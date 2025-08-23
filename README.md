# Ruby on Rails Docker Development Environment

This repository provides a minimal, lightweight Docker-based development environment for Ruby on Rails applications. The goal is to provide a consistent, version-controlled environment that a team of developers can use to work on one or more Rails applications.

The intended workflow is for each developer to clone this repository, start the container, and connect to it with a remote-enabled IDE (like VS Code or Cursor). All application code lives in a local directory that you must specify, which is then mounted into the container. This directory is ignored by this repository's version control.

**Key Features:**

- ✅ Provides a consistent Ruby & Rails environment for a whole team
- ✅ Uses Docker to avoid local installation of dependencies
- ✅ Includes a ready-to-use PostgreSQL container
- ✅ Safely isolates the environment's Git history from the application's Git history

## 🚀 Quick Start: The Development Workflow

This setup provides a container that acts as a development server. You start it once, connect your IDE, and perform all your work inside your designated workspace directory.

**Step 1: Initial Setup (First time only)**

1.  **Create a `.env` file:**
    This file is where you will define the path to your local workspace directory. It is crucial for telling Docker where to mount your application code from.

    ```bash
    touch .env
    ```

2.  **Define your workspace path:**
    Open the `.env` file and add the `LOCAL_WORKSPACE_PATH` variable. For a standard setup, you can point it to a `./workspace` directory.

    ```
    # .env
    LOCAL_WORKSPACE_PATH=./workspace
    ```

    **⚠️ WARNING:** You **MUST** ensure this path is correct. An incorrect path could target the wrong directory, leading to unintended modifications to your existing projects or files.

3.  **Create the workspace directory:**
    This directory will contain all of your application code. Make sure the path matches what you set in your `.env` file.

    ```bash
    mkdir workspace
    ```

4.  **Build and start the container:**
    This command starts the `app` and `postgres` containers in the background. It includes a safety check to prevent you from accidentally mounting an existing project into a new environment.

    ```bash
    ./start.sh --build # Pass --build on the first run
    # Use -d to run silently in the background, e.g., ./start.sh -d
    ```

**Step 2: Daily Workflow**

1.  **Start the container:**
    If the container is not already running, start it using the script.

    ```bash
    ./start.sh # Use -d to run silently in the background
    ```

2.  **Connect your IDE to the container:**
    Use your IDE's remote development feature to attach to the running `app` service container (e.g., in VS Code / Cursor, use "Dev Containers: Attach to Running Container...").

3.  **Work on your application:**
    - Once attached, your IDE should be in the `/app` directory (which is your local `./workspace` directory).
    - Use the integrated terminal for all your development tasks (running `git`, `rails`, `bundle`, etc.).
    - If you are starting a new project, you can now safely run `git clone ...` or `rails new ...` here without causing conflicts.

### Example: Starting a New Rails App

After connecting your IDE to the container, run these commands in the integrated terminal:

1.  **Create the app:**

    ```bash
    # This creates a new app in a subdirectory, e.g., /app/my-new-project
    rails new my-new-project --css=bootstrap --database=postgresql
    ```

    _Note: The Rails application is now located at `./workspace/my-new-project` on your local machine._

2.  **Configure `database.yml`:**
    Navigate to the new project (`cd my-new-project`) and edit `config/database.yml` to connect to the `postgres` service.

    ```yaml
    # ./workspace/my-new-project/config/database.yml
    default: &default
      adapter: postgresql
      encoding: unicode
      pool: 5
      host: postgres
      username: postgres
      password: password

    development:
      <<: *default
      database: my-new-project_development

    test:
      <<: *default
      database: my-new-project_test
    ```

3.  **Set up the database and start the server:**

    ```bash
    # Inside /app/my-new-project
    rails db:create
    rails server -b 0.0.0.0
    ```

Your new Rails application will be available at http://localhost:3000.

## 🛠️ What's Included

