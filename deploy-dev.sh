#!/bin/bash
set -e

# Get the absolute path of the script's directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define relative project paths
OPENSSL_DIR="$BASE_DIR/openssl"
GITLAB_DIR="$BASE_DIR/gitlab"
CERTS_DIR="/certs"
SCAN_DIR="$BASE_DIR/scan"

# Check sudo
if [ "$EUID" -ne 0 ]; then
  error_exit "Veuillez exécuter ce script avec sudo."
fi

# Create certificate directory
if [ ! -d "$CERTS_DIR" ]; then
  mkdir "$CERTS_DIR"
  echo "Le répertoire $CERTS_DIR a été créé."
 else
  echo "Le répertoire $CERTS_DIR existe déjà."
fi

# Install Trivy
if ! command -v trivy &> /dev/null; then
  echo "Installation de Trivy..."
  apt update -y && apt install -y wget apt-transport-https gnupg lsb-release
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" > /etc/apt/sources.list.d/trivy.list
  apt update -y && apt install -y trivy
  echo "Trivy installé avec succès."
else
  echo "Trivy est déjà installé."
fi

# Generate SSL certificate
echo "Déplacement dans le répertoire OpenSSL..."
cd "$OPENSSL_DIR" || error_exit "Impossible d’accéder à $OPENSSL_DIR"

echo "Génération du certificat SSL..."
docker compose -f docker-compose.yml run --rm openssl || error_exit "Échec de la génération du certificat SSL"

# Install Gitlab
echo "Déplacement dans le répertoire GitLab..."
cd "$GITLAB_DIR" || error_exit "Impossible d’accéder à $GITLAB_DIR"

echo "Installation de GitLab..."
docker compose -f docker-compose.yml up -d || error_exit "Échec de l'installation de GitLab"

echo "Installation de GitLab terminé avec succès."

# Scan all local docker images
echo "Scanning all local Docker images..."
IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep -v "<none>" || true)

if [ -z "$IMAGES" ]; then
  echo "No local Docker images found."
else
  echo "Detected images:"
  echo "$IMAGES"
  echo

  LOG_FILE="$SCAN_DIR/trivy-scan-$(date +%F_%H-%M-%S).log"
  echo "Results will be saved in: $LOG_FILE"
  echo "--------------------------------------" > "$LOG_FILE"

  for IMAGE in $IMAGES; do
    echo "Running Trivy scan on image: $IMAGE"
    {
      echo "======================================"
      echo "Image: $IMAGE"
      echo "--------------------------------------"
      trivy image --scanners vuln --severity HIGH,CRITICAL --no-progress --quiet "$IMAGE" || \
        echo "Trivy scan failed for $IMAGE"
      echo
    } >> "$LOG_FILE" 2>&1
  done

  echo
  echo "Trivy scans completed for all local images."
  echo "Full report saved at: $LOG_FILE"
fi