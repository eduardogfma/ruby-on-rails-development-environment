FROM ubuntu:22.04

ARG DEFAULT_SHELL=/bin/bash

# Install system dependencies following official Rails installation guide
RUN apt update && \
    apt install -y curl git build-essential rustc libssl-dev libyaml-dev zlib1g-dev libgmp-dev zsh

# Define timezone
ENV TZ=Europe/Berlin
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Create a non-root user to match host user, and grant sudo permissions
ARG UID=1000
ARG GID=1000
RUN groupadd -g $GID dev && \
    useradd -u $UID -g $GID -m -s $DEFAULT_SHELL dev
RUN apt-get update && apt-get install -y sudo && \
    echo "dev ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to the new user
USER dev
WORKDIR /home/dev

# Install Mise version manager
RUN curl https://mise.run | sh

# Add mise and its shims to the PATH for the new user.
ENV PATH="/home/dev/.local/bin:/home/dev/.local/share/mise/shims:${PATH}"
RUN if [ "$DEFAULT_SHELL" = "/bin/zsh" ]; then \
    echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.zshrc; \
    else \
    echo 'eval "$(~/.local/bin/mise activate)"' >> ~/.bashrc; \
    fi

# Install Ruby and set it as the global version.
# This will install Ruby and make it available for subsequent commands.
RUN mise use -g ruby@3

# Install Rails using the gem shim that is now in the PATH.
RUN gem install rails

# Set working directory for the application
WORKDIR /home/dev/app

# # Install gems if Gemfile exists. The `bundle` command will be found via the shims path.
# RUN if [ -f Gemfile ]; then bundle install; fi

# Expose port
EXPOSE 3000

# # Start Rails server. The `rails` command will be found via the shims path.
# CMD bash -c 'rm -f /app/tmp/pids/server.pid && rails server -b 0.0.0.0'

CMD ["sleep", "infinity"]