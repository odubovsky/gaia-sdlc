param(
  [Parameter(Position=0)]
  [string]$Action = "help"
)

$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
  # Script is located at: <repo>/.cursor/scripts/supabase-helper.ps1
  $scriptsDir = $PSScriptRoot
  $cursorDir = Split-Path -Parent $scriptsDir
  return (Split-Path -Parent $cursorDir)
}

$ProjectRoot = Get-ProjectRoot
$HelperConfigFile = Join-Path $ProjectRoot ".supabase-helper.json"
$SupabaseDir = Join-Path $ProjectRoot "supabase"
$MigrationsDir = Join-Path $SupabaseDir "migrations"
$DefaultMigrationName = "create_initial_schema"

function PrintLine([string]$msg) { Write-Output $msg }
function PrintErr([string]$msg) { Write-Error $msg }

function Require-SupabaseCli {
  if (Get-Command supabase -ErrorAction SilentlyContinue) { return }

  PrintErr "Supabase CLI is not installed."
  PrintErr ""
  PrintErr "Why this matters:"
  PrintErr "This helper uses Supabase CLI to prepare the project, connect it to your Supabase project, create migrations, and push schema changes."
  PrintErr ""
  PrintErr "What to do:"
  PrintErr "1) Install Supabase CLI: https://supabase.com/docs/guides/local-development/cli/getting-started"
  PrintErr "2) Verify it works: supabase --help"
  PrintErr "No changes were made."
  exit 1
}

function Load-HelperConfig {
  if (-not (Test-Path $HelperConfigFile)) { return $null }
  try {
    $raw = Get-Content -Raw -Path $HelperConfigFile -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }
    return ($raw | ConvertFrom-Json)
  } catch {
    return $null
  }
}

function Save-HelperConfig([string]$ProjectRef, [string]$ProjectName, [string]$ProjectUrl) {
  $obj = [ordered]@{
    project_ref  = $ProjectRef
    project_name = $ProjectName
    project_url  = $ProjectUrl
    linked_at    = ([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ"))
  }
  $json = ($obj | ConvertTo-Json -Depth 6)
  $json | Set-Content -Path $HelperConfigFile -Encoding UTF8
}

function Is-Initialized {
  $cfg = Join-Path $SupabaseDir "config.toml"
  return (Test-Path $cfg)
}

function Ensure-Initialized {
  if (Is-Initialized) { return }

  PrintErr @"
This project is not prepared for Supabase yet.

Why this matters:
The local Supabase configuration folder does not exist yet.

What to do:
1) Run option: Prepare this local project for Supabase
2) After that completes, run your current action again.

No changes were made.
"@
  exit 1
}

function Ensure-LoggedIn {
  Require-SupabaseCli
  try {
    $null = & supabase projects list -o json 2>$null
    if ($LASTEXITCODE -eq 0) { return }
  } catch {}

  PrintErr @"
Supabase CLI is installed, but you are not logged in.

Why this matters:
The helper must access your Supabase account to list your cloud projects and connect this repo to one of them.

What to do:
1) Run: supabase login
2) Complete the login flow in the browser.
3) Run this helper again.

No changes were made.
"@
  exit 1
}

function Ensure-Connected {
  $cfg = Load-HelperConfig
  if ($null -ne $cfg -and -not [string]::IsNullOrWhiteSpace($cfg.project_ref)) { return }

  PrintErr @"
This project is not connected to a Supabase cloud project yet.

Why this matters:
This action needs a target Supabase cloud project.

What to do:
1) Run: list-projects
2) Choose one project in chat
3) Run connect with the selected ref, for example:
   ./.cursor/scripts/supabase-helper.ps1 connect --project-ref <project-ref>

No changes were made.
"@
  exit 1
}

function Get-ProjectsJsonRaw {
  $stdout = & supabase projects list -o json
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to list Supabase projects."
  }
  return [string]$stdout
}