- **Ruby 3** - Installed via Mise
- **Rails** - Latest version installed as a gem
- **PostgreSQL 16** - Available as a separate, ready-to-use container
- **SQLite3** - Available for simpler projects
- **Mise** - Modern version manager following official Rails installation guide

## 📁 Development Workflow

With your IDE connected to the container, your workflow is the same as local development. Use the integrated terminal to run commands.

### Running Rails Commands

```bash
# Generate a new controller
rails generate controller Pages home

# Run database migrations
rails db:migrate

# Open Rails console
rails console

# Run tests
rails test
```

### Installing New Gems

1.  Add the gem to your `Gemfile`.
2.  Run `bundle install` in the integrated terminal.

### Using `docker-compose exec` (Alternative)

For quick, one-off commands, you can still use `docker-compose exec` from your local machine's terminal without attaching your full IDE. However, for starting the services, always use `./start.sh`.

```bash
# Run database migrations
docker-compose exec app rails db:migrate

# Open a shell in the container
docker-compose exec app bash
```

### Database Operations

```bash
# Create databases (for PostgreSQL)
docker-compose exec app rails db:create

# Run migrations
docker-compose exec app rails db:migrate

# Seed database
docker-compose exec app rails db:seed

# Reset database
docker-compose exec app rails db:reset
```

## 🔧 Customization

### Environment Variables

You can customize the environment by creating a `.env` file in the root of this project.

- `LOCAL_WORKSPACE_PATH` - **(Required)** Defines the local path that mounts to the container's `/home/dev/app` directory.
  - **⚠️ WARNING:** You **MUST** ensure the path is correct. An incorrect path could target the wrong directory, leading to unintended modifications to your existing projects or files.
- `RAILS_ENV` - Rails environment (development, test, production). Defaults to `development`.

### Adding New Services

To add new services (like Redis, Elasticsearch, etc.), add them to the `docker-compose.yml` file if needed for your specific project.

## 📊 Accessing Services

- **Rails App**: http://localhost:3000 (after you manually start the server)
- **PostgreSQL**: Connect with a database client at `localhost:5432` (User: `postgres`, Pass: `password`)

## 🐛 Troubleshooting

### Container Won't Start

- **Check the logs**: If `./start.sh` fails, first check the output in your terminal.
- **Run `docker-compose` directly**: To bypass the script for debugging, you can try running `docker-compose up` after ensuring your `.env` file is correct.
- **View Docker Compose logs**:

  ```bash
  docker-compose logs app
  ```

- **Rebuild containers**:

  ```bash
  docker-compose down && ./start.sh --build -d
  ```

### Database Issues

If you have issues connecting to PostgreSQL, ensure the `postgres` container is running: `docker-compose ps`.

```bash
# Reset PostgreSQL databases
docker-compose exec app rails db:drop db:create db:migrate

# Or rebuild everything from scratch
docker-compose down --volumes && ./start.sh --build -d
```

## 🧹 Cleanup

To stop and remove all resources, run the following commands from your local machine:

```bash
# Stop and remove containers
docker-compose down

# Optional: Remove all unused Docker data (containers, volumes, images)
docker system prune -a --volumes
```

## 🤝 Contributing

Contributions are welcome! If you have any ideas, suggestions, or bug reports, please open an issue or submit a pull request.

## 📜 License

This project is open-source and available under the [MIT License](LICENSE).

## 📝 Notes

- Your application source code lives in the directory defined by `LOCAL_WORKSPACE_PATH` in your `.env` file, which is mounted into `/app` in the container.
- The path pointed to by `LOCAL_WORKSPACE_PATH` (e.g., `./workspace`) is ignored by this repository's `.gitignore` file, allowing your applications to have their own separate Git history.
- The PostgreSQL data is persisted in a local `./postgres_data` directory, which is also ignored by Git.
- The container creates a `dev` user with the same UID/GID as your host user to avoid permission issues.
