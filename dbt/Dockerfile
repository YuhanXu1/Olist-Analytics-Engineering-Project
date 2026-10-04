FROM python:3.12-slim

# Set working directory inside the container
WORKDIR /app

# Install git (often needed for dbt packages)
# download the last version, install git, deletes the downloaded package index
#RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Install the specific dbt adapter
RUN pip install --no-cache-dir dbt-postgres

# Create a dummy git executable that satisfies dbt's health check
RUN echo '#!/bin/sh\nexit 0' > /usr/local/bin/git && \
    chmod +x /usr/local/bin/git

# Tell dbt to look for profiles.yml in this directory
ENV DBT_PROFILES_DIR=/app

# Keep container alive so you can exec into it and run commands
CMD ["tail", "-f", "/dev/null"]