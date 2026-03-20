#!/usr/bin/env bash

set -euo pipefail

ACTION="${1:-}"

say() {
  printf "\n%s\n" "$1"
}

info() {
  printf "[INFO] %s\n" "$1"
}

warn() {
  printf "[WARN] %s\n" "$1"
}

err() {
  printf "[ERROR] %s\n" "$1" >&2
}

detect_os() {
  case "$(uname -s)" in
    Darwin) printf "macos" ;;
    Linux) printf "linux" ;;
    *) printf "unknown" ;;
  esac
}

is_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || true
}

at_repo_root() {
  [ "$(pwd)" = "$(repo_root)" ]
}

has_commits() {
  git rev-parse --verify HEAD >/dev/null 2>&1
}

current_branch() {
  git branch --show-current 2>/dev/null || true
}

has_origin_remote() {
  git remote get-url origin >/dev/null 2>&1
}

origin_url() {
  git remote get-url origin 2>/dev/null || true
}

remote_repo_reachable() {
  git ls-remote origin >/dev/null 2>&1
}

current_folder_name() {
  basename "$PWD"
}

repo_root_name() {
  local root
  root="$(repo_root)"
  [ -n "$root" ] && basename "$root" || true
}

latest_commit_short() {
  git log -1 --pretty=format:'%h - %s' 2>/dev/null || true
}

default_repo_name() {
  if is_git_repo; then
    repo_root_name
  else
    basename "$PWD"
  fi
}

default_commit_message() {
  printf "%s" "${GITHUB_HELPER_COMMIT_MESSAGE:-Update files}"
}

initial_commit_message() {
  printf "%s" "${GITHUB_HELPER_INITIAL_COMMIT_MESSAGE:-Initial commit}"
}

show_git_missing_message() {
  cat <<EOF
Git is not installed on this computer.

Git is required for all actions in github-helper because it tracks your project files and history.

What to do now:

1. Open a terminal window.
   - On macOS: open the "Terminal" app
   - On Linux: open your Terminal app

2. Install Git.

EOF

  case "$(detect_os)" in
    macos)
      cat <<EOF
   macOS:
   - Website: https://git-scm.com/download/mac
   - Or, if you use Homebrew, run this in Terminal:
     brew install git
EOF
      ;;
    linux)
      cat <<EOF
   Linux:
   - Website: https://git-scm.com/download/linux
   - Ubuntu / Debian:
     sudo apt update && sudo apt install -y git
   - Fedora:
     sudo dnf install -y git
EOF
      ;;
    *)
      cat <<EOF
   Download Git here:
   - https://git-scm.com/downloads
EOF
      ;;
  esac

  cat <<EOF

3. After installation finishes, return to Cursor.

4. In the Cursor chat, run this command again:
   /github-helper
EOF
}

show_gh_missing_message() {
  cat <<EOF
GitHub CLI (gh) is not installed on this computer.

GitHub CLI is needed when github-helper creates a GitHub repository for you
or connects this project to GitHub automatically.

What to do now:

1. Open a terminal window.
   - On macOS: open the "Terminal" app
   - On Linux: open your Terminal app

2. Install GitHub CLI.

EOF

  case "$(detect_os)" in
    macos)
      cat <<EOF
   macOS:
   - Website: https://cli.github.com/
   - Or run this in Terminal:
     brew install gh
EOF
      ;;
    linux)
      cat <<EOF
   Linux:
   - Website and install instructions:
     https://cli.github.com/
EOF
      ;;
    *)
      cat <<EOF
   Download GitHub CLI here:
   - https://cli.github.com/
EOF
      ;;
  esac

  cat <<EOF

3. After installation finishes, return to Cursor.

4. In the Cursor chat, run this command again:
   /github-helper
EOF
}

show_gh_auth_missing_message() {
  cat <<EOF
GitHub CLI is installed, but you are not logged in to GitHub yet.

What to do now:

1. Open a terminal window.
   - On macOS: open the "Terminal" app
   - On Linux: open your Terminal app

2. In that terminal, run this command exactly:
   gh auth login

3. Follow the prompts on screen.
   - GitHub may open a browser window
   - Sign in to your GitHub account
   - Approve the login if asked

4. When the login is complete, go back to Cursor.

5. In the Cursor chat, run this command again:
   /github-helper
EOF
}

