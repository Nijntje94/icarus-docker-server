#!/bin/bash

echo "=== Icarus Dedicated Server Setup ==="
echo ""

# Check if docker and docker-compose are installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed. Please install docker-compose first."
    exit 1
fi

# Ask for server configuration
read -p "Server name [makkers]: " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-makkers}

read -p "Join password [changeme]: " JOIN_PASSWORD
JOIN_PASSWORD=${JOIN_PASSWORD:-changeme}

read -p "Admin password [adminchangeme]: " ADMIN_PASSWORD
ADMIN_PASSWORD=${ADMIN_PASSWORD:-adminchangeme}

read -p "Max players [8]: " MAX_PLAYERS
MAX_PLAYERS=${MAX_PLAYERS:-8}

read -p "Server port [17777]: " SERVER_PORT
SERVER_PORT=${SERVER_PORT:-17777}

read -p "Query port [27015]: " QUERY_PORT
QUERY_PORT=${QUERY_PORT:-27015}

read -p "UID [1000]: " UID
UID=${UID:-1000}

read -p "GID [1000]: " GID
GID=${GID:-1000}

echo ""
echo "=== Configuration ==="
echo "Server name: $SERVER_NAME"
echo "Join password: $JOIN_PASSWORD"
echo "Admin password: $ADMIN_PASSWORD"
echo "Max players: $MAX_PLAYERS"
echo "Server port: $SERVER_PORT"
echo "Query port: $QUERY_PORT"
echo ""

read -p "Continue with this configuration? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Create docker-compose.yml
echo "📝 Creating docker-compose.yml..."
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

# Create config directories
echo "📁 Creating config directories..."
mkdir -p ./serverfiles/Icarus/Saved/Config/WindowsServer
mkdir -p ./serverfiles/Icarus/Saved/PlayerData/DedicatedServer/Prospects

# Create ServerSettings.ini
echo "📝 Creating ServerSettings.ini..."
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

# Create Game.ini
echo "📝 Creating Game.ini..."
cat > ./serverfiles/Icarus/Saved/Config/WindowsServer/Game.ini << GAME_EOF
[/Script/Icarus.IcarusGameState]
JoinPassword=${JOIN_PASSWORD}
AdminPassword=${ADMIN_PASSWORD}
ServerName=${SERVER_NAME}
MaxPlayers=${MAX_PLAYERS}
GAME_EOF

echo ""
echo "=== Backup Configuration ==="
read -p "Do you want to restore from a backup? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Backup location [~/backup/icarus]: " BACKUP_LOCATION
    BACKUP_LOCATION=${BACKUP_LOCATION:-~/backup/icarus}
    BACKUP_LOCATION="${BACKUP_LOCATION/#\~/$HOME}"
    
    if [ -d "$BACKUP_LOCATION" ]; then
        # Find all .json files
        mapfile -t JSON_FILES < <(find "$BACKUP_LOCATION" -name "*.json" -type f)
        
        if [ ${#JSON_FILES[@]} -eq 0 ]; then
            echo "⚠️  No backup files found in $BACKUP_LOCATION"
        else
            echo ""
            echo "Available backups:"
            echo "0. None - Skip restore"
            echo "A. All - Restore all backups"
            for i in "${!JSON_FILES[@]}"; do
                filename=$(basename "${JSON_FILES[$i]}")
                echo "$((i+1)). $filename"
            done
            echo ""
            read -p "Select backup to restore (0/A/1-${#JSON_FILES[@]}): " BACKUP_CHOICE
            
            if [[ $BACKUP_CHOICE =~ ^[Aa]$ ]]; then
                echo "📦 Restoring all backups..."
                for file in "${JSON_FILES[@]}"; do
                    filename=$(basename "$file")
                    cp "$file" "./serverfiles/Icarus/Saved/PlayerData/DedicatedServer/Prospects/"
                    echo "   Restored: $filename"
                done
                echo "✅ All backups restored!"
            elif [[ $BACKUP_CHOICE =~ ^[0-9]+$ ]] && [ $BACKUP_CHOICE -ge 1 ] && [ $BACKUP_CHOICE -le ${#JSON_FILES[@]} ]; then
                selected_file="${JSON_FILES[$((BACKUP_CHOICE-1))]}"
                filename=$(basename "$selected_file")
                cp "$selected_file" "./serverfiles/Icarus/Saved/PlayerData/DedicatedServer/Prospects/"
                echo "✅ Restored: $filename"
            elif [ "$BACKUP_CHOICE" == "0" ]; then
                echo "⏭️  Skipping backup restore"
            else
                echo "⚠️  Invalid selection, skipping restore"
            fi
        fi
    else
        echo "⚠️  Backup location does not exist: $BACKUP_LOCATION"
    fi
fi

echo ""
echo "=== Automatic Backup Configuration ==="
read -p "Do you want to set up automatic daily backups? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Backup location [~/backup/icarus]: " BACKUP_LOCATION
    BACKUP_LOCATION=${BACKUP_LOCATION:-~/backup/icarus}
    BACKUP_LOCATION="${BACKUP_LOCATION/#\~/$HOME}"
    
    # Create backup directory
    mkdir -p "$BACKUP_LOCATION"
    
    # Create backup script
    BACKUP_SCRIPT_PATH="$(pwd)/backup-icarus.sh"
    cat > "$BACKUP_SCRIPT_PATH" << BACKUP_SCRIPT_EOF
#!/bin/bash
# Icarus Server Backup Script
# Created by setup.sh

BACKUP_DIR="$BACKUP_LOCATION"
SOURCE_DIR="$(pwd)/serverfiles/Icarus/Saved/PlayerData/DedicatedServer/Prospects"
TIMESTAMP=\$(date +%Y%m%d_%H%M%S)

# Create backup directory if it doesn't exist
mkdir -p "\$BACKUP_DIR"

# Copy all .json files with timestamp
if [ -d "\$SOURCE_DIR" ]; then
    for file in "\$SOURCE_DIR"/*.json; do
        if [ -f "\$file" ]; then
            filename=\$(basename "\$file" .json)
            cp "\$file" "\$BACKUP_DIR/\${filename}_\${TIMESTAMP}.json"
            echo "Backed up: \${filename}_\${TIMESTAMP}.json"
        fi
    done
    echo "Backup completed at \$(date)"
else
    echo "Error: Source directory does not exist: \$SOURCE_DIR"
    exit 1
fi

# Optional: Remove backups older than 30 days
find "\$BACKUP_DIR" -name "*.json" -type f -mtime +30 -delete
BACKUP_SCRIPT_EOF
    
    chmod +x "$BACKUP_SCRIPT_PATH"
    
    # Add to crontab
    CRON_JOB="0 4 * * * $BACKUP_SCRIPT_PATH >> $BACKUP_LOCATION/backup.log 2>&1"
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "$BACKUP_SCRIPT_PATH"; then
        echo "⚠️  Cron job already exists, skipping..."
    else
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "✅ Automatic backup configured!"
        echo "   Backups will run daily at 04:00"
        echo "   Backup location: $BACKUP_LOCATION"
        echo "   Backup script: $BACKUP_SCRIPT_PATH"
        echo ""
        echo "   To manually run backup: $BACKUP_SCRIPT_PATH"
        echo "   To view cron jobs: crontab -l"
        echo "   To remove cron job: crontab -e (then delete the line)"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Start the server with: docker-compose up -d"
echo "View logs with: docker-compose logs -f icarus"
echo "Stop the server with: docker-compose down"
echo ""
