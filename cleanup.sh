#!/bin/bash

# Script to clean up Azure resources created by the deployment

# Variables
RESOURCE_GROUP="myACITestResourceGroup"
ACR_NAME="myacitestcontainerregistry"

# Step 1: Log in to Azure
echo "Logging in to Azure..."
az login

# Step 2: Delete the resource group
echo "Deleting resource group: $RESOURCE_GROUP..."
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Step 3: Delete the Azure Container Registry (optional, if not part of the resource group)
echo "Deleting Azure Container Registry: $ACR_NAME..."
az acr delete --name $ACR_NAME --resource-group $RESOURCE_GROUP --yes

# Step 4: Output success message
echo "Cleanup initiated. Resources are being deleted. Check the Azure Portal to confirm."