function Cmd-ListProjects {
  Require-SupabaseCli
  Ensure-LoggedIn
  PrintLine (Get-ProjectsJsonRaw)
}

function Cmd-Setup {
  Require-SupabaseCli
  if (Is-Initialized) {
    PrintLine "Supabase is already prepared in this project."
    return
  }

  PrintLine "Preparing this local project for Supabase..."
  & supabase init | Out-Host
  PrintLine "Done. Local Supabase folder created under $SupabaseDir."
}

function Cmd-Connect([string]$ProjectRef) {
  Require-SupabaseCli
  Ensure-LoggedIn
  Ensure-Initialized

  if ([string]::IsNullOrWhiteSpace($ProjectRef)) {
    PrintErr "Project ref is required. Use: connect --project-ref <ref>"
    exit 1
  }

  PrintLine "Connecting this repo to Supabase project ref: $ProjectRef"
  & supabase link --project-ref $ProjectRef | Out-Host

  # Retrieve metadata and store it in helper config.
  $raw = Get-ProjectsJsonRaw
  $projects = $raw | ConvertFrom-Json
  $proj = $projects | Where-Object { $_.ref -eq $ProjectRef -or $_.id -eq $ProjectRef } | Select-Object -First 1
  $name = ""
  $url = ""
  if ($null -ne $proj) {
    $name = [string]$proj.name
    $url = "https://$ProjectRef.supabase.co"
  }

  Save-HelperConfig -ProjectRef $ProjectRef -ProjectName $name -ProjectUrl $url
  PrintLine "Connected this repo to Supabase project ref: $ProjectRef"
}

function Write-InitialSchemaSql([string]$Path) {
  $sql = @'
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
'@
  $sql | Set-Content -Path $Path -Encoding UTF8
}

