#!/bin/bash

# URL du Webhook Discord
WEBHOOK_URL="https://discordapp.com/api/webhooks/1473180055969599529/XiIf4ZMZLqf1OYpLeF2r_SsS0DGXvCEsWpzEBay08OZw7G4R7bl0humPHPHzPCWmnYgm"

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

