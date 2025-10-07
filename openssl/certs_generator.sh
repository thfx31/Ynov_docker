#!/bin/bash

# Vérifie si le script est exécuté avec sudo
if [ "$EUID" -ne 0 ]; then
  echo "Veuillez exécuter ce script avec sudo."
  exit 1
fi

# Vérifie si le répertoire /certs existe déjà
if [ ! -d "/certs" ]; then
  # Crée le répertoire /certs
  mkdir /certs
  echo "Le répertoire /certs a été créé."
else
  echo "Le répertoire /certs existe déjà."
fi

# Génère le certificat SSL
docker compose -f docker-compose.yml run --rm openssl || { echo "Échec de la génération du certificat SSL"; exit 1; }