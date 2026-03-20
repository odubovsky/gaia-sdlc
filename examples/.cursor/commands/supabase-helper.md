Run basic Supabase migration commands from agent

description: Guided helper for basic Supabase setup and migration tasks for students. Use when the user wants to prepare a repo for Supabase, connect it to an existing Supabase cloud project, create a migration, push schema changes, migrate local SQLite data to Supabase, or check current setup status.
---

# Supabase Helper

This helper is a guided wrapper around the local `supabase-helper.sh` script.

## Supported actions

1. Prepare this local project for Supabase
2. Connect this project to my Supabase cloud project
3. Create a database migration
4. Apply local schema changes to Supabase
5. Migrate my local app database to Supabase
6. Check Supabase setup status

## Core rule

You must EXECUTE the helper script directly.
Do NOT tell the user to manually run terminal commands unless the script output explicitly says a required tool is missing.
Do NOT replace the helper with raw Supabase CLI commands unless the helper script itself fails.
The shell script is non-interactive. The chat flow handles choices.

## Menu

When invoked, present this menu exactly:

1. Prepare this local project for Supabase
2. Connect this project to my Supabase cloud project
3. Create a database migration
4. Apply local schema changes to Supabase
5. Migrate my local app database to Supabase
6. Check Supabase setup status

Then ask the user which option they want.

## Execution

On macOS or Linux, execute:

```bash
./.cursor/scripts/supabase-helper.sh <action>
```

Where `<action>` is one of:
- `setup`
- `list-projects`
- `connect --project-ref <ref>`
- `migration`
- `push`
- `migrate-local-db --source sqlite --db-path <path>`
- `status`

## Option behavior

### 1. Prepare this local project for Supabase

Use this when the repo does not yet have local Supabase files.

Run:

```bash
./.cursor/scripts/supabase-helper.sh setup
```

Then summarize the result.

### 2. Connect this project to my Supabase cloud project

This is a guided chat flow, not a terminal prompt flow.

Run:

```bash
./.cursor/scripts/supabase-helper.sh list-projects
```

Expected result:
- clean JSON list of available projects, or
- a clear prerequisite error from the script.

If projects are returned, present them as a numbered list in chat using:
- project name
- project ref
- status
- region

Then also present one more option:
- Create a new Supabase project in the dashboard

If the user chooses an existing project:
- run:

```bash
./.cursor/scripts/supabase-helper.sh connect --project-ref <chosen-ref>
```

- then summarize the result.

If the user chooses to create a new project:
- instruct them to open:
  `https://supabase.com/dashboard/projects`
- create the project in the dashboard
- wait until it is ready
- reply `done`
- then rerun `list-projects`
- show the refreshed list
- continue with project selection and `connect --project-ref <chosen-ref>`

Do NOT claim that push needs Docker.
Do NOT ask the shell script to wait for user input.

### 3. Create a database migration

Use the default migration name automatically unless the user explicitly asks for another name.

Default migration name:
- `create_initial_schema`

Run:

```bash
./.cursor/scripts/supabase-helper.sh migration
```

If the user explicitly wants a custom name, use the script's supported flag form if available; otherwise explain that the current helper uses the default name.

After it succeeds, tell the user that the migration file now exists under `supabase/migrations` and that the next normal step is to edit the SQL before pushing.

### 4. Apply local schema changes to Supabase

Use this when migration files already exist and the repo is already connected to a cloud project.

Run:

```bash
./.cursor/scripts/supabase-helper.sh push
```

This step should be described as pushing local migration SQL to the linked Supabase cloud project.
Do NOT say Docker is required for this course flow.
If the script itself reports a missing prerequisite, reflect that exactly.

### 5. Migrate my local app database to Supabase

For this class, default to SQLite.
The local DB remains intact after migration.
Supabase becomes the new source of truth afterward.

If the user gives a local DB path, run:

```bash
./.cursor/scripts/supabase-helper.sh migrate-local-db --source sqlite --db-path <path>
```

If the user does not give a path, ask for the SQLite DB path in chat.
Do not invent one.

If the script generates SQL instead of applying it automatically, explain clearly what was generated and what the student should verify in the Supabase dashboard.

### 6. Check Supabase setup status

Run:

```bash
./.cursor/scripts/supabase-helper.sh status
```

Then summarize the current state in a concise table or bullet-style structure, including:
- Supabase CLI installed/logged in
- local Supabase folder initialized or not
- cloud project connected or not
- project ref if available
- project URL if available
- migration files present or not
- helper config file present or not

If already connected, recommend the next likely step from this set:
- create migration
- push schema
- migrate SQLite data
- reconnect to another project

Do NOT include stale wording like “push needs Docker” unless the script explicitly says so.

## Notes for the agent

- The shell script is the executor. The chat is the menu.
- Query / inspect / verify can be demonstrated in the Supabase dashboard.
- Cloud project creation stays in the dashboard for this teaching flow.
- The helper-owned local memory file is `.supabase-helper.json`.
- If some earlier uploaded files are unavailable, work from the latest script and the current chat agreement.
