# What this script do?
- create `/root/chasm-scout-nodes/<SCOUT_NAME>/docker-compose.yaml`
- start docker container
- allowing given publish port with `ufw`

# Setup Guide
1. get and install
```bash
wget -O scout-install.sh https://raw.githubusercontent.com/yornfifty/chasm-scout-bash/main/scout_install.sh --no-cache && chmod +x scout-install.sh && ./scout-install.sh
```

2. start the initalization
type `scout` and enter

3. Answer all the promp
- `Enter the Scout UID: ` _Type your `SCOUT_UID`_

- `Enter the Webhook API Key: ` _Type Your Scout WEBHOOK_API_KEY_

- `Enter the Groq API Key: ` _Type Your_[ Groq API Key](https://console.groq.com/keys)

- `Enter the OpenRouter API Key (optional, press Enter to skip): ` _You can fill this or skip with enter_

- `Enter the port to publish (default: 3001): ` _Default is *3001*, or type your desired port (e.g., `3333`)_

- `Enter your public IP address (default: your_public_ip): ` _Default is *your_public_ip*, or type your public IP_

- `Enter the Scout Name (default: SCOUT-SCOUT_UID): ` _Default is "SCOUT-SCOUT_UID", or type your desired Scout Name_

