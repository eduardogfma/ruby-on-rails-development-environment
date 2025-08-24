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

# 5. Check for PostgreSQL configuration changes after the first run
PG_CHECKSUM_FILE=".pg_config.checksum"

if [ -n "$POSTGRES_DB" ] && [ -n "$POSTGRES_USER" ]; then
    # Create a checksum of the relevant PG variables.
    # The 'tr' command is used to ensure consistent checksums across different OS environments.
    CURRENT_PG_CONFIG="DB:${POSTGRES_DB},USER:${POSTGRES_USER}"
    CURRENT_CHECKSUM=$(echo -n "$CURRENT_PG_CONFIG" | shasum | tr -d '[:space:]-')

    # Check if a checksum from a previous run is present.
    # The presence of the checksum file implies the database was already initialized.
    if [ -f "$PG_CHECKSUM_FILE" ]; then
        PREVIOUS_CHECKSUM=$(cat "$PG_CHECKSUM_FILE")
        if [ "$CURRENT_CHECKSUM" != "$PREVIOUS_CHECKSUM" ]; then
            echo "🚨  CRITICAL WARNING: PostgreSQL configuration has changed in your .env file." >&2
            echo "   Your existing database volume was created with a different user or database name." >&2
            echo "   To apply these new settings, you must destroy the existing database volume." >&2
            echo >&2
            echo "   RECOMMENDED ACTION: Run 'docker compose down -v' and then './start.sh' again." >&2
            echo >&2
            read -p "   Do you want to continue anyway with the old database configuration? (y/N) " -n 1 -r
            echo # Move to a new line
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "   Operation cancelled." >&2
                exit 1
            fi
        fi
    fi
fi

# 6. Generate init.sql from template if a template file exists
INIT_SQL_TEMPLATE_PATH="postgres/init.sql.template"
INIT_SQL_PATH="postgres/init.sql"

if [ -f "$INIT_SQL_TEMPLATE_PATH" ]; then
    echo "⚙️  Generating $INIT_SQL_PATH from template..."
    # Use a delimiter for sed that is unlikely to be in the variables
    sed -e "s|\${POSTGRES_DB}|${POSTGRES_DB}|g" \
        -e "s|\${POSTGRES_USER}|${POSTGRES_USER}|g" \
        "$INIT_SQL_TEMPLATE_PATH" > "$INIT_SQL_PATH"
fi

# 7. If all checks pass, start docker compose and update checksum
echo "✅ All checks passed. Starting Docker Compose..."
docker compose up "$@"

# After a successful start (or if the user continues), update the checksum file
if [ -n "$POSTGRES_DB" ] && [ -n "$POSTGRES_USER" ]; then
    echo -n "$CURRENT_CHECKSUM" > "$PG_CHECKSUM_FILE"
fi
