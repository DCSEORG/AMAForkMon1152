# Infrastructure as Code (IaC)

This directory contains Azure Bicep templates for deploying the Expense Management System infrastructure.

## Files

- **main.bicep**: Main orchestration template that coordinates all infrastructure deployments
- **genai.bicep**: Azure OpenAI and Cognitive Services resources for GenAI capabilities

## Quick Deploy

```bash
# From repository root
./deploy-genai.sh
```

For detailed deployment instructions, see [GenAI Infrastructure Documentation](../docs/GenAI-Infrastructure.md)

## Resources Created

### GenAI Module (genai.bicep)

- Azure OpenAI Service (S0 SKU, Sweden Central)
  - GPT-4o deployment (model version 2024-05-13)
  - System-assigned managed identity
- Cognitive Services (S0 SKU, UK South)
  - Multi-service account
  - System-assigned managed identity

## Parameters

All templates support the following parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| environmentName | string | 'dev' | Environment name (dev, test, prod) |
| location | string | 'uksouth' | Primary Azure region |
| resourcePrefix | string | 'expensemgmt' | Prefix for resource names |

## Outputs

The templates output the following values for use in application configuration:

- `openAIEndpoint`: Azure OpenAI service endpoint URL
- `openAIAccountName`: Name of the Azure OpenAI account
- `gpt4oDeploymentName`: Name of the GPT-4o deployment
- `cognitiveServicesEndpoint`: Cognitive Services endpoint URL
- `cognitiveServicesName`: Name of the Cognitive Services account

## Usage Examples

### Deploy with Default Parameters

```bash
az deployment group create \
    --resource-group rg-expensemgmt-dev \
    --template-file main.bicep
```

### Deploy with Custom Parameters

```bash
az deployment group create \
    --resource-group rg-expensemgmt-prod \
    --template-file main.bicep \
    --parameters environmentName=prod location=uksouth resourcePrefix=expenseprod
```

### Deploy and Capture Outputs

```bash
az deployment group create \
    --resource-group rg-expensemgmt-dev \
    --template-file main.bicep \
    --query properties.outputs
```

## Best Practices

1. **Use the deployment script**: The `deploy-genai.sh` script handles common tasks automatically
2. **Version control**: All infrastructure changes should be version controlled
3. **Test in dev first**: Always test infrastructure changes in development before production
4. **Tag resources**: Templates automatically apply standard tags for tracking
5. **Use managed identity**: All resources are configured with system-assigned managed identity

## Security Notes

- Resources use managed identity for authentication
- Public network access is enabled by default for development ease
- For production, consider:
  - Enabling network restrictions
  - Using private endpoints
  - Implementing Azure Firewall rules

## Troubleshooting

### Bicep Validation

```bash
# Validate template syntax
az bicep build --file main.bicep

# Perform what-if deployment
az deployment group what-if \
    --resource-group rg-expensemgmt-dev \
    --template-file main.bicep
```

### Common Issues

1. **Quota limits**: Azure OpenAI has regional quotas. Request increases if needed.
2. **Region availability**: GPT-4o is only available in specific regions (Sweden Central configured).
3. **Naming conflicts**: Resource names must be globally unique. The templates use `uniqueString()` to help with this.

## More Information

See the full documentation: [GenAI Infrastructure Documentation](../docs/GenAI-Infrastructure.md)
