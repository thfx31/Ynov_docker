#!/bin/bash

# Vérifie si le script est exécuté avec sudo
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script avec sudo."
  exit 1
fi

# Génère le certificat SSL
echo "Déplacement dans le répertoire openssl..."
cd /home/admintf/ynov_docker/openssl || { echo "Échec du déplacement dans le répertoire openssl"; exit 1; }

echo "Génération du certificat SSL..."
docker compose -f docker-compose.yml run --rm openssl || { echo "Échec de la génération du certificat SSL"; exit 1; }

# Déploie GitLab
echo "Déplacement dans le répertoire Gitlab..."
cd /home/admintf/ynov_docker/gitlab || { echo "Échec du déplacement dans le répertoire gitlab"; exit 1; }

echo "Déploiement de GitLab..."
docker compose -f docker-compose.yml up -d || { echo "Échec du déploiement de GitLab"; exit 1; }

echo "Script exécuté avec succès."
