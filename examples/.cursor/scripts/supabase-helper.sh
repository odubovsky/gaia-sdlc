#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="supabase-helper.sh"
HELPER_CONFIG_FILE=".supabase-helper.json"
SUPABASE_DIR="supabase"
MIGRATIONS_DIR="$SUPABASE_DIR/migrations"
DEFAULT_MIGRATION_NAME="create_initial_schema"
PROJECTS_CACHE_JSON=""
PYTHON_BIN=""
SAVED_PROJECT_REF=""
SAVED_PROJECT_NAME=""
SAVED_PROJECT_URL=""

print_line() { printf '%s\n' "$*"; }
print_err() { printf '%s\n' "$*" >&2; }

usage() {
  cat <<'USAGE'
Usage:
  ./.cursor/scripts/supabase-helper.sh setup
  ./.cursor/scripts/supabase-helper.sh list-projects
  ./.cursor/scripts/supabase-helper.sh connect --project-ref <ref>
  ./.cursor/scripts/supabase-helper.sh migration [--name <name>]
  ./.cursor/scripts/supabase-helper.sh push
  ./.cursor/scripts/supabase-helper.sh migrate-local-db --source sqlite --db-path <path> [--apply]
  ./.cursor/scripts/supabase-helper.sh status

Notes:
- Non-interactive by design.
- Project choice should happen in chat after list-projects.
- Selected project metadata is stored in .supabase-helper.json.
- Migration creation and remote push do not require Docker in this helper flow.
USAGE
}

find_python() {
  if [[ -n "$PYTHON_BIN" ]]; then
    printf '%s\n' "$PYTHON_BIN"
    return 0
  fi
  local cand
  for cand in python3 python; do
    if command -v "$cand" >/dev/null 2>&1; then
      PYTHON_BIN="$(command -v "$cand")"
      printf '%s\n' "$PYTHON_BIN"
      return 0
    fi
  done
  print_err "Python is required for JSON handling in this helper."
  exit 1
}

require_supabase_cli() {
  if command -v supabase >/dev/null 2>&1; then
    return 0
  fi
  cat <<'EOFMSG'
Supabase CLI is not installed.

Why this matters:
This helper uses Supabase CLI to prepare the project, connect it to your Supabase project, create migrations, and push schema changes.

What to do:
1. Open a terminal.
2. Go to:
   https://supabase.com/docs/guides/local-development/cli/getting-started
3. Install Supabase CLI for your operating system.
4. On macOS with Homebrew, you can run:
   brew install supabase/tap/supabase
5. Verify it works by running:
   supabase --help
6. Run this helper again.

No changes were made.
EOFMSG
  exit 1
}

projects_list_json_raw() {
  local stdout_file stderr_file rc
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  set +e
  supabase projects list -o json >"$stdout_file" 2>"$stderr_file"
  rc=$?
  set -e

  if [[ $rc -ne 0 ]]; then
    print_err "Failed to list Supabase projects."
    if [[ -s "$stderr_file" ]]; then
      cat "$stderr_file" >&2
    fi
    rm -f "$stdout_file" "$stderr_file"
    return $rc
  fi

  cat "$stdout_file"
  rm -f "$stdout_file" "$stderr_file"
}

get_projects_json() {
  if [[ -n "$PROJECTS_CACHE_JSON" ]]; then
    printf '%s\n' "$PROJECTS_CACHE_JSON"
    return 0
  fi
  PROJECTS_CACHE_JSON="$(projects_list_json_raw)"
  printf '%s\n' "$PROJECTS_CACHE_JSON"
}

