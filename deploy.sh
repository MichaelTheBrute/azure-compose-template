#!/bin/bash

# Script to deploy a multi-container application to Azure Container Instances (ACI)

# Variables
RESOURCE_GROUP="myACITestResourceGroup2"
LOCATION="westus"
ACR_NAME="myacitestcontainerregistry2"
FRONTEND_IMAGE="docker-compose-project-frontend:latest"
BACKEND_IMAGE="docker-compose-project-backend:latest"
ACR_LOGIN_SERVER="$ACR_NAME.azurecr.io"
ENVIRONMENT_NAME="myACITestEnvironment2"  # Parameterized environment name

# Step 1: Log in to Azure
echo "Logging in to Azure..."
az login

# Step 2: Create a resource group
echo "Creating resource group: $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# Step 3: Create an Azure Container Registry (ACR)
echo "Creating Azure Container Registry: $ACR_NAME..."
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic

# Step 4: Log in to ACR
echo "Logging in to ACR..."
az acr login --name $ACR_NAME

# Step 5: Tag and push Docker images to ACR
echo "Tagging and pushing Docker images to ACR..."
docker tag $FRONTEND_IMAGE $ACR_LOGIN_SERVER/frontend:latest
docker tag $BACKEND_IMAGE $ACR_LOGIN_SERVER/backend:latest

docker push $ACR_LOGIN_SERVER/frontend:latest
docker push $ACR_LOGIN_SERVER/backend:latest

# Step 6: Create Azure Container Apps Environment
echo "Creating Azure Container Apps Environment: $ENVIRONMENT_NAME..."
az containerapp env create \
  --name $ENVIRONMENT_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION

# Step 7: Deploy to Azure Container Instances (ACI)
echo "Deploying to Azure Container Apps using environment: $ENVIRONMENT_NAME..."
az containerapp compose create \
  --resource-group $RESOURCE_GROUP \
  --environment $ENVIRONMENT_NAME \
  --compose-file-path docker-compose.yml

# Step 8: Enable Dapr for frontend and backend container apps
echo "Enabling Dapr for frontend and backend container apps..."
az containerapp dapr enable \
  --name frontend \
  --resource-group $RESOURCE_GROUP \
  --dapr-app-id frontend \
  --dapr-app-port 8080

az containerapp dapr enable \
  --name backend \
  --resource-group $RESOURCE_GROUP \
  --dapr-app-id backend \
  --dapr-app-port 5000

echo "Dapr is now enabled for service-to-service communication for both frontend and backend."

# Step 9: Output success message
echo "Deployment complete! Check Azure Portal for your application."