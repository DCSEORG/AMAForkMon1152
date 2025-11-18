// Main Infrastructure Deployment for Expense Management System
// Orchestrates all Azure resources including GenAI capabilities

targetScope = 'resourceGroup'

@description('The name of the environment (e.g., dev, test, prod)')
param environmentName string = 'dev'

@description('The location for most resources (default: UK South)')
param location string = 'uksouth'

@description('The name prefix for all resources')
param resourcePrefix string = 'expensemgmt'

// Deploy GenAI resources
module genai 'genai.bicep' = {
  name: 'genai-deployment'
  params: {
    environmentName: environmentName
    location: location
    resourcePrefix: resourcePrefix
  }
}

// Outputs
output openAIEndpoint string = genai.outputs.openAIEndpoint
output openAIAccountName string = genai.outputs.openAIAccountName
output gpt4oDeploymentName string = genai.outputs.gpt4oDeploymentName
output cognitiveServicesEndpoint string = genai.outputs.cognitiveServicesEndpoint
output cognitiveServicesName string = genai.outputs.cognitiveServicesName
