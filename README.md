# Icarus Dedicated Server - Docker

Easy setup for an Icarus dedicated server using Docker.

## Requirements

- Docker
- docker-compose
- Open ports: 17777/udp and 27015/udp

## Quick Start
```bash
# Clone the repo
git clone https://github.com/Nijntje94/icarus-docker-server/.git
cd icarus-docker-server

# Run setup script
./setup.sh

# Start the server
docker-compose up -d

# View logs
docker-compose logs -f icarus
```

## Manual Setup

1. Copy `docker-compose.yml.example` to `docker-compose.yml`
2. Adjust the following variables:
   - `YOUR_SERVER_NAME` - Name of your server
   - `YOUR_JOIN_PASSWORD` - Password to join
   - `YOUR_ADMIN_PASSWORD` - Admin password

3. Create config directory:
```bash
mkdir -p ./serverfiles/Icarus/Saved/Config/WindowsServer
```

4. Copy `config-templates/ServerSettings.ini.example` to `./serverfiles/Icarus/Saved/Config/WindowsServer/ServerSettings.ini`
5. Adjust the placeholders in ServerSettings.ini

6. Start the server:
```bash
docker-compose up -d
```

## Server Management
```bash
# Start server
docker-compose up -d

# Stop server
docker-compose down

# Restart server
docker-compose restart icarus

# View logs
docker-compose logs -f icarus

# Update server
docker-compose down
docker-compose pull
docker-compose up -d
```

## Configuration

### Ports
- **17777/udp** - Game port
- **27015/udp** - Query port (server browser)

### ServerSettings.ini Options

- `SessionName` - Server name in browser
- `JoinPassword` - Password to join
- `AdminPassword` - Admin password for in-game commands
- `MaxPlayers` - Maximum number of players (1-8)
- `ShutdownIfNotJoinedFor` - Seconds until pause when nobody joins (-1 = never)
- `ShutdownIfEmptyFor` - Seconds until pause when server is empty (-1 = never)

## Firewall

Ubuntu/Debian (ufw):
```bash
sudo ufw allow 17777/udp
sudo ufw allow 27015/udp
```

RHEL/CentOS (firewalld):
```bash
sudo firewall-cmd --permanent --add-port=17777/udp
sudo firewall-cmd --permanent --add-port=27015/udp
sudo firewall-cmd --reload
```

## Delete World/Save Data
```bash
docker-compose stop icarus
rm -rf ./serverfiles/Icarus/Saved/PlayerData/*
rm -rf ./serverfiles/Icarus/Saved/ProspectData/*
docker-compose start icarus
```

## Troubleshooting

**Server doesn't ask for password**
- Check if ServerSettings.ini is created correctly
- Restart the container: `docker-compose restart icarus`

**Cannot connect**
- Check firewall rules
- Verify ports are open: `sudo ss -tulpn | grep -E '17777|27015'`

**Server name is a random number**
- Check if `-SteamServerName` parameter is in GAME_PARAMS
- Restart the container

## Credits

- Docker image: [ich777/steamcmd:icarus](https://hub.docker.com/r/ich777/steamcmd)
- Game: [Icarus by RocketWerkz](https://store.steampowered.com/app/1149460/ICARUS/)
