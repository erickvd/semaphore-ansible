#!/bin/bash

# Définition du répertoire du script de manière robuste
SCRIPTDIR=$(dirname "$(readlink -f "$0")")

# Chargement des variables d'environnement (.env)
if [ -f "${SCRIPTDIR}/.env" ]; then
    source "${SCRIPTDIR}/.env"
else
    echo "Erreur : Fichier ${SCRIPTDIR}/.env introuvable."
    exit 1
fi

# Vérification de la présence de WEBHOOK_URL
if [ -z "$WEBHOOK_URL" ]; then
    echo "Erreur : WEBHOOK_URL n'est pas défini dans le fichier .env"
    exit 1
fi

# Mise à jour silencieuse de la liste des paquets
sudo apt update > /dev/null 2>&1

# Récupération des mises à jour (on filtre pour n'avoir que les lignes de paquets)
# raw_updates=$(apt list --upgradable 2>/dev/null | grep "/")
raw_updates=$(apt upgrade --simulate 2>/dev/null | grep -e '^Inst')
count=$(echo "$raw_updates" | grep -c "^" | xargs) # xargs retire les espaces superflus

# Détermination de la couleur et du statut
# Vert : 3066993 | Orange/Jaune : 16753920 | Rouge : 15158332
if [ "$count" -eq 0 ]; then
    color=3066993
    status_msg="✅ Système à jour sur $(hostname)"
    updates_list="Aucun paquet à mettre à jour."
else
    [ "$count" -lt 15 ] && color=16753920 || color=15158332
    status_msg="📦 $count mise(s) à jour Ubuntu disponibles sur $(hostname)"

    # Formatage de la liste avec printf pour simuler des colonnes
    # On limite à 30 paquets pour ne pas exploser la limite de caractères de Discord
    updates_list=$(apt upgrade --simulate 2>/dev/null | grep '^Inst' | head -n 30 | awk '{
        name=$2;
        old_ver=$3;
        new_ver=$4;
        gsub(/[\[\]()]/, "", old_ver);
        gsub(/[\[\]()]/, "", new_ver);
        printf "%-30s %s -> %s\n", name, old_ver, new_ver
    }')

    if [ "$count" -gt 30 ]; then
        updates_list+=$'\n... (liste tronquée pour des raisons de lisibilité)'
    fi
fi
formatted_list=$(printf '```text\n%s\n```' "$updates_list")

# Construction du JSON avec jq
# On utilise --argjson pour la couleur afin qu'elle soit traitée comme un nombre
payload=$(jq -n \
    --arg title "$status_msg" \
    --arg list "$formatted_list" \
    --argjson clr "$color" \
    '{
        embeds: [{
            title: $title,
            color: $clr,
            fields: [
                {
                    name: "Détails des paquets",
                    value: ($list | .[0:1024]),
                    inline: false
                }
            ]
        }]
    }')

# Envoi au Webhook Discord
curl -s -H "Content-Type: application/json" \
     -X POST \
     -d "$payload" \
     "$WEBHOOK_URL" > /dev/null

exit 0
