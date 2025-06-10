#!/bin/bash
# filepath: /home/michael/github/dapr-parent/dapr-azure-compose-demo/push-azure-containers.sh

set -e

# Parse command line arguments
FORCE=false
for arg in "$@"; do
  case $arg in
    --force)
      FORCE=true
      shift
      ;;
    --help)
      echo "Usage: $0 [--force]"
      echo "  --force    Force build and push even if no changes detected"
      exit 0
      ;;
  esac
done

RESOURCE_GROUP="myACITestResourceGroup2"
LOCATION="westus"
ACR_NAME="myacitestcontainerregistry2"
FRONTEND_IMAGE="docker-compose-project-frontend:latest"
BACKEND_IMAGE="docker-compose-project-backend:latest"
ACR_LOGIN_SERVER="$ACR_NAME.azurecr.io"
ENVIRONMENT_NAME="myACITestEnvironment2"  # Parameterized environment name

# Check if logged in to Azure CLI
if ! az account show > /dev/null 2>&1; then
  echo "You are not logged in to Azure CLI. Logging in..."
  az login
fi

# Config
SERVICES=("frontend" "backend")

for SERVICE in "${SERVICES[@]}"; do
  DIR="./$SERVICE"
  IMAGE="$ACR_LOGIN_SERVER/$SERVICE:latest"
  DOCKERFILE="$DIR/Dockerfile"

  # Find the latest modification time for Dockerfile and src/
  LAST_BUILD_FILE="$DIR/.last_build"
  LAST_MODIFIED=$(find "$DIR" -type f \( -name 'Dockerfile' -o -path "$DIR/src/*" -o -path "$DIR/templates/*" \) -printf '%T@\n' | sort -n | tail -1)

  # Read last build time
  LAST_BUILD=0
  if [ -f "$LAST_BUILD_FILE" ]; then
    LAST_BUILD=$(cat "$LAST_BUILD_FILE")
  fi

  az acr login --name $ACR_NAME

  # Check if we should force rebuild or compare timestamps
  if $FORCE || (( $(echo "$LAST_MODIFIED > $LAST_BUILD" | bc -l) )); then
    if $FORCE; then
      echo "Force flag enabled. Building and pushing $SERVICE..."
    else
      echo "Changes detected in $SERVICE. Building and pushing..."
    fi
    
    docker build -t "$IMAGE" "$DIR"
    docker push "$IMAGE"
    echo "$LAST_MODIFIED" > "$LAST_BUILD_FILE"
    TIMESTAMP=$(date +%s)
    az containerapp update \
      --name $SERVICE \
      --resource-group $RESOURCE_GROUP \
      --image $IMAGE \
      --set-env-vars DEPLOY_TIMESTAMP=$TIMESTAMP
  else
    echo "No changes detected in $SERVICE. Skipping build and push."
  fi
done

echo "Process completed."