#!/bin/bash

# Define the directory name variable
CHASM_DIR="$HOME/chasm-scout-nodes"

# Function to display available arguments and their purposes
show_help() {
    echo "Usage: $0 [OPTION]"
    echo "Available options:"
    echo "  upgrade    Rebuild and restart all Docker containers."
    echo "  stop       Stop all Docker containers."
    echo "  help       Show this help message."
}

# Function to check if a port is in use
is_port_in_use() {
    local PORT=$1
    if ss -tuln | grep -q ":$PORT "; then
        return 0  # Port is in use
    else
        return 1  # Port is not in use
    fi
}

# Function to allow a port through the firewall
allow_port() {
    local PORT=$1
    if command -v ufw >/dev/null; then
        echo "Configuring firewall with ufw to allow port $PORT..."
        sudo ufw allow $PORT/tcp || { echo "Failed to configure ufw."; exit 1; }
    elif command -v firewall-cmd >/dev/null; then
        echo "Configuring firewall with firewalld to allow port $PORT..."
        sudo firewall-cmd --permanent --add-port=$PORT/tcp || { echo "Failed to configure firewalld."; exit 1; }
        sudo firewall-cmd --reload || { echo "Failed to reload firewalld."; exit 1; }
    else
        echo "No supported firewall tool found (ufw or firewalld)."
    fi
}

# Convert SCOUT_NAME to lower_snake_case
convert_to_lower_snake_case() {
    local NAME=$1
    echo "$NAME" | awk '{gsub(/ /,"_"); print tolower($0)}'
}

# Function to prompt for non-empty input
prompt_for_non_empty() {
    local PROMPT=$1
    local VAR
    while [ -z "$VAR" ]; do
        read -p "$PROMPT" VAR
        if [ -z "$VAR" ]; then
            echo "Input cannot be empty. Please enter a valid value."
        fi
    done
    echo "$VAR"
}

# Function to prompt for optional input
prompt_for_optional() {
    local PROMPT=$1
    local VAR
    read -p "$PROMPT" VAR
    echo "$VAR"
}

# Get the current public IP address
CURRENT_IP=$(curl -s ifconfig.me)

# Prompt user for input values
SCOUT_UID=$(prompt_for_non_empty "Enter the Scout UID: ")
WEBHOOK_API_KEY=$(prompt_for_non_empty "Enter the Webhook API Key: ")
GROQ_API_KEY=$(prompt_for_non_empty "Enter the Groq API Key: ")
OPENROUTER_API_KEY=$(prompt_for_optional "Enter the OpenRouter API Key (optional, press Enter to skip): ")
PORT=$(prompt_for_optional "Enter the port to publish (default: 3001): ")
PUBLIC_IP=$(prompt_for_optional "Enter your public IP address (default: $CURRENT_IP): ")
SCOUT_NAME=$(prompt_for_optional "Enter the Scout Name (default: SCOUT-$SCOUT_UID): ")

# Use default values if not provided
PUBLIC_IP=${PUBLIC_IP:-$CURRENT_IP}
PORT=${PORT:-3001}
SCOUT_NAME=${SCOUT_NAME:-SCOUT-$SCOUT_UID}

# Increment port if it is already in use
INITIAL_PORT=$PORT
while is_port_in_use $PORT; do
    PORT=$((PORT + 1))
done

# Allow the port through the firewall if PORT is provided
if [ -n "$PORT" ]; then
    allow_port $PORT
fi

# Convert SCOUT_NAME to lower_snake_case for the container name
CONTAINER_NAME=$(convert_to_lower_snake_case "$SCOUT_NAME")

# Define the path for the docker-compose.yaml file
FILE="$CHASM_DIR/$SCOUT_NAME/docker-compose.yaml"

# Create the directory for the Dockerfile and docker-compose.yaml
mkdir -p "$(dirname "$FILE")"

# Check if the file already exists
if [ -f "$FILE" ]; then
    echo "File $FILE already exists. It will be overwritten."
fi

# Create the docker-compose.yaml file with the specified content
cat <<EOF > $FILE
services:
  $CONTAINER_NAME:
    image: chasmtech/chasm-scout:latest
    container_name: $CONTAINER_NAME
    restart: always
EOF

# Add ports and environment variables based on user input
if [ -n "$PORT" ]; then
    echo "    ports:" >> $FILE
    echo "      - \"$PORT:$PORT\"" >> $FILE
    echo "    environment:" >> $FILE
    echo "      PORT: $PORT" >> $FILE
    echo "      WEBHOOK_URL: http://$PUBLIC_IP:$PORT" >> $FILE
fi

cat <<EOF >> $FILE
      LOGGER_LEVEL: debug
      ORCHESTRATOR_URL: https://orchestrator.chasm.net
      SCOUT_NAME: "$SCOUT_NAME"
      SCOUT_UID: $SCOUT_UID
      WEBHOOK_API_KEY: $WEBHOOK_API_KEY
      PROVIDERS: $(if [ -n "$OPENROUTER_API_KEY" ]; then echo "groq,openrouter"; else echo "groq"; fi)
      MODEL: gemma2-9b-it
      GROQ_API_KEY: $GROQ_API_KEY
EOF

# Comment out OPENAI_API_KEY
echo "      # OPENAI_API_KEY: $OPENAI_API_KEY" >> $FILE

# Add OPENROUTER_API_KEY to the environment if it was provided
if [ -n "$OPENROUTER_API_KEY" ]; then
    echo "      OPENROUTER_API_KEY: $OPENROUTER_API_KEY" >> $FILE
fi

# Close the EOF delimiter for the docker-compose.yaml file
cat <<EOF >> $FILE
EOF

echo "docker-compose.yaml file created successfully at $FILE with port $PORT."
echo "Dockerfile directory created at $CHASM_DIR/$SCOUT_NAME."

# Prompt user to run the Docker container
read -p "Do you want to run the Docker container now? (yes/no, default: yes): " RUN_CONTAINERS
RUN_CONTAINERS=${RUN_CONTAINERS:-yes}

if [ "$RUN_CONTAINERS" == "yes" ]; then
    cd "$CHASM_DIR/$SCOUT_NAME" || { echo "Directory $CHASM_DIR/$SCOUT_NAME not found."; exit 1; }
    docker compose up -d || { echo "Failed to start Docker container for $SCOUT_NAME."; exit 1; }
    echo "Docker container for $SCOUT_NAME is now running."
fi
