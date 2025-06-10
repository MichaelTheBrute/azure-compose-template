#!/bin/bash

# Variables
RESOURCE_GROUP="myACITestResourceGroup3"
LOCATION="westus"
ACR_NAME="myacitestcontainerregistry3"
ACR_LOGIN_SERVER="$ACR_NAME.azurecr.io"
ENVIRONMENT_NAME="myACITestEnvironment3"
export AZURE_ENV_NAME="$ENVIRONMENT_NAME"

# Log in to Azure
echo "Logging in to Azure..."
az login

# Create resource group
echo "Creating resource group: $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create ACR
echo "Creating Azure Container Registry: $ACR_NAME..."
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Enable admin access to ACR (alternative to managed identity)
echo "Enabling admin access to ACR..."
az acr update --name $ACR_NAME --resource-group $RESOURCE_GROUP --admin-enabled true

# Get ACR credentials
echo "Getting ACR credentials..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username --output tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)

# Create Container Apps Environment
echo "Creating Azure Container Apps Environment: $ENVIRONMENT_NAME..."
az containerapp env create \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# # Create managed identity for the environment
# echo "Adding managed identity to Container Apps Environment..."
# az containerapp env update \
#   --name $ENVIRONMENT_NAME \
#   --resource-group $RESOURCE_GROUP \
#   --enable-managed-identity

# Deploy using docker-compose with ACR credentials and min scale set to 1
echo "Deploying to Azure Container Apps..."
az containerapp compose create \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --compose-file-path docker-compose.yml \
  --registry-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD

    # Configure frontend
  az containerapp update --name frontend --resource-group $RESOURCE_GROUP \
    --min-replicas 1 --max-replicas 10
  
  # Configure backend
  az containerapp ingress update --name backend --resource-group $RESOURCE_GROUP \
    --type internal --target-port 5000
  
  # Configure redis
  az containerapp ingress update --name redis --resource-group $RESOURCE_GROUP \
    --type internal --target-port 6379 --transport tcp

echo "Deployment complete!"