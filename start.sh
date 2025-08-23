#!/bin/bash
set -e

# ---
# Safety check script for Docker Compose
# ---
# This script ensures that the LOCAL_WORKSPACE_PATH is explicitly defined in a .env file
# and warns the user if the target directory is not empty, preventing accidental
# modification of an existing project when spinning up a new environment.
# ---

# 1. Check for .env file
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found."
    echo "Please create a .env file and define LOCAL_WORKSPACE_PATH."
    echo "Example: echo 'LOCAL_WORKSPACE_PATH=./workspace' > .env"
    exit 1
fi

# 2. Load environment variables from .env
# Using a POSIX-compliant way to load .env variables
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# 3. Check if LOCAL_WORKSPACE_PATH is set
if [ -z "$LOCAL_WORKSPACE_PATH" ]; then
    echo "❌ Error: LOCAL_WORKSPACE_PATH is not set in your .env file."
    echo "Please define it in .env, for example: LOCAL_WORKSPACE_PATH=./workspace"
    exit 1
fi

# 4. Check if the workspace directory exists and is not empty
if [ -d "$LOCAL_WORKSPACE_PATH" ] && [ "$(ls -A "$LOCAL_WORKSPACE_PATH")" ]; then
    echo "⚠️  Warning: The specified workspace directory '$LOCAL_WORKSPACE_PATH' is not empty."
    read -p "   Are you sure you want to continue and mount this directory? (y/N) " -n 1 -r
    echo # Move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Operation cancelled."
        echo "   If you're starting a new project, please set LOCAL_WORKSPACE_PATH in your .env file to a new or empty directory."
        exit 1
    fi
fi

# 5. If all checks pass, start docker compose
echo "✅ All checks passed. Starting Docker Compose..."
docker compose up "$@"
