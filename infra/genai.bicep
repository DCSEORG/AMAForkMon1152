// GenAI Infrastructure for Expense Management System
// Creates Azure OpenAI and related resources for AI-powered chat interface
// Following Azure best practices and using managed identities

@description('The name of the environment (e.g., dev, test, prod)')
param environmentName string = 'dev'

@description('The location for resources (default: UK South)')
param location string = 'uksouth'

@description('The location for Azure OpenAI (Sweden Central for GPT-4o)')
param openAILocation string = 'swedencentral'

@description('The name prefix for all resources')
param resourcePrefix string = 'expensemgmt'

@description('Tags to apply to all resources')
param tags object = {
  Environment: environmentName
  Application: 'ExpenseManagement'
  ManagedBy: 'Bicep'
}

// Variables
var uniqueSuffix = uniqueString(resourceGroup().id)
var openAIAccountName = '${resourcePrefix}-openai-${uniqueSuffix}'
var cognitiveServicesName = '${resourcePrefix}-cognitive-${uniqueSuffix}'

// Azure OpenAI Service
resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIAccountName
  location: openAILocation
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: openAIAccountName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  tags: tags
}

// Deploy GPT-4o model
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-05-13'
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    raiPolicyName: 'Microsoft.Default'
  }
}

// Cognitive Services (for additional AI capabilities)
resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: cognitiveServicesName
  location: location
  kind: 'CognitiveServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: cognitiveServicesName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  tags: tags
}

// Outputs for use in application configuration
output openAIAccountName string = openAIAccount.name
output openAIEndpoint string = openAIAccount.properties.endpoint
output openAIAccountId string = openAIAccount.id
output openAIPrincipalId string = openAIAccount.identity.principalId
output gpt4oDeploymentName string = gpt4oDeployment.name

output cognitiveServicesName string = cognitiveServices.name
output cognitiveServicesEndpoint string = cognitiveServices.properties.endpoint
output cognitiveServicesId string = cognitiveServices.id
output cognitiveServicesPrincipalId string = cognitiveServices.identity.principalId
