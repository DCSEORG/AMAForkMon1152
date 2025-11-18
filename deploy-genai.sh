#!/bin/bash

# Deployment script for Expense Management System GenAI Infrastructure
# This script deploys Azure OpenAI and Cognitive Services resources
# Follows Azure best practices with managed identities

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
RESOURCE_GROUP_NAME="rg-expensemgmt-dev"
LOCATION="uksouth"
ENVIRONMENT="dev"
RESOURCE_PREFIX="expensemgmt"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_info "Azure CLI found: $(az version --query \"azure-cli\" -o tsv)"
}

# Function to check if logged in to Azure
check_azure_login() {
    if ! az account show &> /dev/null; then
        print_error "Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_info "Using subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
}

# Function to create resource group if it doesn't exist
create_resource_group() {
    print_info "Checking resource group: $RESOURCE_GROUP_NAME"
    
    if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_info "Creating resource group: $RESOURCE_GROUP_NAME in $LOCATION"
        az group create \
            --name "$RESOURCE_GROUP_NAME" \
            --location "$LOCATION" \
            --tags Environment="$ENVIRONMENT" Application="ExpenseManagement" ManagedBy="Script"
    else
        print_info "Resource group already exists: $RESOURCE_GROUP_NAME"
    fi
}

# Function to deploy Bicep template
deploy_infrastructure() {
    print_info "Deploying GenAI infrastructure..."
    
    DEPLOYMENT_NAME="genai-deployment-$(date +%Y%m%d-%H%M%S)"
    
    az deployment group create \
        --name "$DEPLOYMENT_NAME" \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --template-file ./infra/main.bicep \
        --parameters environmentName="$ENVIRONMENT" \
                    location="$LOCATION" \
                    resourcePrefix="$RESOURCE_PREFIX" \
        --output json > deployment-output.json
    
    print_info "Deployment completed: $DEPLOYMENT_NAME"
}

# Function to extract and save outputs
save_deployment_outputs() {
    print_info "Extracting deployment outputs..."
    
    OPENAI_ENDPOINT=$(jq -r '.properties.outputs.openAIEndpoint.value' deployment-output.json)
    OPENAI_NAME=$(jq -r '.properties.outputs.openAIAccountName.value' deployment-output.json)
    GPT4O_DEPLOYMENT=$(jq -r '.properties.outputs.gpt4oDeploymentName.value' deployment-output.json)
    COGNITIVE_ENDPOINT=$(jq -r '.properties.outputs.cognitiveServicesEndpoint.value' deployment-output.json)
    COGNITIVE_NAME=$(jq -r '.properties.outputs.cognitiveServicesName.value' deployment-output.json)
    
    print_info "Azure OpenAI Endpoint: $OPENAI_ENDPOINT"
    print_info "Azure OpenAI Account: $OPENAI_NAME"
    print_info "GPT-4o Deployment: $GPT4O_DEPLOYMENT"
    print_info "Cognitive Services Endpoint: $COGNITIVE_ENDPOINT"
    print_info "Cognitive Services Name: $COGNITIVE_NAME"
    
    # Update GenAISettings.json
    print_info "Updating GenAISettings.json with deployment outputs..."
    
    jq --arg openai_endpoint "$OPENAI_ENDPOINT" \
       --arg cognitive_endpoint "$COGNITIVE_ENDPOINT" \
       '.AzureOpenAI.Endpoint = $openai_endpoint | .CognitiveServices.Endpoint = $cognitive_endpoint' \
       ./config/GenAISettings.json > ./config/GenAISettings.tmp.json && \
       mv ./config/GenAISettings.tmp.json ./config/GenAISettings.json
    
    print_info "GenAISettings.json updated successfully"
    
    # Create a summary file
    cat > deployment-summary.txt <<EOF
Expense Management System - GenAI Infrastructure Deployment Summary
====================================================================

Deployment Date: $(date)
Resource Group: $RESOURCE_GROUP_NAME
Location: $LOCATION
Environment: $ENVIRONMENT

Azure OpenAI Service:
---------------------
Account Name: $OPENAI_NAME
Endpoint: $OPENAI_ENDPOINT
Deployment Name: $GPT4O_DEPLOYMENT
Model: GPT-4o (2024-05-13)
Region: Sweden Central
SKU: S0

Cognitive Services:
-------------------
Account Name: $COGNITIVE_NAME
Endpoint: $COGNITIVE_ENDPOINT
Region: $LOCATION
SKU: S0

Authentication:
---------------
Managed Identity: Enabled (System-assigned)

Next Steps:
-----------
1. Review the updated config/GenAISettings.json file
2. Configure your application to use the endpoints above
3. Ensure your application's managed identity has proper RBAC roles
4. Test the GenAI integration

For managed identity access, assign these roles:
- Cognitive Services OpenAI User (for Azure OpenAI)
- Cognitive Services User (for Cognitive Services)

Example Azure CLI commands:
az role assignment create --assignee <app-identity-principal-id> \\
    --role "Cognitive Services OpenAI User" \\
    --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.CognitiveServices/accounts/$OPENAI_NAME

az role assignment create --assignee <app-identity-principal-id> \\
    --role "Cognitive Services User" \\
    --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.CognitiveServices/accounts/$COGNITIVE_NAME
EOF
    
    print_info "Deployment summary saved to deployment-summary.txt"
}

# Main execution
main() {
    print_info "Starting Expense Management System GenAI Infrastructure Deployment"
    print_info "=================================================================="
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -g|--resource-group)
                RESOURCE_GROUP_NAME="$2"
                shift 2
                ;;
            -l|--location)
                LOCATION="$2"
                shift 2
                ;;
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -p|--prefix)
                RESOURCE_PREFIX="$2"
                shift 2
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  -g, --resource-group NAME    Resource group name (default: rg-expensemgmt-dev)"
                echo "  -l, --location LOCATION      Azure region (default: uksouth)"
                echo "  -e, --environment ENV        Environment name (default: dev)"
                echo "  -p, --prefix PREFIX          Resource name prefix (default: expensemgmt)"
                echo "  -h, --help                   Show this help message"
                echo ""
                echo "Example:"
                echo "  $0 -g rg-expense-prod -e prod -l uksouth"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use -h or --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_azure_cli
    check_azure_login
    
    # Deploy infrastructure
    create_resource_group
    deploy_infrastructure
    save_deployment_outputs
    
    print_info "=================================================================="
    print_info "Deployment completed successfully!"
    print_info "Please review deployment-summary.txt for details and next steps."
    print_info "=================================================================="
}

# Run main function
main "$@"
