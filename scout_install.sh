#!/bin/bash

# Define variables
SCRIPT_URL="https://raw.githubusercontent.com/yornfifty/chasm-scout-bash/main/scout.sh"
SCRIPT_NAME="scout"
DESTINATION="/usr/local/bin/$SCRIPT_NAME"

# Download the script
echo "Downloading script from $SCRIPT_URL..."
wget -O /tmp/$SCRIPT_NAME $SCRIPT_URL

# Check if wget was successful
if [ $? -ne 0 ]; then
  echo "Failed to download the script."
  exit 1
fi

# Make the script executable
chmod +x /tmp/$SCRIPT_NAME

# Move the script to /usr/local/bin
echo "Moving script to $DESTINATION..."
sudo mv /tmp/$SCRIPT_NAME $DESTINATION

# Verify the script is in place
if [ $? -eq 0 ]; then
  echo "Script successfully installed as '$SCRIPT_NAME'."
else
  echo "Failed to move the script to $DESTINATION."
  exit 1
fi
