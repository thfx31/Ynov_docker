#!/bin/bash
set -e

#############################################
# Configuration
#############################################

USERNAME="thfx31"                     # Docker Hub username
REPO="thfx31/ynov"                    # Private Docker Hub repository
DOCKERFILE="Dockerfile"               # Multi-stage Dockerfile
TARGETS=("forge" "jenkins" "gitea" "nginx-proxy" "nginx-letsencrypt" "postgres")
DOCKER_PASSWORD=""                    # Optional: leave empty for interactive input


#############################################
# Dependency check and auto-install (jq)
#############################################

check_jq() {
  if command -v jq >/dev/null 2>&1; then
    return 0
  fi

  echo "'jq' is not installed. Attempting to install it automatically..."

  if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
      ubuntu|debian)
        sudo apt update -y && sudo apt install -y jq && return 0
        ;;
      fedora)
        sudo dnf install -y jq && return 0
        ;;
      rhel|centos|rocky|almalinux)
        sudo yum install -y jq && return 0
        ;;
      *)
        echo "Unsupported Linux distribution. Please install 'jq' manually."
        exit 1
        ;;
    esac
  else
    echo "Cannot detect Linux distribution. Please install 'jq' manually."
    exit 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "Failed to install 'jq'. Please install it manually and rerun the script."
    exit 1
  fi
}


#############################################
# Docker Hub Authentication
#############################################

authenticate() {
  if [ -z "$DOCKER_PASSWORD" ]; then
    read -s -p "Enter your Docker Hub password or access token for ${USERNAME}: " DOCKER_PASSWORD
    echo
  fi

  echo "Authenticating with Docker Hub..."
  TOKEN=$(curl -s -H "Content-Type: application/json" \
    -X POST -d "{\"username\": \"${USERNAME}\", \"password\": \"${DOCKER_PASSWORD}\"}" \
    https://hub.docker.com/v2/users/login/ | jq -r .token)

  if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
    echo "Authentication failed. Please check your credentials or token."
    exit 1
  fi

  echo "Authentication successful."
}


#############################################
# Determine next tag version
#############################################

get_next_tag() {
  local target="$1"

  local latest_tag
  latest_tag=$(curl -s -H "Authorization: JWT ${TOKEN}" \
    "https://hub.docker.com/v2/repositories/${REPO}/tags/?page_size=100" \
    | jq -r ".results[].name" | grep "${target}-v" | sort -V | tail -n1)

  if [[ -z "$latest_tag" ]]; then
    echo "${target}-v1"
  else
    local current_version="${latest_tag##*-v}"
    local next_version=$((current_version + 1))
    echo "${target}-v${next_version}"
  fi
}


#############################################
# Build and Push
#############################################

build_and_push() {
  local target="$1"
  local nocache_flag=""

  echo "=============================="
  echo "Building image: ${target}"

  # Only disable cache for Forge
  if [[ "$target" == "forge" ]]; then
    nocache_flag="--no-cache"
    echo "Cache disabled for target: $target"
  fi

  TAG=$(get_next_tag "$target")
  IMAGE="${REPO}:${TAG}"

  echo "New tag: ${TAG}"
  echo "Building image..."
  docker build $nocache_flag -t "$IMAGE" --target "$target" -f "$DOCKERFILE" .

  echo "Pushing image to Docker Hub..."
  docker push "$IMAGE"

  echo "Image pushed successfully: $IMAGE"
}


#############################################
# List available images
#############################################

list_images() {
  echo
  echo "=============================="
  echo "Available images in Docker Hub repository (${REPO}):"
  echo

  curl -s -H "Authorization: JWT ${TOKEN}" \
    "https://hub.docker.com/v2/repositories/${REPO}/tags/?page_size=100" \
    | jq -r '.results[] | [.name, .last_updated] | @tsv' \
    | sort -V \
    | awk -F'\t' '{printf "  %-25s (%s)\n", $1, $2}' \
    || echo "Unable to fetch image list."

  echo
}


#############################################
# CLI Options Handling
#############################################

show_help() {
  echo "Usage: $0 [OPTION]"
  echo
  echo "Options:"
  echo "  --list               List all available images in Docker Hub"
  echo "  --build <name>       Build and push a specific image (e.g., forge)"
  echo "  --all                Build and push all images (default)"
  echo "  --help               Show this help message"
  echo
  echo "Examples:"
  echo "  $0 --list"
  echo "  $0 --build jenkins"
  echo "  $0 --all"
  exit 0
}


#############################################
# Main logic
#############################################

main() {
  check_jq  # verify jq availability (and install if needed)

  local mode="all"
  local specific_target=""

  case "$1" in
    --list)
      mode="list"
      ;;
    --build)
      mode="build_one"
      specific_target="$2"
      if [ -z "$specific_target" ]; then
        echo "Error: Please specify a target name after --build"
        exit 1
      fi
      ;;
    --all|"")
      mode="all"
      ;;
    --help|-h)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      ;;
  esac

  authenticate

  case "$mode" in
    list)
      list_images
      ;;
    build_one)
      build_and_push "$specific_target"
      ;;
    all)
      for target in "${TARGETS[@]}"; do
        build_and_push "$target"
      done
      ;;
  esac

  if [[ "$mode" != "list" ]]; then
    list_images
    echo "Build and push completed successfully."
  fi
}


#############################################
# Execution
#############################################

main "$@"
