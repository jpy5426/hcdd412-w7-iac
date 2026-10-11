// HCDD 412 - Week 7: Linux App Service (web app) + Azure AI Language
// No secrets live in this file. The Language key is fetched at runtime into an env var.

@description('Short identifier for your app. Lowercase letters/numbers only.')
@minLength(2)
@maxLength(12)
param appName string

@description('Deployment environment.')
@allowed([
  'dev'
  'staging'
  'prod'
])
param env string = 'dev'

@description('Azure region. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('App Service plan SKU. F1 (Free) is the cheapest.')
@allowed([
  'F1'
])
param planSku string = 'F1'

@description('Deploy the Azure AI Language resource (Part 4).')
param deployLanguage bool = true

@description('AI Language SKU. F0 is free (one per subscription); S is paid.')
@allowed([
  'F0'
  'S'
])
param languageSku string = 'F0'

// Web app and Language subdomain names must be globally unique -> 6-char suffix per resource group.
var suffix = take(uniqueString(resourceGroup().id), 6)
var tags = {
  course: 'HCDD412'
  lab: 'week7'
  environment: env
}

// Linux App Service plan. "reserved: true" is what makes the plan Linux.
resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'plan-${appName}-${env}'
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: planSku
  }
  properties: {
    reserved: true
  }
}

// Web app on the plan above: HTTPS only, TLS 1.2+, FTP disabled.
resource app 'Microsoft.Web/sites@2024-04-01' = {
  name: 'app-${appName}-${env}-${suffix}'
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|20-lts'
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      alwaysOn: false
    }
  }
}

// Azure AI Language (Text Analytics) for the sentiment-analysis proof of concept.
resource lang 'Microsoft.CognitiveServices/accounts@2024-10-01' = if (deployLanguage) {
  name: 'lang-${appName}-${env}'
  location: location
  tags: tags
  kind: 'TextAnalytics'
  sku: {
    name: languageSku
  }
  properties: {
    customSubDomainName: 'lang-${appName}-${env}-${suffix}'
    publicNetworkAccess: 'Enabled'
  }
}

output webAppName string = app.name
output webAppUrl string = 'https://${app.properties.defaultHostName}'
output languageAccountName string = deployLanguage ? lang!.name : ''
output languageEndpoint string = deployLanguage ? lang!.properties.endpoint : ''