ensure_logged_in() {
  require_supabase_cli
  local stdout_file stderr_file rc
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"
  set +e
  supabase projects list -o json >"$stdout_file" 2>"$stderr_file"
  rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    PROJECTS_CACHE_JSON="$(cat "$stdout_file")"
    rm -f "$stdout_file" "$stderr_file"
    return 0
  fi

  rm -f "$stdout_file"
  cat <<'EOFMSG'
Supabase CLI is installed, but you are not logged in.

Why this matters:
The helper must access your Supabase account to list your cloud projects and connect this repo to one of them.

What to do:
1. Open a terminal.
2. Run:
   supabase login
3. Complete the login flow in the browser.
4. Run this helper again.

Where to learn more:
https://supabase.com/docs/guides/functions/deploy

No changes were made.
EOFMSG
  if [[ -s "$stderr_file" ]]; then
    print_err "CLI details:"
    cat "$stderr_file" >&2
  fi
  rm -f "$stderr_file"
  exit 1
}

is_initialized() {
  [[ -d "$SUPABASE_DIR" && -f "$SUPABASE_DIR/config.toml" ]]
}

ensure_initialized() {
  if is_initialized; then
    return 0
  fi
  cat <<'EOFMSG'
This project is not prepared for Supabase yet.

Why this matters:
The local Supabase configuration folder does not exist yet.

What to do:
1. Run the helper option:
   Prepare this local project for Supabase
2. After that completes, run your current action again.

No changes were made.
EOFMSG
  exit 1
}

helper_config_exists() {
  [[ -f "$HELPER_CONFIG_FILE" ]]
}

load_helper_config_vars() {
  SAVED_PROJECT_REF=""
  SAVED_PROJECT_NAME=""
  SAVED_PROJECT_URL=""

  if ! helper_config_exists; then
    return 0
  fi

  local py cfg_lines line i
  py="$(find_python)"
  cfg_lines="$($py - "$HELPER_CONFIG_FILE" <<'PY'
import json, os, sys
path = sys.argv[1]
if not os.path.exists(path):
    print("")
    print("")
    print("")
    raise SystemExit(0)
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)
print(data.get("project_ref", "") or "")
print(data.get("project_name", "") or "")
print(data.get("project_url", "") or "")
PY
)"
  i=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$i" in
      0) SAVED_PROJECT_REF="$line" ;;
      1) SAVED_PROJECT_NAME="$line" ;;
      2) SAVED_PROJECT_URL="$line" ;;
    esac
    i=$((i+1))
  done <<EOF_CFG
$cfg_lines
EOF_CFG
}

ensure_connected() {
  load_helper_config_vars
  if [[ -n "$SAVED_PROJECT_REF" ]]; then
    return 0
  fi
  cat <<'EOFMSG'
This project is not connected to a Supabase cloud project yet.

Why this matters:
This action needs a target Supabase cloud project.

What to do:
1. Run list-projects to fetch your available Supabase cloud projects.
2. Choose one project in chat.
3. Run connect with the selected ref, for example:
   ./.cursor/scripts/supabase-helper.sh connect --project-ref <project-ref>

No changes were made.
EOFMSG
  exit 1
}

save_helper_config() {
  local project_ref="$1"
  local project_name="$2"
  local project_url="$3"
  local py
  py="$(find_python)"
  "$py" - "$HELPER_CONFIG_FILE" "$project_ref" "$project_name" "$project_url" <<'PY'
import json, sys
path, ref, name, url = sys.argv[1:5]
with open(path, "w", encoding="utf-8") as f:
    json.dump({
        "project_ref": ref,
        "project_name": name,
        "project_url": url,
    }, f, indent=2)
    f.write("\n")
PY
}

project_metadata_by_ref() {
  local ref="$1"
  local py projects_json lines line i name url
  py="$(find_python)"
  projects_json="$(get_projects_json)"
  lines="$(PROJECTS_JSON="$projects_json" "$py" - "$ref" <<'PY'
import json, os, sys
ref = sys.argv[1]
projects = json.loads(os.environ['PROJECTS_JSON'])
for p in projects:
    if p.get('ref') == ref or p.get('id') == ref:
        name = p.get('name', '') or ''
        actual_ref = p.get('ref', '') or p.get('id', '') or ref
        url = f"https://{actual_ref}.supabase.co" if actual_ref else ''
        print(name)
        print(url)
        raise SystemExit(0)
raise SystemExit(1)
PY
)" || return 1
  i=0
  name=""
  url=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$i" in
      0) name="$line" ;;
      1) url="$line" ;;
    esac
    i=$((i+1))
  done <<EOF_META