ensure_git() {
  if command -v git >/dev/null 2>&1; then
    return 0
  fi
  show_git_missing_message
  exit 1
}

ensure_gh() {
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi
  show_gh_missing_message
  exit 1
}

ensure_gh_auth() {
  if gh auth status >/dev/null 2>&1; then
    return 0
  fi
  show_gh_auth_missing_message
  exit 1
}

ensure_branch_exists() {
  local branch
  branch="$(current_branch)"
  if [ -n "$branch" ]; then
    printf "%s" "$branch"
    return 0
  fi

  if git show-ref --verify --quiet refs/heads/main; then
    git checkout main >/dev/null 2>&1
    printf "main"
    return 0
  fi

  git checkout -b main >/dev/null 2>&1
  printf "main"
}

action_status() {
  local git_installed="n"
  local gh_installed="n"
  local gh_logged_in="n"
  local inside_repo="n"
  local root_here="n"
  local remote_configured="n"
  local remote_reachable="n"
  local next_step=""

  if command -v git >/dev/null 2>&1; then
    git_installed="y"
  fi

  if command -v gh >/dev/null 2>&1; then
    gh_installed="y"
    if gh auth status >/dev/null 2>&1; then
      gh_logged_in="y"
    fi
  fi

  if [ "$git_installed" = "y" ] && is_git_repo; then
    inside_repo="y"
    if at_repo_root; then
      root_here="y"
    fi
  fi

  if [ "$inside_repo" = "y" ] && has_origin_remote; then
    remote_configured="y"
    if remote_repo_reachable; then
      remote_reachable="y"
    fi
  fi

  if [ "$git_installed" = "n" ]; then
    next_step="Install Git, then rerun /github-helper"
  elif [ "$gh_installed" = "n" ]; then
    next_step="Install GitHub CLI, then rerun /github-helper"
  elif [ "$gh_logged_in" = "n" ]; then
    next_step="Run gh auth login, then rerun /github-helper"
  elif [ "$inside_repo" = "n" ]; then
    next_step="Run option 1 (Init repo) to initialize this folder locally and on GitHub"
  elif [ "$remote_configured" = "n" ]; then
    next_step="Run option 1 (Init repo) to create and connect the private GitHub repo"
  elif [ "$remote_reachable" = "n" ]; then
    next_step="Run option 1 (Init repo) to recreate or reconnect the GitHub repo"
  else
    next_step="Repo is ready. Use option 2 (Push code) or option 3 (List branches) as needed"
  fi

  say "Status"
  printf "Git installed: %s\n" "$git_installed"
  printf "GitHub CLI installed: %s\n" "$gh_installed"
  if [ "$gh_installed" = "y" ]; then
    printf "GitHub CLI logged in: %s\n" "$gh_logged_in"
  fi
  printf "Inside git repo: %s\n" "$inside_repo"

  if [ "$inside_repo" = "y" ]; then
    printf "At repo root: %s\n" "$root_here"
    printf "Current folder: %s\n" "$(current_folder_name)"
    printf "Repo root: %s\n" "$(repo_root_name)"
    printf "Current branch: %s\n" "$(current_branch)"
    printf "GitHub remote configured: %s\n" "$remote_configured"
    if [ "$remote_configured" = "y" ]; then
      printf "GitHub remote reachable: %s\n" "$remote_reachable"
      printf "Origin URL: %s\n" "$(origin_url)"
    fi
    if has_commits; then
      printf "Latest commit: %s\n" "$(latest_commit_short)"
    else
      printf "Latest commit: No commits yet\n"
    fi
  fi

  printf "Recommended next step: %s\n" "$next_step"

  if [ "$git_installed" = "n" ]; then
    say ""
    show_git_missing_message
  fi
  if [ "$gh_installed" = "n" ]; then
    say ""
    show_gh_missing_message
  fi
  if [ "$gh_installed" = "y" ] && [ "$gh_logged_in" = "n" ]; then
    say ""
    show_gh_auth_missing_message
  fi
}

