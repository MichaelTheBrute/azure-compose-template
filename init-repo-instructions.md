# Repository Initialization Scripts

These scripts automate the setup of Azure service principals and GitHub secrets for new repositories based on this template.

## Prerequisites

1. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **GitHub CLI** - [Install GitHub CLI](https://cli.github.com/)
3. **jq** (Linux/Mac only) - `sudo apt install jq` or `brew install jq`

## Before Running

1. Login to Azure CLI: `az login`
2. Login to GitHub CLI: `gh auth login`
3. Ensure you have admin access to the target GitHub repository

## Usage

### Linux/Mac
```bash
chmod +x scripts/init-repo-azure.sh
./scripts/init-repo-azure.sh <repo-owner> <repo-name> [subscription-id] [resource-group]