function Invoke-SupabaseMigrationNewWithTimeout(
  [string]$MigrationName,
  [int]$TimeoutSeconds,
  [string]$StdoutFile,
  [string]$StderrFile
) {
  $psiArgs = @("--debug", "--yes", "migration", "new", $MigrationName)

  $proc = Start-Process -FilePath "supabase" -ArgumentList $psiArgs -NoNewWindow -PassThru `
    -RedirectStandardOutput $StdoutFile -RedirectStandardError $StderrFile

  $exited = $proc.WaitForExit($TimeoutSeconds * 1000)
  if (-not $exited) {
    try { $proc.Kill() | Out-Null } catch {}
    return @{ exited=$false; exitCode=$null }
  }

  return @{ exited=$true; exitCode=$proc.ExitCode }
}

function Cmd-Migration([string]$Name) {
  Require-SupabaseCli
  Ensure-Initialized

  if ([string]::IsNullOrWhiteSpace($Name)) { $Name = $DefaultMigrationName }

  PrintLine "Creating Supabase migration: $Name"

  # Ensure temp dir exists. The CLI's behavior varies across versions; we rely on timeout+fallback.
  New-Item -ItemType Directory -Force -Path (Join-Path $SupabaseDir ".temp") | Out-Null
  New-Item -ItemType Directory -Force -Path $MigrationsDir | Out-Null

  # If temp "profile" exists but is empty, remove it (it can break parsing in some CLI versions).
  $profilePath = Join-Path $SupabaseDir ".temp" "profile"
  if (Test-Path $profilePath) {
    if ((Get-Item $profilePath).Length -eq 0) {
      Remove-Item -Force $profilePath -ErrorAction SilentlyContinue
    }
  }

  $origEditor = $env:EDITOR
  $origVisual = $env:VISUAL
  if ($env:SUPABASE_HELPER_RESPECT_EDITOR -ne "1") {
    $env:EDITOR = "true"
    $env:VISUAL = "true"
    PrintLine "DEBUG: Overriding EDITOR/VISUAL to prevent interactive editor waits: EDITOR=$($env:EDITOR) VISUAL=$($env:VISUAL) (was EDITOR=$origEditor VISUAL=$origVisual)"
  }

  $timeoutSeconds = [int]($env:SUPABASE_HELPER_MIGRATION_TIMEOUT_SECONDS)
  if ($null -eq $timeoutSeconds -or $timeoutSeconds -le 0) { $timeoutSeconds = 120 }
  $attempts = [int]($env:SUPABASE_HELPER_MIGRATION_ATTEMPTS)
  if ($null -eq $attempts -or $attempts -le 0) { $attempts = 2 }

  $attempt = 1
  while ($attempt -le $attempts) {
    $stdoutFile = [IO.Path]::GetTempFileName()
    $stderrFile = [IO.Path]::GetTempFileName()

    # Remove any existing content so tail isn't polluted.
    Remove-Item -Force $stdoutFile,$stderrFile -ErrorAction SilentlyContinue
    New-Item -ItemType File -Force -Path $stdoutFile | Out-Null
    New-Item -ItemType File -Force -Path $stderrFile | Out-Null

    PrintLine "DEBUG: Attempt $attempt/$attempts: starting supabase --debug --yes migration new `"$Name`" (timeout=$timeoutSeconds s)"

    $result = Invoke-SupabaseMigrationNewWithTimeout -MigrationName $Name -TimeoutSeconds $timeoutSeconds -StdoutFile $stdoutFile -StderrFile $stderrFile

    # Read debug output tails.
    PrintLine "DEBUG: supabase stdout (tail):"
    if (Test-Path $stdoutFile -and (Get-Item $stdoutFile).Length -gt 0) {
      Get-Content -Path $stdoutFile -Tail 120 | ForEach-Object { PrintLine $_ }
    } else {
      PrintLine "<empty stdout>"
    }

    PrintLine "DEBUG: supabase stderr (tail):"
    if (Test-Path $stderrFile -and (Get-Item $stderrFile).Length -gt 0) {
      Get-Content -Path $stderrFile -Tail 120 | ForEach-Object { PrintLine $_ }
    } else {
      PrintLine "<empty stderr>"
    }

    # Identify the migration file we just created.
    $latestFile = Get-ChildItem -Path $MigrationsDir -Filter "*$Name*.sql" -File -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1

    $sizeBytes = 0
    if ($null -ne $latestFile) { $sizeBytes = $latestFile.Length }

    # Determine whether we should write the real initial schema.
    $needsInitialSchema = "no"
    if ($Name -eq $DefaultMigrationName -and $null -ne $latestFile) {
      if ($sizeBytes -eq 0) {
        $needsInitialSchema = "yes"
      } else {
        $head = ""
        try {
          $head = (Get-Content -Path $latestFile.FullName -TotalCount 12) -join "`n"
        } catch {}
        if ($head -match "Supabase migration scaffolded by") {
          $needsInitialSchema = "yes"
        }
      }
    }

    if ($null -ne $latestFile -and $sizeBytes -gt 0) {
      if ($needsInitialSchema -eq "yes") {
        PrintLine "WARNING: Writing real sessions/messages SQL into placeholder initial-schema migration."
        Write-InitialSchemaSql -Path $latestFile.FullName
      }
      $finalSize = (Get-Item $latestFile.FullName).Length
      PrintLine "Migration command finished."
      PrintLine "Created migration: $($latestFile.FullName) ($finalSize bytes)"
      break
    }

    # If empty but initial-schema, write fallback.
    if ($null -ne $latestFile -and $sizeBytes -eq 0 -and $Name -eq $DefaultMigrationName) {
      PrintLine "WARNING: Supabase CLI produced an empty initial-schema migration; writing sessions/messages SQL fallback."
      Write-InitialSchemaSql -Path $latestFile.FullName
      $finalSize = (Get-Item $latestFile.FullName).Length
      PrintLine "Migration command finished."
      PrintLine "Created fallback migration: $($latestFile.FullName) ($finalSize bytes)"
      break
    }

    if ($attempt -lt $attempts) {
      PrintLine "Retrying migration scaffolding..."
      if ($null -ne $latestFile) {
        Remove-Item -Force $latestFile.FullName -ErrorAction SilentlyContinue
      }
      $attempt++
      continue
    }

    PrintErr "ERROR: migration scaffolding failed after $attempts attempts."
    exit 1
  }

  # Restore editor variables.
  if ($env:SUPABASE_HELPER_RESPECT_EDITOR -ne "1") {
    if ($null -ne $origEditor) { $env:EDITOR = $origEditor } else { Remove-Item env:EDITOR -ErrorAction SilentlyContinue }
    if ($null -ne $origVisual) { $env:VISUAL = $origVisual } else { Remove-Item env:VISUAL -ErrorAction SilentlyContinue }
  }
}