action_init() {
  ensure_git
  ensure_gh
  ensure_gh_auth

  if is_git_repo; then
    info "Current folder is inside an existing Git repository."
    info "Repo root: $(repo_root)"
    cd "$(repo_root)"
  else
    info "Initializing Git repository with branch 'main'..."
    if ! git init -b main >/dev/null 2>&1; then
      git init >/dev/null 2>&1
      git checkout -b main >/dev/null 2>&1
    fi
    info "Git repository initialized."
  fi

  local repo_name
  repo_name="${GITHUB_HELPER_REPO_NAME:-$(default_repo_name)}"

  if has_origin_remote; then
    if remote_repo_reachable; then
      info "GitHub remote is already connected and reachable."
    else
      warn "Origin exists locally, but GitHub remote is unreachable."
      warn "Reconnecting origin to a newly created private GitHub repo..."
      git remote remove origin
      gh repo create "$repo_name" --private --source=. --remote=origin
      info "GitHub repository created and remote reconnected."
    fi
  else
    info "Creating and connecting private GitHub repository..."
    gh repo create "$repo_name" --private --source=. --remote=origin
    info "GitHub repository created and remote connected."
  fi

  git add .

  if git diff --cached --quiet; then
    warn "No changes to commit."
  elif ! has_commits; then
    git commit -m "$(initial_commit_message)"
    info "Initial commit created."
  else
    git commit -m "$(default_commit_message)"
    info "Commit created."
  fi

  local branch
  branch="$(ensure_branch_exists)"

  if has_origin_remote; then
    git push -u origin "$branch"
    info "Pushed branch '$branch' to GitHub."
  else
    err "GitHub remote is still not connected after init."
    exit 1
  fi
}

action_push() {
  ensure_git

  if ! is_git_repo; then
    err "This folder is not a Git repository. Run option 1 (Init repo) first."
    exit 1
  fi

  cd "$(repo_root)"

  if ! has_origin_remote; then
    err "This repo is not connected to GitHub yet. Run option 1 (Init repo) first."
    exit 1
  fi

  if ! remote_repo_reachable; then
    err "This repo has an origin configured locally, but the GitHub repo is unreachable or no longer exists."
    err "Run option 1 (Init repo) first."
    exit 1
  fi

  local branch
  branch="$(ensure_branch_exists)"

  git add .

  if git diff --cached --quiet; then
    warn "No staged changes to commit."
  else
    git commit -m "$(default_commit_message)"
    info "Commit created."
  fi

  git push -u origin "$branch"
  info "Pushed to origin/$branch"
}

action_branches() {
  ensure_git

  if ! is_git_repo; then
    err "This folder is not a Git repository."
    exit 1
  fi

  cd "$(repo_root)"

  say "Current branch: $(current_branch)"
  say "Local branches:"
  git branch --list

  if has_origin_remote; then
    say ""
    say "Remote branches:"
    git branch -r
  fi
}

action_rollback() {
  ensure_git

  if ! is_git_repo; then
    err "This folder is not a Git repository."
    exit 1
  fi

  cd "$(repo_root)"

  if ! has_commits; then
    err "There are no commits to roll back."
    exit 1
  fi

  if [ "${GITHUB_HELPER_CONFIRM_ROLLBACK:-no}" != "yes" ]; then
    err "Rollback requires explicit confirmation."
    err "Run again with: GITHUB_HELPER_CONFIRM_ROLLBACK=yes"
    exit 1
  fi

  git reset --hard HEAD~1
  info "Rolled back one commit."
}

show_usage() {
  cat <<EOF
Usage:
  ./.cursor/scripts/github-helper.sh init
  ./.cursor/scripts/github-helper.sh push
  ./.cursor/scripts/github-helper.sh branches
  ./.cursor/scripts/github-helper.sh rollback
  ./.cursor/scripts/github-helper.sh status

Optional environment variables:
  GITHUB_HELPER_REPO_NAME
  GITHUB_HELPER_COMMIT_MESSAGE
  GITHUB_HELPER_INITIAL_COMMIT_MESSAGE
  GITHUB_HELPER_CONFIRM_ROLLBACK=yes
EOF
}

main() {
  case "$ACTION" in
    init) action_init ;;
    push) action_push ;;
    branches) action_branches ;;
    rollback) action_rollback ;;
    status) action_status ;;
    *) show_usage; exit 1 ;;
  esac
}

main