#!/bin/bash
# set -x

# Définition du répertoire du script de manière robuste
SCRIPTDIR=$(dirname "$(readlink -f "$0")")

# Chargement des variables d'environnement (.env)
if [ -f "${SCRIPTDIR}/.env" ]; then
    source "${SCRIPTDIR}/.env"
else
    echo "Erreur : Fichier ${SCRIPTDIR}/.env introuvable."
    exit 1
fi

hname=$(hostname -s)

# Vérification de la présence de WEBHOOK_URL
if [ -z "$WEBHOOK_URL" ]; then
    echo "Erreur : WEBHOOK_URL n'est pas défini dans le fichier .env"
    exit 1
fi

# Mise à jour silencieuse de la liste des paquets
sudo apt update > /dev/null 2>&1

# Check d'une nouvelle release
CHECK_RELEASE=$(LANG=en /usr/lib/ubuntu-release-upgrader/check-new-release 2>&1 | grep "New release" | awk "BEGIN {FS=\"'\"} {print \$2}")

# Check fin de support
if ( LANG=en /usr/lib/ubuntu-release-upgrader/check-new-release 2>&1 | grep "not supported anymore" &> /dev/null );
then CHECK_EOS=1;
else CHECK_EOS=0; fi

if ( ! [[ -f /root/last-dist-notified ]] ); then
    grep VERSION_ID /etc/os-release | awk -F '"' '{print $2}' > /root/last-dist-notified;
fi

if [[ -n "${CHECK_RELEASE}" ]] && ! grep -q "${CHECK_RELEASE}" /root/last-dist-notified ; then
    # Notification Discord
    title="Nouvelle Release détectée: ${CHECK_RELEASE}"
    if [[ ${CHECK_EOS} -eq 1 ]];
    then
        support="Plus de support la distribution actuelle => Mettre à jour rapidement."
        color="16189962"
    else
        support="Support toujours disponible => Mise à jour conseillée."
        color="1826317"
    fi
    payload=$(jq -n \
        --arg title "$title" \
        --arg host "$hname" \
        --arg support "$support" \
        --argjson clr "$color" \
        '{
            embeds: [{
                title: $title,
                color: $clr,
                fields: [
                    {
                        name: $host,
                        value: $support,
                        inline: false
                    }
                ]
            }]
        }')
    curl -s -H "Content-Type: application/json" \
     -X POST \
     -d "$payload" \
     "$WEBHOOK_URL" > /dev/null
    # Enregistrer la nlle release
    echo ${CHECK_RELEASE} > /root/last-dist-notified
fi
# set +x
