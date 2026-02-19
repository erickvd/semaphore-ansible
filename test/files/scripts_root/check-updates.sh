#!/bin/bash
SCRIPTDIR=$(dirname $0)

if [ ! -f ${SCRIPTDIR}/.env ]; then
    echo "Pas de fichier .env."
    echo "Impossible de charger les variables d'environnement."
    echo ""
    exit 1
else
    source ${SCRIPTDIR}/.env
fi

# Mise à jour de la liste des paquets (nécessite sudo)
sudo apt update > /dev/null 2>&1

# Vérification des mises à jour disponibles
updates=$(apt list --upgradable 2>/dev/null | grep -v "Listing...")

if [ -n "$updates" ]; then
    # Formatage du message pour Discord
    message="📦 **Mises à jour Ubuntu disponibles**\n\`\`\`$updates\`\`\`"

    # Envoi via curl
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" $WEBHOOK_URL
fi