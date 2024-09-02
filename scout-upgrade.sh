#!/bin/bash

# Parent directory containing all the scout directories
parent_dir="/root/chasm-scout-nodes"

# Find all directories containing docker-compose.yaml files
compose_dirs=$(find "$parent_dir" -type f -name "docker-compose.yaml" -exec dirname {} \;)

# Remove the cached image
docker rmi chasmtech/chasm-scout:latest --force

# Pull the latest chasm-scout image
docker pull chasmtech/chasm-scout:latest

# Loop through each directory and restart containers
for dir in $compose_dirs; do
    echo "Updating services in $dir"
    cd "$dir" || { echo "Failed to access $dir"; continue; }
    
    # Stop existing containers
    docker compose down

    # Start the services with the latest image and force pull
    docker compose up -d --remove-orphans --pull always
done

echo "All services have been updated."