$lines
EOF_META
  printf '%s\n%s\n' "$name" "$url"
}

has_migration_files() {
  if [[ ! -d "$MIGRATIONS_DIR" ]]; then
    return 1
  fi
  local files=("$MIGRATIONS_DIR"/*.sql)
  [[ -e "${files[0]}" ]]
}

cmd_setup() {
  require_supabase_cli
  if is_initialized; then
    print_line "Supabase is already prepared in this project."
    return 0
  fi
  print_line "Preparing this local project for Supabase..."
  supabase init
  print_line "Done. Local Supabase folder created under $SUPABASE_DIR/."
}

cmd_list_projects() {
  require_supabase_cli
  ensure_logged_in
  print_line "Fetching your Supabase cloud projects..."
  get_projects_json
}

cmd_connect() {
  require_supabase_cli
  ensure_logged_in
  ensure_initialized

  local project_ref=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project-ref)
        shift
        project_ref="${1:-}"
        [[ -n "$project_ref" ]] || { print_err "Missing value after --project-ref"; exit 1; }
        shift
        ;;
      *)
        print_err "Unknown connect argument: $1"
        exit 1
        ;;
    esac
  done

  [[ -n "$project_ref" ]] || { print_err "Project ref is required. Use: connect --project-ref <ref>"; exit 1; }

  print_line "Connecting this repo to Supabase project ref: $project_ref"
  (cd . && supabase link --project-ref "$project_ref")

  local meta_lines meta_name meta_url i line
  meta_lines="$(project_metadata_by_ref "$project_ref" || printf '\n\n')"
  meta_name=""
  meta_url=""
  i=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$i" in
      0) meta_name="$line" ;;
      1) meta_url="$line" ;;
    esac
    i=$((i+1))
  done <<EOF_META2
$meta_lines
EOF_META2

  save_helper_config "$project_ref" "$meta_name" "$meta_url"
  print_line "Connected this repo to Supabase project ref: $project_ref"
}

cmd_migration() {
  require_supabase_cli
  ensure_initialized
  local name="$DEFAULT_MIGRATION_NAME"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --name)
        shift
        name="${1:-$DEFAULT_MIGRATION_NAME}"
        shift
        ;;
      *)
        print_err "Unknown migration argument: $1"
        exit 1
        ;;
    esac
  done

  print_line "Creating Supabase migration: $name"

  # Supabase CLI may use a temp folder (e.g. for profile/templates) under `supabase/.temp`.
  # Your earlier debug output showed it trying to open `supabase/.temp/profile`, so ensure
  # the folder exists to avoid hangs in CLI temp initialization.
  mkdir -p "$SUPABASE_DIR/.temp" >/dev/null 2>&1 || true
  # Important: newer Supabase CLI versions fail if `supabase/.temp/profile` exists but is empty.
  # Let the CLI create/populate it; if we previously created an empty placeholder, remove it.
  if [[ -f "$SUPABASE_DIR/.temp/profile" && ! -s "$SUPABASE_DIR/.temp/profile" ]]; then
    rm -f "$SUPABASE_DIR/.temp/profile" 2>/dev/null || true
  fi
  mkdir -p "$MIGRATIONS_DIR" >/dev/null 2>&1 || true
  if [[ -e "$SUPABASE_DIR/.temp/profile" ]]; then
    print_line "DEBUG: Found existing $SUPABASE_DIR/.temp/profile"
  else
    print_line "DEBUG: $SUPABASE_DIR/.temp/profile not present yet (created parent .temp dir)"
  fi

  # The Supabase CLI may open an editor and wait for it to be closed.
  # In this class helper flow we want non-interactive behavior + visible debug output.
  local original_editor="${EDITOR-}"
  local original_visual="${VISUAL-}"
  if [[ "${SUPABASE_HELPER_RESPECT_EDITOR:-0}" != "1" ]]; then
    local editor_cmd="${SUPABASE_HELPER_MIGRATION_EDITOR_CMD:-true}"
    export EDITOR="$editor_cmd"
    export VISUAL="$editor_cmd"
    print_line "DEBUG: Overriding EDITOR/VISUAL to prevent interactive editor waits: EDITOR=${EDITOR} VISUAL=${VISUAL} (was EDITOR=${original_editor:-<unset>} VISUAL=${original_visual:-<unset>})"
  else
    print_line "DEBUG: Using existing EDITOR/VISUAL (SUPABASE_HELPER_RESPECT_EDITOR=1): EDITOR=${EDITOR:-<unset>} VISUAL=${VISUAL:-<unset>}"
  fi

  # Safety net: `supabase migration new` is not guaranteed to exit quickly in all environments.
  # We cap execution time so the helper never blocks forever.
  local timeout_seconds="${SUPABASE_HELPER_MIGRATION_TIMEOUT_SECONDS:-120}"
  local attempts="${SUPABASE_HELPER_MIGRATION_ATTEMPTS:-2}"
  local attempt=1

  while [[ $attempt -le $attempts ]]; do
    local stdout_file stderr_file pid start_ts rc latest_file size_bytes
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"

    print_line "DEBUG: Attempt ${attempt}/${attempts}: starting supabase --debug --yes migration new \"$name\" (timeout=${timeout_seconds}s)"

    set +e
    supabase --debug --yes migration new "$name" >"$stdout_file" 2>"$stderr_file" &
    pid=$!
    set -e

    start_ts="$(date +%s)"
    while kill -0 "$pid" 2>/dev/null; do
      local now
      now="$(date +%s)"
      if (( now - start_ts >= timeout_seconds )); then
        print_err "ERROR: migration new timed out after ${timeout_seconds}s (pid=${pid}). Killing it."
        # Best-effort termination of the process. (If it spawned children, they may linger,
        # but the helper will still exit cleanly.)
        kill "$pid" 2>/dev/null || true
        sleep 1
        kill -9 "$pid" 2>/dev/null || true
        break
      fi
      sleep 1
    done

    # Collect exit code if the process already ended.
    set +e
    wait "$pid" 2>/dev/null
    rc=$?
    set -e

    # Print the last part of CLI output so you can copy it from STDOUT.
    print_line "DEBUG: supabase stdout (tail):"
    if [[ -s "$stdout_file" ]]; then
      tail -n 120 "$stdout_file" || true
    else
      print_line "<empty stdout>"
    fi
    print_line "DEBUG: supabase stderr (tail):"
    if [[ -s "$stderr_file" ]]; then
      tail -n 120 "$stderr_file" || true
    else
      print_line "<empty stderr>"
    fi

    # Identify the migration file we just created.
    latest_file="$(ls -t "$MIGRATIONS_DIR/"*"$name"*.sql 2>/dev/null | awk 'NR==1{print; exit}')"
    size_bytes="0"
    if [[ -n "$latest_file" && -f "$latest_file" ]]; then
      size_bytes="$(wc -c < "$latest_file" 2>/dev/null || echo 0)"
    fi

    # If we were asked to create the initial schema, replace any placeholder scaffold output
    # with the actual table definitions used by this repo's SQLite model.
    local needs_initial_schema="no"
    if [[ "$name" = "$DEFAULT_MIGRATION_NAME" && -n "$latest_file" && -f "$latest_file" ]]; then
      local head_sample
      head_sample="$(sed -n '1,12p' "$latest_file" 2>/dev/null || true)"
      if [[ "$size_bytes" -eq 0 || "$head_sample" == *"Supabase migration scaffolded by"* ]]; then
        needs_initial_schema="yes"
      fi
    fi

    if [[ -n "$latest_file" && -f "$latest_file" && "$size_bytes" -gt 0 ]]; then
      if [[ "$needs_initial_schema" = "yes" ]]; then
        print_err "WARNING: Detected placeholder/empty scaffold for initial schema; writing real sessions/messages SQL."
        cat >"$latest_file" <<'EOFSQL'
begin;

create table if not exists public.sessions (
  id text primary key,
  created_at text not null
);

create table if not exists public.messages (
  id bigserial primary key,
  session_id text not null references public.sessions(id) on delete cascade,
  role text not null,
  text text not null,
  timestamp text not null
);

commit;
EOFSQL
      fi

      local final_size
      final_size="$(wc -c < "$latest_file" 2>/dev/null || echo 0)"
      print_line "Migration command finished."
      print_line "Created migration: $latest_file (${final_size} bytes)"
      break
    fi

    print_err "ERROR: migration SQL template appears empty (file=${latest_file:-<none>} size=${size_bytes})."
    if [[ $attempt -lt $attempts ]]; then
      # Remove the empty migration so the retry produces a clean file.
      if [[ -n "$latest_file" && -f "$latest_file" ]]; then
        rm -f "$latest_file" 2>/dev/null || true
      fi
      print_err "Retrying migration scaffolding..."
      attempt=$((attempt + 1))
      continue
    fi

    # Final fallback: if the CLI produced the .sql file but left it empty,
    # write the actual initial schema SQL so downstream `db push` can succeed.
    if [[ -n "$latest_file" && -f "$latest_file" && "$size_bytes" -eq 0 ]]; then
      if [[ "$name" = "$DEFAULT_MIGRATION_NAME" ]]; then
        print_err "WARNING: Supabase CLI produced an empty initial-schema migration; writing sessions/messages SQL fallback."
        cat >"$latest_file" <<'EOFSQL'
begin;

create table if not exists public.sessions (
  id text primary key,
  created_at text not null
);

create table if not exists public.messages (
  id bigserial primary key,
  session_id text not null references public.sessions(id) on delete cascade,
  role text not null,
  text text not null,
  timestamp text not null
);

commit;
EOFSQL
        print_line "Created fallback migration (real schema): $latest_file"
        break
      fi

      print_err "WARNING: Supabase CLI produced an empty migration template; writing placeholder fallback."
      cat >"$latest_file" <<'EOFSQL'
-- Supabase migration scaffolded by `supabase-helper.sh`.
-- Replace this placeholder with your actual schema changes.
EOFSQL
      print_line "Created fallback migration: $latest_file"
      break
    fi

    print_err "ERROR: migration scaffolding failed after ${attempts} attempts."
    print_err "Last CLI exit code: ${rc:-unknown}"
    exit 1
  done

  # Restore editor variables (best-effort).
  if [[ "${SUPABASE_HELPER_RESPECT_EDITOR:-0}" != "1" ]]; then
    if [[ -n "${original_editor:-}" ]]; then
      export EDITOR="$original_editor"
    else
      unset EDITOR 2>/dev/null || true
    fi
    if [[ -n "${original_visual:-}" ]]; then
      export VISUAL="$original_visual"
    else
      unset VISUAL 2>/dev/null || true
    fi
  fi
}

cmd_push() {
  require_supabase_cli
  ensure_logged_in
  ensure_initialized
  ensure_connected
  if ! has_migration_files; then
    print_err "No migration files were found under $MIGRATIONS_DIR."
    exit 1
  fi
  print_line "Pushing local schema migrations to the connected Supabase project..."
  supabase db push
  print_line "Schema push finished."
}

cmd_migrate_local_db() {
  require_supabase_cli
  ensure_logged_in
  ensure_initialized
  ensure_connected

  local source="" db_path="" apply_flag="0"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --source) source="${2:-}"; shift 2 ;;
      --db-path) db_path="${2:-}"; shift 2 ;;
      --apply) apply_flag="1"; shift ;;
      *) print_err "Unknown migrate-local-db argument: $1"; exit 1 ;;
    esac
  done

  if [[ "$source" != "sqlite" ]]; then
    print_err "Only --source sqlite is supported in this version."
    exit 1
  fi
  if [[ -z "$db_path" || ! -f "$db_path" ]]; then
    print_err "Provide a valid SQLite DB path with --db-path <path>."
    exit 1
  fi

  local py import_sql
  py="$(find_python)"
  import_sql="$SUPABASE_DIR/import-from-local.sql"
  print_line "Generating import SQL from local SQLite DB..."
  "$py" - "$db_path" "$import_sql" <<'PY'
import sqlite3, sys
from pathlib import Path

db_path = sys.argv[1]
out_path = sys.argv[2]
conn = sqlite3.connect(db_path)
cur = conn.cursor()
Path(out_path).parent.mkdir(parents=True, exist_ok=True)
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('-- Generated import SQL from local SQLite\n')
    for table in ('sessions', 'messages'):
        try:
            rows = cur.execute(f'SELECT * FROM {table}').fetchall()
            cols = [d[0] for d in cur.description]
        except Exception:
            continue
        if not rows:
            continue
        col_list = ', '.join([f'"{c}"' for c in cols])
        for row in rows:
            vals = []
            for v in row:
                if v is None:
                    vals.append('NULL')
                else:
                    s = str(v).replace("'", "''")
                    vals.append("'%s'" % s)
            f.write(f'INSERT INTO public.{table} ({col_list}) VALUES ({", ".join(vals)});\n')
conn.close()
PY
  print_line "Generated import SQL at: $import_sql"
  if [[ "$apply_flag" = "1" ]]; then
    print_line "Applying current schema migrations to the connected Supabase project..."
    supabase db push
    print_line "Schema push finished. Apply the generated import SQL from the Supabase SQL Editor or include it in a migration."
  fi
}

cmd_status() {
  load_helper_config_vars
  local cli_installed="no" logged_in="no" initialized="no" connected="no" migrations="no"
  if command -v supabase >/dev/null 2>&1; then
    cli_installed="yes"
    local stdout_file stderr_file rc
    stdout_file="$(mktemp)"
    stderr_file="$(mktemp)"
    set +e
    supabase projects list -o json >"$stdout_file" 2>"$stderr_file"
    rc=$?
    set -e
    [[ $rc -eq 0 ]] && logged_in="yes"
    rm -f "$stdout_file" "$stderr_file"
  fi
  is_initialized && initialized="yes"
  [[ -n "$SAVED_PROJECT_REF" ]] && connected="yes"
  has_migration_files && migrations="yes"

  print_line "Here’s your current Supabase setup status:"
  print_line ""
  print_line "Supabase CLI installed: $cli_installed"
  print_line "Supabase CLI logged in: $logged_in"
  print_line "Local project prepared for Supabase: $initialized"
  print_line "Connected to a Supabase cloud project: $connected"
  print_line "Migration files present: $migrations"
  if [[ "$connected" = "yes" ]]; then
    print_line "Project ref: $SAVED_PROJECT_REF"
    if [[ -n "$SAVED_PROJECT_NAME" ]]; then
      print_line "Project name: $SAVED_PROJECT_NAME"
    else
      print_line "Project name: (not stored)"
    fi
    if [[ -n "$SAVED_PROJECT_URL" ]]; then
      print_line "Project URL: $SAVED_PROJECT_URL"
    fi
    print_line "Helper memory file: $HELPER_CONFIG_FILE"
  fi
}

action="${1:-help}"
if [[ $# -gt 0 ]]; then shift; fi

case "$action" in
  setup) cmd_setup "$@" ;;
  list-projects) cmd_list_projects "$@" ;;
  connect) cmd_connect "$@" ;;
  migration) cmd_migration "$@" ;;
  push) cmd_push "$@" ;;
  migrate-local-db) cmd_migrate_local_db "$@" ;;
  status) cmd_status "$@" ;;
  help|-h|--help) usage ;;
  *) print_err "Unknown action: $action"; usage; exit 1 ;;
esac
