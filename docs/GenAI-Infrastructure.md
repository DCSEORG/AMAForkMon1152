# GenAI Infrastructure Documentation

## Overview

This document describes the Azure OpenAI and Cognitive Services infrastructure for the Expense Management System. The infrastructure enables AI-powered features including:

- **Intelligent Chat Interface**: GPT-4o powered conversational interface for expense queries
- **Receipt Analysis**: Automated receipt data extraction using Cognitive Services
- **Expense Insights**: AI-driven analytics and spending pattern detection
- **Policy Compliance**: Automated expense policy validation

## Architecture

The GenAI infrastructure follows Azure best practices and consists of:

### Azure OpenAI Service
- **SKU**: S0 (Standard, cost-optimized)
- **Region**: Sweden Central (for GPT-4o availability)
- **Model**: GPT-4o (version 2024-05-13)
- **Deployment Name**: gpt-4o
- **Capacity**: 10 TPM (Tokens Per Minute)
- **Authentication**: Managed Identity (System-assigned)

### Cognitive Services
- **SKU**: S0 (Standard, cost-optimized)
- **Region**: UK South (same as primary resource group)
- **Capabilities**: Multi-service account for vision, text analytics
- **Authentication**: Managed Identity (System-assigned)

## Deployment

### Prerequisites

