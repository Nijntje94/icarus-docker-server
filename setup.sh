#!/bin/bash

echo "=== Icarus Dedicated Server Setup ==="
echo ""

# Check of docker en docker-compose geïnstalleerd zijn
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is niet geïnstalleerd. Installeer eerst Docker."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is niet geïnstalleerd. Installeer eerst docker-compose."
    exit 1
fi

# Vraag om server configuratie
read -p "Server naam [makkers]: " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-makkers}

read -p "Join wachtwoord [changeme]: " JOIN_PASSWORD
JOIN_PASSWORD=${JOIN_PASSWORD:-changeme}

read -p "Admin wachtwoord [adminchangeme]: " ADMIN_PASSWORD
ADMIN_PASSWORD=${ADMIN_PASSWORD:-adminchangeme}

read -p "Max spelers [8]: " MAX_PLAYERS
MAX_PLAYERS=${MAX_PLAYERS:-8}

read -p "Server poort [17777]: " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-17777}

read -p "Query poort [27015]: " QUERY_PORT
QUERY_PORT=${QUERY_PORT:-27015}

read -p "UID [1000]: " UID
UID=${UID:-1000}

read -p "GID [1000]: " GID
GID=${GID:-1000}

echo ""
echo "=== Configuratie ==="
echo "Server naam: $SERVER_NAME"
echo "Join wachtwoord: $JOIN_PASSWORD"
echo "Admin wachtwoord: $ADMIN_PASSWORD"
echo "Max spelers: $MAX_PLAYERS"
echo "Server poort: $SERVER_PORT"
echo "Query poort: $QUERY_PORT"
echo ""

read -p "Doorgaan met deze configuratie? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup geannuleerd."
    exit 1
fi

# Maak docker-compose.yml
echo "📝 Maak docker-compose.yml..."
cat > docker-compose.yml << COMPOSE_EOF
services:
  icarus:
    container_name: icarus-dedicated
    image: ich777/steamcmd:icarus
    hostname: icarus-dedicated
    restart: "unless-stopped"
    ports:
      - ${SERVER_PORT}:17777/udp
      - ${QUERY_PORT}:27015/udp
    volumes:
      - ./serverfiles:/serverdata/serverfiles
      - ./steamcmd:/serverdata/steamcmd
    environment:
      - UID=${UID}
      - GID=${GID}
      - GAME_ID=2089300
      - GAME_NAME=icarus
      - GAME_PARAMS=-Log -PORT=17777 -QueryPort=27015 -SteamServerName=${SERVER_NAME}
      - GAME_PORT=17777
      - VALIDATE=true
COMPOSE_EOF

# Maak config directories
echo "📁 Maak config directories..."
mkdir -p ./serverfiles/Icarus/Saved/Config/WindowsServer

# Maak ServerSettings.ini
echo "📝 Maak ServerSettings.ini..."
cat > ./serverfiles/Icarus/Saved/Config/WindowsServer/ServerSettings.ini << CONFIG_EOF
[/Script/Icarus.DedicatedServerSettings]
SessionName=${SERVER_NAME}
JoinPassword=${JOIN_PASSWORD}
MaxPlayers=${MAX_PLAYERS}
AdminPassword=${ADMIN_PASSWORD}
ShutdownIfNotJoinedFor=300.000000
ShutdownIfEmptyFor=300.000000
AllowNonAdminsToLaunchProspects=True
AllowNonAdminsToDeleteProspects=False
ResumeProspect=True
CONFIG_EOF

# Maak Game.ini
echo "📝 Maak Game.ini..."
cat > ./serverfiles/Icarus/Saved/Config/WindowsServer/Game.ini << GAME_EOF
[/Script/Icarus.IcarusGameState]
JoinPassword=${JOIN_PASSWORD}
AdminPassword=${ADMIN_PASSWORD}
ServerName=${SERVER_NAME}
MaxPlayers=${MAX_PLAYERS}
GAME_EOF

echo ""
echo "✅ Setup compleet!"
echo ""
echo "Start de server met: docker-compose up -d"
echo "Bekijk logs met: docker-compose logs -f icarus"
echo "Stop de server met: docker-compose down"
echo ""
