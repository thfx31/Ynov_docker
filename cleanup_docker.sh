#!/bin/bash
set -e

############################################################
# Docker Environment Cleanup Script
# ---------------------------------
# This script removes all Docker images, containers,
# volumes, networks, and build caches.
# Use it before re-testing or rebuilding your pipeline
# from a clean state.
############################################################

echo "=========================================="
echo " Docker Cleanup Utility"
echo "=========================================="
echo

read -p "⚠️  WARNING: This will remove ALL Docker data (containers, images, volumes, cache). Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
fi

echo
echo "Stopping all running containers..."
docker stop $(docker ps -aq) 2>/dev/null || true

echo "Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "Removing all images..."
docker rmi -f $(docker images -aq) 2>/dev/null || true

echo "Removing all volumes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true

echo "Removing all user-created networks..."
docker network rm $(docker network ls -q | grep -v "bridge\|host\|none") 2>/dev/null || true

echo "Pruning builder cache..."
docker builder prune -af

echo "Running full system prune..."
docker system prune -af --volumes

echo
echo "✅ Docker environment successfully cleaned."
echo
docker system df