1. **Azure CLI**: Install from [Microsoft Docs](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure Subscription**: Active subscription with appropriate permissions
3. **Permissions Required**:
   - Contributor or Owner role on subscription/resource group
   - Ability to create Cognitive Services resources
4. **Tools** (for script):
   - Bash shell (Linux, macOS, WSL, or Git Bash)
   - jq (JSON processor)

### Quick Start

```bash
# 1. Login to Azure
az login

# 2. Set your subscription (if you have multiple)
az account set --subscription "Your Subscription Name"

# 3. Run the deployment script
./deploy-genai.sh

# With custom parameters
./deploy-genai.sh -g rg-expensemgmt-prod -e prod -l uksouth
```

### Deployment Options

The deployment script supports the following parameters:

| Parameter | Short | Description | Default |
|-----------|-------|-------------|---------|
| --resource-group | -g | Resource group name | rg-expensemgmt-dev |
| --location | -l | Azure region for most resources | uksouth |
| --environment | -e | Environment name (dev/test/prod) | dev |
| --prefix | -p | Resource name prefix | expensemgmt |

### Manual Deployment (Using Azure CLI)

If you prefer to deploy manually:

```bash
# Create resource group
az group create \
    --name rg-expensemgmt-dev \
    --location uksouth

# Deploy infrastructure
az deployment group create \
    --name genai-deployment \
    --resource-group rg-expensemgmt-dev \
    --template-file ./infra/main.bicep \
    --parameters environmentName=dev location=uksouth resourcePrefix=expensemgmt
```

### Manual Deployment (Using Azure Portal)

1. Navigate to Azure Portal
2. Create a new resource group
3. Deploy custom template
4. Upload `infra/main.bicep`
5. Fill in parameters
6. Review and create

## Configuration

### GenAISettings.json

After deployment, the `config/GenAISettings.json` file is automatically updated with endpoints. This file contains:

```json
{
  "AzureOpenAI": {
    "Endpoint": "https://expensemgmt-openai-xyz.openai.azure.com/",
    "DeploymentName": "gpt-4o",
    "UseManagedIdentity": true,
    "MaxTokens": 1000,
    "Temperature": 0.7
  },
  "CognitiveServices": {
    "Endpoint": "https://expensemgmt-cognitive-xyz.cognitiveservices.azure.com/",
    "UseManagedIdentity": true
  },
  "ChatInterface": {
    "SystemPrompt": "You are an AI assistant for...",
    "EnableExpenseInsights": true,
    "EnableReceiptAnalysis": true
  }
}
```

### Environment Variables (Alternative)

For containerized deployments, you can use environment variables:

```bash
AZURE_OPENAI_ENDPOINT=https://expensemgmt-openai-xyz.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4o
AZURE_COGNITIVE_ENDPOINT=https://expensemgmt-cognitive-xyz.cognitiveservices.azure.com/
USE_MANAGED_IDENTITY=true
```

## Security & Authentication

### Managed Identity (Recommended)

The infrastructure uses **System-assigned Managed Identity** for secure, keyless authentication:

**Benefits:**
- No credentials in code or configuration files
- Automatic credential rotation
- Azure RBAC integration
- Reduced security risk

**Required RBAC Roles:**

For your application's managed identity:

```bash
# Assign OpenAI User role
az role assignment create \
    --assignee <app-principal-id> \
    --role "Cognitive Services OpenAI User" \
    --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.CognitiveServices/accounts/<openai-name>

# Assign Cognitive Services User role
az role assignment create \
    --assignee <app-principal-id> \
    --role "Cognitive Services User" \
    --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.CognitiveServices/accounts/<cognitive-name>
```

### API Keys (Not Recommended)

If managed identity is not available, you can use API keys:

```bash
# Get Azure OpenAI key
az cognitiveservices account keys list \
    --name <openai-account-name> \
    --resource-group <resource-group>

# Store in Key Vault (recommended)
az keyvault secret set \
    --vault-name <key-vault-name> \
    --name OpenAIKey \
    --value <api-key>
```

## Cost Optimization

Following Azure best practices for cost optimization:

### S0 SKU Selection
- **Azure OpenAI S0**: Pay-per-use pricing, no upfront commitment
- **Cognitive Services S0**: Optimized for development and moderate workloads
- **Estimated Monthly Cost**: £50-200 depending on usage

### Cost Management Tips

1. **Monitor Usage**: Use Azure Cost Management
2. **Set Budgets**: Configure budget alerts
3. **Token Optimization**: Tune `MaxTokens` in GenAISettings.json
4. **Caching**: Implement response caching where appropriate
5. **Auto-shutdown**: For dev/test environments, consider auto-shutdown scripts

### Cost Estimation

```bash
# Get pricing information
az consumption usage list \
    --start-date 2025-11-01 \
    --end-date 2025-11-30 \
    --resource-group rg-expensemgmt-dev
```

## Monitoring & Diagnostics

### Enable Diagnostic Settings

```bash
# For Azure OpenAI
az monitor diagnostic-settings create \
    --name openai-diagnostics \
    --resource <openai-resource-id> \
    --logs '[{"category":"Audit","enabled":true}]' \
    --metrics '[{"category":"AllMetrics","enabled":true}]' \
    --workspace <log-analytics-workspace-id>
```

### Key Metrics to Monitor

- **Token Usage**: Track API calls and token consumption
- **Latency**: Response times for user experience
- **Error Rates**: Failed requests and throttling
- **Cost**: Daily/monthly spending

### Alerts

Configure alerts for:
- High token usage
- Increased error rates
- Budget thresholds
- Service health issues

## Troubleshooting

### Common Issues

#### 1. Deployment Fails - Region Availability

**Error**: "The specified location 'X' is not available for OpenAI"

**Solution**: Azure OpenAI GPT-4o is only available in certain regions. The template uses Sweden Central by default.

#### 2. Authentication Fails

**Error**: "Unauthorized" or "403 Forbidden"

**Solution**: Ensure managed identity has correct RBAC roles assigned.

#### 3. Quota Exceeded

**Error**: "Deployment quota exceeded"

**Solution**: Request quota increase via Azure Portal or use a different subscription.

#### 4. Model Not Available

**Error**: "Model 'gpt-4o' not found"

**Solution**: Ensure you're using the correct API version and deployment name.

### Diagnostic Commands

```bash
# Check OpenAI account status
az cognitiveservices account show \
    --name <openai-name> \
    --resource-group <rg-name>

# List deployments
az cognitiveservices account deployment list \
    --name <openai-name> \
    --resource-group <rg-name>

# Test connectivity
curl -H "Authorization: Bearer $(az account get-access-token --resource=https://cognitiveservices.azure.com --query accessToken -o tsv)" \
    "https://<openai-name>.openai.azure.com/openai/deployments?api-version=2023-05-15"
```

## Best Practices

### 1. Security
- ✅ Always use Managed Identity
- ✅ Store secrets in Azure Key Vault
- ✅ Enable network restrictions in production
- ✅ Implement least-privilege access
- ✅ Enable audit logging

### 2. Reliability
- ✅ Implement retry logic with exponential backoff
- ✅ Handle rate limiting gracefully
- ✅ Use circuit breakers
- ✅ Monitor service health

### 3. Performance
- ✅ Cache common responses
- ✅ Optimize prompts and tokens
- ✅ Use async/await patterns
- ✅ Implement request batching where possible

### 4. Cost Management
- ✅ Set and monitor budgets
- ✅ Use appropriate SKUs for environment
- ✅ Implement usage analytics
- ✅ Review and optimize regularly

## Additional Resources

- [Azure OpenAI Service Documentation](https://learn.microsoft.com/azure/ai-services/openai/)
- [Azure Cognitive Services Documentation](https://learn.microsoft.com/azure/cognitive-services/)
- [Azure Best Practices](https://learn.microsoft.com/azure/architecture/best-practices/)
- [Azure Security Baseline](https://learn.microsoft.com/security/benchmark/azure/)
- [Managed Identity Documentation](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Azure service health
3. Consult Azure documentation
4. Contact Azure support

## License

This infrastructure code is part of the Expense Management System project.