function Cmd-Push {
  Require-SupabaseCli
  Ensure-LoggedIn
  Ensure-Initialized
  Ensure-Connected

  if (-not (Test-Path $MigrationsDir)) {
    PrintErr "No migration files were found under $MigrationsDir."
    exit 1
  }

  $hasAny = (Get-ChildItem -Path $MigrationsDir -Filter "*.sql" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
  if (-not $hasAny) {
    PrintErr "No migration files were found under $MigrationsDir."
    exit 1
  }

  PrintLine "Pushing local schema migrations to the connected Supabase project..."
  & supabase db push | Out-Host
  PrintLine "Schema push finished."
}

function Cmd-MigrateLocalDb([string]$Source, [string]$DbPath) {
  Require-SupabaseCli
  Ensure-LoggedIn
  Ensure-Initialized
  Ensure-Connected

  if ($Source -ne "sqlite") {
    PrintErr "Only --source sqlite is supported in this version."
    exit 1
  }
  if ([string]::IsNullOrWhiteSpace($DbPath) -or -not (Test-Path $DbPath)) {
    PrintErr "Provide a valid SQLite DB path with --db-path <path>."
    exit 1
  }

  $importSqlPath = Join-Path $SupabaseDir "import-from-local.sql"
  PrintLine "Generating import SQL from local SQLite DB..."

  # Generate inserts for sessions and messages. We omit `id` for messages to avoid sequence/id conflicts later.
  $py = $null
  if (Get-Command python -ErrorAction SilentlyContinue) { $py = "python" }
  elseif (Get-Command python3 -ErrorAction SilentlyContinue) { $py = "python3" }
  else { PrintErr "Python is required for SQLite handling in this helper."; exit 1 }

  & $py - "$DbPath" "$importSqlPath" @"
import sqlite3, sys
from pathlib import Path

db_path = sys.argv[1]
out_path = sys.argv[2]
conn = sqlite3.connect(db_path)
cur = conn.cursor()

Path(out_path).parent.mkdir(parents=True, exist_ok=True)

def esc(v):
    if v is None:
        return ""
    return str(v).replace("'", "''")

with open(out_path, 'w', encoding='utf-8') as f:
    f.write('-- Generated import SQL from local SQLite\\n')
    # sessions: (id TEXT, created_at TEXT)
    try:
        rows = cur.execute('SELECT id, created_at FROM sessions').fetchall()
        for (idv, created_at) in rows:
            f.write("insert into public.sessions (id, created_at) values ('%s', '%s') on conflict (id) do nothing;\\n" % (esc(idv), esc(created_at)))
    except Exception:
        pass

    # messages: (session_id TEXT, role TEXT, text TEXT, timestamp TEXT)
    try:
        rows = cur.execute('SELECT session_id, role, text, timestamp FROM messages ORDER BY id ASC').fetchall()
        for (session_id, role, text, timestamp) in rows:
            f.write("insert into public.messages (session_id, role, text, timestamp) values ('%s', '%s', '%s', '%s');\\n" % (esc(session_id), esc(role), esc(text), esc(timestamp)))
    except Exception:
        pass

conn.close()
@ | Out-Null

  PrintLine "Generated import SQL at: $importSqlPath"
  PrintLine "Next: apply this SQL in the Supabase SQL editor, or include it into a migration."
}

function Cmd-Status {
  $cliInstalled = "no"
  $loggedIn = "no"
  $initialized = "no"
  $connected = "no"
  $migrations = "no"

  if (Get-Command supabase -ErrorAction SilentlyContinue) {
    $cliInstalled = "yes"
    try {
      $null = & supabase projects list -o json 2>$null
      if ($LASTEXITCODE -eq 0) { $loggedIn = "yes" }
    } catch {}
  }

  if (Is-Initialized) { $initialized = "yes" }
  $cfg = Load-HelperConfig
  if ($null -ne $cfg -and -not [string]::IsNullOrWhiteSpace($cfg.project_ref)) { $connected = "yes" }
  if (Test-Path $MigrationsDir) {
    $hasAny = (Get-ChildItem -Path $MigrationsDir -Filter "*.sql" -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($hasAny) { $migrations = "yes" }
  }

  PrintLine "Here’s your current Supabase setup status:"
  PrintLine ""
  PrintLine "Supabase CLI installed: $cliInstalled"
  PrintLine "Supabase CLI logged in: $loggedIn"
  PrintLine "Local project prepared for Supabase: $initialized"
  PrintLine "Connected to a Supabase cloud project: $connected"
  PrintLine "Migration files present: $migrations"

  if ($connected -eq "yes") {
    PrintLine "Project ref: $($cfg.project_ref)"
    if (-not [string]::IsNullOrWhiteSpace($cfg.project_name)) { PrintLine "Project name: $($cfg.project_name)" }
    if (-not [string]::IsNullOrWhiteSpace($cfg.project_url)) { PrintLine "Project URL: $($cfg.project_url)" }
    PrintLine "Helper memory file: $HelperConfigFile"
  }
}

#
# Argument parsing for non-interactive helper use
#
$rest = @($args)

switch ($Action.ToLowerInvariant()) {
  "setup" {
    Cmd-Setup
  }
  "list-projects" {
    Cmd-ListProjects
  }
  "connect" {
    $projectRef = ""
    for ($i = 0; $i -lt $rest.Length; $i++) {
      if ($rest[$i] -eq "--project-ref") {
        $projectRef = $rest[$i+1]
        $i++
      }
    }
    Cmd-Connect -ProjectRef $projectRef
  }
  "migration" {
    $name = $DefaultMigrationName
    for ($i = 0; $i -lt $rest.Length; $i++) {
      if ($rest[$i] -eq "--name") {
        $name = $rest[$i+1]
        $i++
      }
    }
    Cmd-Migration -Name $name
  }
  "push" {
    Cmd-Push
  }
  "migrate-local-db" {
    $source = ""
    $dbPath = ""
    for ($i = 0; $i -lt $rest.Length; $i++) {
      if ($rest[$i] -eq "--source") { $source = $rest[$i+1]; $i++ }
      elseif ($rest[$i] -eq "--db-path") { $dbPath = $rest[$i+1]; $i++ }
    }
    Cmd-MigrateLocalDb -Source $source -DbPath $dbPath
  }
  "status" {
    Cmd-Status
  }
  default {
    PrintLine "Usage:"
    PrintLine "  ./supabase-helper.ps1 setup"
    PrintLine "  ./supabase-helper.ps1 list-projects"
    PrintLine "  ./supabase-helper.ps1 connect --project-ref <ref>"
    PrintLine "  ./supabase-helper.ps1 migration [--name <name>]"
    PrintLine "  ./supabase-helper.ps1 push"
    PrintLine "  ./supabase-helper.ps1 migrate-local-db --source sqlite --db-path <path>"
    PrintLine "  ./supabase-helper.ps1 status"
    exit 1
  }
}

