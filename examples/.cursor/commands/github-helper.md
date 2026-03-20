Run basic git and github commands from agent

description: Guided helper for basic Git and GitHub tasks for students. Use when the user wants to initialize a repo, check status, list branches, push code, or roll back the last commit.
---

# GitHub Helper

This skill helps students perform a few common Git and GitHub actions in a guided way.

## Supported actions

1. Init repo
2. Push code to selected branch
3. List branches
4. Roll back previous commit
5. Status

## Core rule

You must EXECUTE the helper script directly.
Do NOT explain to the user how to run the script themselves.
Do NOT tell the user to open Terminal / PowerShell unless the script output says a required tool is missing.
Do NOT replace the helper with raw git commands unless the helper script itself fails.

## Meaning of each option

1. **Init repo**
   - This is the full setup option.
   - It must always try to do all of the following:
     - initialize local Git if needed
     - create/connect a private GitHub repo if needed
     - commit if needed
     - push if possible
   - If the folder is already a local Git repo but has no GitHub remote yet, option 1 must still create/connect the GitHub repo.
   - Do NOT redirect the user from option 1 to option 2 in that case.

2. **Push code to selected branch**
   - Use only when the repo is already initialized and already connected to GitHub.

3. **List branches**
   - Show available branches.

4. **Roll back previous commit**
   - Destructive. Ask for confirmation first.

5. **Status**
   - Show installation / repo / remote status and recommend the next step.

## Menu

When invoked, present this menu exactly:

1. Init repo
2. Push code to selected branch
3. List branches
4. Roll back previous commit
5. Status

Then ask the user which option they want.

## Execution

Use the matching script for the user's operating system.

On macOS or Linux, execute:

```bash
.cursor/scripts/github-helper.sh <action>

On Windows, execute:

powershell -ExecutionPolicy Bypass -File .cursor\scripts\github-helper.ps1 <action>

Where <action> is one of:
	•	init
	•	push
	•	branches
	•	rollback
	•	status
