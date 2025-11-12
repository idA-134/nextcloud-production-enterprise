#!/bin/bash
#
# Nextcloud Health Check Script
# Überprüft den Status aller Services
#

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

check_service() {
    local service=$1
    local url=$2
    local name=$3
    
    if curl -f -s -o /dev/null "$url" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $name läuft"
        return 0
    else
        echo -e "${RED}✗${NC} $name ist nicht erreichbar"
        return 1
    fi
}

check_container() {
    local container=$1
    local name=$2
    
    if docker ps --filter "name=$container" --filter "status=running" | grep -q "$container"; then
        echo -e "${GREEN}✓${NC} Container $name läuft"
        return 0
    else
        echo -e "${RED}✗${NC} Container $name läuft nicht"
        return 1
    fi
}

echo -e "${BLUE}=== Nextcloud Production Health Check ===${NC}"
echo ""

# Container Status
echo -e "${BLUE}Container Status:${NC}"
check_container "nextcloud_prod_db" "PostgreSQL"
check_container "nextcloud_prod_redis" "Redis"
check_container "nextcloud_prod_app" "Nextcloud"
check_container "nextcloud_prod_nginx" "Nginx"
check_container "nextcloud_prod_onlyoffice" "OnlyOffice"
check_container "nextcloud_prod_coturn" "TURN Server"
check_container "nextcloud_prod_cron" "Cron"

echo ""

# Service Erreichbarkeit
echo -e "${BLUE}Service Erreichbarkeit:${NC}"
check_service "http://localhost/status.php" "http://localhost/status.php" "Nextcloud Web"
check_service "http://localhost:8080/healthcheck" "http://localhost:8080/healthcheck" "OnlyOffice" || echo -e "${YELLOW}  (OnlyOffice optional)${NC}"

echo ""

# Disk Space
echo -e "${BLUE}Speicherplatz:${NC}"
df -h | grep -E "Filesystem|nextcloud" || df -h | head -2

echo ""

# Docker Volumes
echo -e "${BLUE}Docker Volumes:${NC}"
docker volume ls | grep nextcloud_prod || echo "Keine Volumes gefunden"

echo ""
echo -e "${GREEN}=== Health Check abgeschlossen ===${NC}"
