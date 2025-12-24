# Icarus Dedicated Server - Docker

Makkelijke setup voor een Icarus dedicated server met Docker.

## Vereisten

- Docker
- docker-compose
- Open poorten: 17777/udp en 27015/udp

## Snelle Start
```bash
# Clone de repo
git clone https://github.com/jouw-username/icarus-server.git
cd icarus-server

# Run setup script
./setup.sh

# Start de server
docker-compose up -d

# Bekijk logs
docker-compose logs -f icarus
```

## Handmatige Setup

1. Kopieer `docker-compose.yml.example` naar `docker-compose.yml`
2. Pas de volgende variabelen aan:
   - `YOUR_SERVER_NAME` - Naam van je server
   - `YOUR_JOIN_PASSWORD` - Wachtwoord om te joinen
   - `YOUR_ADMIN_PASSWORD` - Admin wachtwoord

3. Maak config directory:
```bash
mkdir -p ./serverfiles/Icarus/Saved/Config/WindowsServer
```

4. Kopieer `config-templates/ServerSettings.ini.example` naar `./serverfiles/Icarus/Saved/Config/WindowsServer/ServerSettings.ini`
5. Pas de placeholders aan in ServerSettings.ini

6. Start de server:
```bash
docker-compose up -d
```

## Server Beheer
```bash
# Start server
docker-compose up -d

# Stop server
docker-compose down

# Herstart server
docker-compose restart icarus

# Bekijk logs
docker-compose logs -f icarus

# Update server
docker-compose down
docker-compose pull
docker-compose up -d
```

## Configuratie

### Poorten
- **17777/udp** - Game poort
- **27015/udp** - Query poort (server browser)

### ServerSettings.ini opties

- `SessionName` - Server naam in browser
- `JoinPassword` - Wachtwoord om te joinen
- `AdminPassword` - Admin wachtwoord voor in-game commands
- `MaxPlayers` - Maximum aantal spelers (1-8)
- `ShutdownIfNotJoinedFor` - Seconden tot pauze als niemand joint (-1 = nooit)
- `ShutdownIfEmptyFor` - Seconden tot pauze als server leeg is (-1 = nooit)

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

## World/Save Data Verwijderen
```bash
docker-compose stop icarus
rm -rf ./serverfiles/Icarus/Saved/PlayerData/*
rm -rf ./serverfiles/Icarus/Saved/ProspectData/*
docker-compose start icarus
```

## Troubleshooting

**Server vraagt niet om wachtwoord**
- Check of ServerSettings.ini correct is aangemaakt
- Herstart de container: `docker-compose restart icarus`

**Kan niet verbinden**
- Check firewall regels
- Verify poorten zijn open: `sudo ss -tulpn | grep -E '17777|27015'`

**Server naam is een random nummer**
- Check of `-SteamServerName` parameter in GAME_PARAMS staat
- Herstart de container

## Credits

- Docker image: [ich777/steamcmd:icarus](https://hub.docker.com/r/ich777/steamcmd)
- Game: [Icarus by RocketWerkz](https://store.steampowered.com/app/1149460/ICARUS/)
