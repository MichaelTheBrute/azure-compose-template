#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to prompt for app name and update docker-compose.yml
prompt_and_set_app_name() {
    print_info "App name configuration required..."
    echo
    print_info "The app name will be used for:"
    echo "  • Azure resource naming (Resource Groups, Container Registry, etc.)"
    echo "  • Database seeding and application display"
    echo "  • Service principal naming"
    echo
    print_info "App name requirements:"
    echo "  • 2-50 characters long"
    echo "  • Start and end with alphanumeric characters"
    echo "  • Can contain hyphens (-) in the middle"
    echo "  • Cannot contain spaces or special characters"
    echo "  • Will be converted to lowercase for Azure resources"
    echo
    print_info "Examples: my-piano-studio, webapp-demo, musicapp123"
    echo
    
    while true; do
        read -p "Enter your app name: " APP_NAME
        
        # Remove quotes and trim whitespace
        APP_NAME=$(echo "$APP_NAME" | sed 's/^["'"'"']//;s/["'"'"']$//' | xargs)
        
        # Check if empty
        if [[ -z "$APP_NAME" ]]; then
            print_error "App name cannot be empty. Please try again."
            continue
        fi
        
        # Validate app name format
        if [[ ! "$APP_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]] || [[ ${#APP_NAME} -lt 2 ]] || [[ ${#APP_NAME} -gt 50 ]]; then
            print_error "Invalid app name format: '$APP_NAME'"
            print_error "Please ensure it meets the requirements above."
            continue
        fi
        
        # Confirm with user
        echo
        print_info "You entered: '$APP_NAME'"
        read -p "Is this correct? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            break
        else
            echo "Let's try again..."
        fi
    done
    
    print_success "App name validated: '$APP_NAME'"
    
    # Update docker-compose.yml with the app name
    print_info "Updating docker-compose.yml with app name..."
    
    # Check if metadata section exists
    if yq eval '.metadata' docker-compose.yml >/dev/null 2>&1; then
        # Update existing metadata section
        yq eval ".metadata.app_name = \"$APP_NAME\"" -i docker-compose.yml
    else
        # Add metadata section
        yq eval ".metadata.app_name = \"$APP_NAME\"" -i docker-compose.yml
    fi
    
    print_success "✓ docker-compose.yml updated with app_name: '$APP_NAME'"
    
    # Store app name for use in service principal naming
    export VALIDATED_APP_NAME="$APP_NAME"
}

# Function to select Azure subscription interactively
select_azure_subscription() {
    print_info "Getting available Azure subscriptions..."
    
    # Get all subscriptions in JSON format
    SUBSCRIPTIONS_JSON=$(az account list --query "[].{id:id, name:name, isDefault:isDefault}" -o json 2>/dev/null)
    
    if [[ -z "$SUBSCRIPTIONS_JSON" || "$SUBSCRIPTIONS_JSON" == "[]" ]]; then
        print_error "No Azure subscriptions found"
        print_error "Please ensure you're logged in with: az login"
        exit 1
    fi
    
    # Parse subscriptions into arrays
    mapfile -t SUB_IDS < <(echo "$SUBSCRIPTIONS_JSON" | jq -r '.[].id')
    mapfile -t SUB_NAMES < <(echo "$SUBSCRIPTIONS_JSON" | jq -r '.[].name')
    mapfile -t SUB_DEFAULTS < <(echo "$SUBSCRIPTIONS_JSON" | jq -r '.[].isDefault')
    
    # If only one subscription, use it automatically
    if [[ ${#SUB_IDS[@]} -eq 1 ]]; then
        SUBSCRIPTION_ID="${SUB_IDS[0]}"
        SUBSCRIPTION_NAME="${SUB_NAMES[0]}"
        print_info "Using only available subscription: $SUBSCRIPTION_NAME"
        return
    fi
    
    # Display subscription options
    echo
    print_info "Available Azure subscriptions:"
    echo
    
    for i in "${!SUB_IDS[@]}"; do
        local number=$((i + 1))
        local default_marker=""
        
        if [[ "${SUB_DEFAULTS[$i]}" == "true" ]]; then
            default_marker=" (current default)"
        fi
        
        printf "%2d) %s%s\n" "$number" "${SUB_NAMES[$i]}" "$default_marker"
        printf "     ID: %s\n" "${SUB_IDS[$i]}"
        echo
    done
    
    # Get user selection
    while true; do
        echo -n "Select subscription (1-${#SUB_IDS[@]}): "
        read -r selection
        
        # Validate selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le ${#SUB_IDS[@]} ]]; then
            local index=$((selection - 1))
            SUBSCRIPTION_ID="${SUB_IDS[$index]}"
            SUBSCRIPTION_NAME="${SUB_NAMES[$index]}"
            break
        else
            print_error "Invalid selection. Please enter a number between 1 and ${#SUB_IDS[@]}"
        fi
    done
    
    print_success "Selected subscription: $SUBSCRIPTION_NAME"
    print_info "Subscription ID: $SUBSCRIPTION_ID"
}

# Function to validate docker-compose.yml and app_name (UPDATED)
validate_docker_compose() {
    print_info "Validating docker-compose.yml configuration..."
    
    # Check if docker-compose.yml exists
    if [[ ! -f "docker-compose.yml" ]]; then
        print_error "docker-compose.yml not found in current directory"
        print_error "Make sure you're running this script from the repository root"
        exit 1
    fi
    
    print_success "✓ docker-compose.yml found"
    
    # Check if yq is available (needed to parse YAML)
    if ! command_exists yq; then
        print_error "yq is not installed. Please install it first:"
        echo "Ubuntu/Debian: sudo apt install yq"
        echo "macOS: brew install yq"
        echo "Or download from: https://github.com/mikefarah/yq/releases"
        exit 1
    fi
    
    # Extract app_name from metadata section
    APP_NAME=$(yq eval '.metadata.app_name // ""' docker-compose.yml 2>/dev/null || echo "")
    
    # Remove any quotes and trim whitespace
    APP_NAME=$(echo "$APP_NAME" | sed 's/^["'"'"']//;s/["'"'"']$//' | xargs)
    
    # Check if app_name is set and valid
    if [[ -z "$APP_NAME" || "$APP_NAME" == "null" ]]; then
        print_warning "⚠️  App name is not set in docker-compose.yml"
        prompt_and_set_app_name
    else
        # Validate existing app name format
        if [[ ! "$APP_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$ ]] || [[ ${#APP_NAME} -lt 2 ]] || [[ ${#APP_NAME} -gt 50 ]]; then
            print_error "❌ Invalid app name format in docker-compose.yml: '$APP_NAME'"
            echo
            print_error "The existing app name doesn't meet requirements."
            prompt_and_set_app_name
        else
            print_success "✓ App name validated: '$APP_NAME'"
            export VALIDATED_APP_NAME="$APP_NAME"
        fi
    fi
}

# Function to get repository info from git context
get_repo_info() {
    print_info "Getting repository information from git context..."
    
    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_error "Not inside a git repository"
        print_error "Please run this script from within your GitHub repository"
        exit 1
    fi
    
    # Get the GitHub remote URL
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
    
    if [[ -z "$REMOTE_URL" ]]; then
        print_error "No 'origin' remote found"
        print_error "Please add a GitHub remote with: git remote add origin <github-url>"
        exit 1
    fi
    
    # Parse GitHub repo owner and name from remote URL
    if [[ "$REMOTE_URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        REPO_OWNER="${BASH_REMATCH[1]}"
        REPO_NAME="${BASH_REMATCH[2]}"
    else
        print_error "Could not parse GitHub repository from remote URL: $REMOTE_URL"
        print_error "Make sure the origin remote points to a GitHub repository"
        exit 1
    fi
    
    print_success "Repository detected: $REPO_OWNER/$REPO_NAME"
    print_info "Remote URL: $REMOTE_URL"
}

# Function to validate repository access
validate_repo_access() {
    print_info "Validating repository access..."
    
    # Check if repository exists and we have access
    if ! gh repo view "$REPO_OWNER/$REPO_NAME" >/dev/null 2>&1; then
        print_error "Cannot access repository '$REPO_OWNER/$REPO_NAME'"
        print_error "Make sure:"
        print_error "1. The repository exists on GitHub"
        print_error "2. You have admin access to the repository"
        print_error "3. You are logged into GitHub CLI (gh auth login)"
        exit 1
    fi
    
    print_success "Repository access verified"
}

# Function to check if repository is already initialized
check_existing_setup() {
    print_info "Checking for existing setup..."
    
    # Check if GitHub secret already exists
    if gh secret list --repo "$REPO_OWNER/$REPO_NAME" 2>/dev/null | grep -q "AZURE_CREDENTIALS"; then
        print_warning "GitHub secret 'AZURE_CREDENTIALS' already exists"
        
        # Check if service principal exists
        SP_NAME="sp-${VALIDATED_APP_NAME}-github-actions"
        EXISTING_APP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv 2>/dev/null || echo "")
        
        if [[ -n "$EXISTING_APP_ID" && "$EXISTING_APP_ID" != "null" ]]; then
            print_warning "Service principal '$SP_NAME' already exists"
            echo
            print_info "🔄 This repository appears to be already initialized for Azure deployment."
            echo
            print_info "Current setup:"
            echo "  • Service Principal: $SP_NAME"
            echo "  • Application ID: $EXISTING_APP_ID"
            echo "  • GitHub Secret: AZURE_CREDENTIALS (exists)"
            echo
            print_info "Re-running this script will:"
            echo "  • Reset service principal credentials (new password)"
            echo "  • Update GitHub secret with new credentials"
            echo "  • Re-assign Azure roles (if needed)"
            echo
            print_warning "⚠️  This may cause active deployments to fail temporarily."
            echo
            read -p "Do you want to continue with re-initialization? (y/N): " -n 1 -r
            echo
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Re-initialization cancelled"
                echo
                print_success "✅ Repository is already configured for Azure deployment"
                echo
                print_info "To view current deployments: gh run list"
                print_info "To view service principal: az ad sp show --id $EXISTING_APP_ID"
                exit 0
            fi
            
            print_info "Proceeding with re-initialization..."
            export REINITIALIZING=true
        fi
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Git
    if ! command_exists git; then
        print_error "Git is not installed"
        exit 1
    fi
    
    # Check Azure CLI
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install it first:"
        echo "https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check GitHub CLI
    if ! command_exists gh; then
        print_error "GitHub CLI is not installed. Please install it first:"
        echo "https://cli.github.com/"
        exit 1
    fi
    
    # Check jq
    if ! command_exists jq; then
        print_error "jq is not installed. Please install it first:"
        echo "Ubuntu/Debian: sudo apt install jq"
        echo "macOS: brew install jq"
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show >/dev/null 2>&1; then
        print_error "Not logged into Azure CLI. Please run: az login"
        exit 1
    fi
    
    # Check if logged into GitHub
    if ! gh auth status >/dev/null 2>&1; then
        print_error "Not logged into GitHub CLI. Please run: gh auth login"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Function to get Azure subscription info
get_azure_info() {
    print_info "Getting Azure subscription information..."
    
    if [[ -n "$SUBSCRIPTION_ID" ]]; then
        # Subscription provided via command line
        if az account set --subscription "$SUBSCRIPTION_ID" 2>/dev/null; then
            print_info "Using specified subscription: $SUBSCRIPTION_ID"
        else
            print_error "Invalid subscription ID: $SUBSCRIPTION_ID"
            print_info "Available subscriptions:"
            az account list --query "[].{Name:name, ID:id}" -o table
            exit 1
        fi
    else
        # Interactive selection
        select_azure_subscription
        az account set --subscription "$SUBSCRIPTION_ID"
    fi
    
    TENANT_ID=$(az account show --query tenantId -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    
    print_info "Active subscription: $SUBSCRIPTION_NAME"
    print_info "Tenant ID: $TENANT_ID"
}

# Function to create service principal
create_service_principal() {
    if [[ "$REINITIALIZING" == "true" ]]; then
        print_info "Updating existing service principal..."
    else
        print_info "Creating service principal..."
    fi
    
    # Use the validated app name for service principal naming
    SP_NAME="sp-${VALIDATED_APP_NAME}-github-actions"
    
    # Check if service principal already exists
    EXISTING_APP_ID=$(az ad sp list --display-name "$SP_NAME" --query "[0].appId" -o tsv 2>/dev/null || echo "")
    
    if [[ -n "$EXISTING_APP_ID" && "$EXISTING_APP_ID" != "null" ]]; then
        if [[ "$REINITIALIZING" != "true" ]]; then
            print_warning "Service principal '$SP_NAME' already exists"
            echo
            read -p "Reset credentials for existing service principal? (y/N): " -n 1 -r
            echo
            
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Operation cancelled"
                exit 0
            fi
        fi
        
        APP_ID="$EXISTING_APP_ID"
        print_info "Using existing service principal: $APP_ID"
        
        # Reset credentials
        print_info "Resetting service principal credentials..."
        CREDENTIALS=$(az ad sp credential reset --id "$APP_ID" --query "{ appId: appId, password: password, tenant: tenant }" -o json)
        
        print_success "Service principal credentials reset successfully"
    else
        print_info "Creating new service principal: $SP_NAME"
        CREDENTIALS=$(az ad sp create-for-rbac \
            --name "$SP_NAME" \
            --role Contributor \
            --scopes "/subscriptions/$SUBSCRIPTION_ID" \
            --query "{ appId: appId, password: password, tenant: tenant }" \
            -o json)
        
        print_success "New service principal created successfully"
    fi
    
    APP_ID=$(echo "$CREDENTIALS" | jq -r '.appId')
    CLIENT_SECRET=$(echo "$CREDENTIALS" | jq -r '.password')
    
    print_success "Service principal ready: $APP_ID"
}

# Function to assign additional permissions
assign_permissions() {
    print_info "Assigning additional Azure permissions..."
    
    # Wait for service principal to propagate (shorter wait for re-initialization)
    if [[ "$REINITIALIZING" == "true" ]]; then
        print_info "Waiting for credential propagation..."
        sleep 10
    else
        print_info "Waiting for service principal propagation..."
        sleep 30
    fi
    
    # Define roles needed for Container Apps deployment
    ROLES=(
        "User Access Administrator"
        "Container Registry Contributor"
        "Azure Container Apps Contributor"
        "Log Analytics Contributor"
        "Key Vault Administrator"                   # Full Key Vault management
        "Key Vault Secrets Officer"                 # Create/manage secrets
        "PostgreSQL Flexible Server Contributor"    # Create/manage PostgreSQL servers
        "Network Contributor"                       # Manage firewall rules and networking
        "Storage Account Contributor"               # For any storage needs
    )
    
    for role in "${ROLES[@]}"; do
        print_info "Assigning role: $role"
        if az role assignment create \
            --assignee "$APP_ID" \
            --role "$role" \
            --scope "/subscriptions/$SUBSCRIPTION_ID" \
            >/dev/null 2>&1; then
            print_success "✓ Assigned role: $role"
        else
            print_warning "⚠ Could not assign role: $role (may already be assigned)"
        fi
    done

    # Additional role assignments for specific scenarios
    print_info "Assigning additional specialized roles..."
    
    # These roles might not exist in all Azure environments, so we'll handle them separately
    OPTIONAL_ROLES=(
        "Key Vault Crypto Officer"                  # For encryption key management
        "Monitoring Contributor"                    # For Application Insights/monitoring
        "DNS Zone Contributor"                      # If custom domains are used
    )
    
    for role in "${OPTIONAL_ROLES[@]}"; do
        print_info "Attempting to assign optional role: $role"
        if az role assignment create \
            --assignee "$APP_ID" \
            --role "$role" \
            --scope "/subscriptions/$SUBSCRIPTION_ID" \
            >/dev/null 2>&1; then
            print_success "✓ Assigned optional role: $role"
        else
            print_warning "⚠ Optional role not available or already assigned: $role"
        fi
    done
}

# Function to create GitHub secret
create_github_secret() {
    if [[ "$REINITIALIZING" == "true" ]]; then
        print_info "Updating GitHub repository secret..."
    else
        print_info "Creating GitHub repository secret..."
    fi
    
    # Create the Azure credentials JSON
    AZURE_CREDENTIALS=$(jq -n \
        --arg clientId "$APP_ID" \
        --arg clientSecret "$CLIENT_SECRET" \
        --arg subscriptionId "$SUBSCRIPTION_ID" \
        --arg tenantId "$TENANT_ID" \
        '{
            clientId: $clientId,
            clientSecret: $clientSecret,
            subscriptionId: $subscriptionId,
            tenantId: $tenantId
        }')
    
    # Create the secret
    echo "$AZURE_CREDENTIALS" | gh secret set AZURE_CREDENTIALS --repo "$REPO_OWNER/$REPO_NAME"
    
    if [[ "$REINITIALIZING" == "true" ]]; then
        print_success "GitHub secret 'AZURE_CREDENTIALS' updated successfully"
    else
        print_success "GitHub secret 'AZURE_CREDENTIALS' created successfully"
    fi
}

# Function to verify setup
verify_setup() {
    print_info "Verifying setup..."
    
    # Test Azure authentication
    if az account show --query "id" -o tsv >/dev/null 2>&1; then
        print_success "✓ Azure CLI authentication working"
    else
        print_error "✗ Azure CLI authentication failed"
    fi
    
    # Test GitHub secret
    if gh secret list --repo "$REPO_OWNER/$REPO_NAME" | grep -q "AZURE_CREDENTIALS"; then
        print_success "✓ GitHub secret verified"
    else
        print_error "✗ GitHub secret not found"
    fi
    
    # Test service principal
    if az ad sp show --id "$APP_ID" >/dev/null 2>&1; then
        print_success "✓ Service principal accessible"
    else
        print_error "✗ Service principal not accessible"
    fi
    
    # Test role assignments
    ROLE_COUNT=$(az role assignment list --assignee "$APP_ID" --query "length(@)" -o tsv 2>/dev/null || echo "0")
    if [[ "$ROLE_COUNT" -gt 0 ]]; then
        print_success "✓ Role assignments verified ($ROLE_COUNT roles)"
    else
        print_warning "⚠ No role assignments found"
    fi
    
    print_success "Setup verification completed"
}

# Function to display summary
display_summary() {
    echo
    if [[ "$REINITIALIZING" == "true" ]]; then
        print_info "=== RE-INITIALIZATION SUMMARY ==="
        print_success "🔄 Repository re-initialized successfully!"
    else
        print_info "=== SETUP SUMMARY ==="
        print_success "🎉 Repository is now ready for Azure deployments!"
    fi
    
    echo "Repository: $REPO_OWNER/$REPO_NAME"
    echo "App Name: $VALIDATED_APP_NAME"
    echo "Service Principal: $SP_NAME"
    echo "Application ID: $APP_ID"
    echo "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
    echo "Tenant ID: $TENANT_ID"
    echo
    
    print_info "Next steps:"
    echo "1. Commit and push your changes to trigger deployment"
    echo "2. Monitor the deployment in GitHub Actions"
    echo "3. Your app will be deployed with name: $VALIDATED_APP_NAME"
    echo
    print_info "Useful commands:"
    echo "- View workflow runs: gh run list"
    echo "- Watch latest run: gh run watch"
    echo "- View service principal: az ad sp show --id $APP_ID"
    echo "- View role assignments: az role assignment list --assignee $APP_ID --output table"
    
    if [[ "$REINITIALIZING" == "true" ]]; then
        echo
        print_info "Note: New credentials are now active. Previous deployments using old credentials will fail."
    fi
}

# Function to show usage (UPDATED)
show_usage() {
    echo "Usage: $0 [subscription-id]"
    echo
    echo "This script must be run from within a GitHub repository directory."
    echo "If docker-compose.yml doesn't have app_name set, you'll be prompted to enter one."
    echo
    echo "Arguments:"
    echo "  subscription-id    Optional Azure subscription ID"
    echo "                     If not provided, you'll be prompted to select from available subscriptions"
    echo
    echo "Examples:"
    echo "  $0                                          # Interactive subscription selection and app name prompting"
    echo "  $0 12345678-1234-1234-1234-123456789abc    # Use specific subscription"
    echo
    echo "Prerequisites:"
    echo "- Run from within a GitHub repository directory"
    echo "- docker-compose.yml file (app_name will be prompted if missing)"
    echo "- Azure CLI installed and logged in (az login)"
    echo "- GitHub CLI installed and logged in (gh auth login)"
    echo "- yq tool installed for YAML processing"
    echo "- Admin access to the GitHub repository"
    echo
    echo "Interactive Features:"
    echo "- App name prompting with validation if not set in docker-compose.yml"
    echo "- Subscription selection menu if multiple subscriptions available"
    echo "- Re-initialization detection with confirmation prompts"
    echo "- Comprehensive validation and error handling"
    echo
    echo "Re-running:"
    echo "- Safe to run multiple times"
    echo "- Will detect existing setup and ask for confirmation"
    echo "- Can reset credentials if needed"
}

# Main function
main() {
    echo
    print_info "🚀 Azure Container Apps Repository Initialization Script"
    echo
    
    # Parse arguments
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    SUBSCRIPTION_ID="$1"
    
    # Run setup steps
    check_prerequisites
    validate_docker_compose  # This now includes app name prompting if needed
    get_repo_info
    validate_repo_access
    check_existing_setup
    get_azure_info  # This includes subscription selection
    create_service_principal
    assign_permissions
    create_github_secret
    verify_setup
    display_summary
}

# Run main function with all arguments
main "$@"