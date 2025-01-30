targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
@allowed([
  'canadacentral'
  'eastus'
  'eastus2'
  'southcentralus'
  'westus2'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param location string
param apiServiceName string = ''
param applicationInsightsName string = ''
param appServicePlanName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''
param storageAccountName string = ''
param disableLocalAuth bool = true

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }
var functionAppName = !empty(apiServiceName) ? apiServiceName : '${abbrs.webSitesFunctions}api-${resourceToken}'
var deploymentStorageContainerName = 'app-package-${take(functionAppName, 32)}-${take(toLower(uniqueString(functionAppName, resourceToken)), 7)}'

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// The application backend is a function app
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
    location: location
    tags: tags
    sku: {
      name: 'S1'
      tier: 'Standard'
    }
  }
}

module function 'core/host/functions.bicep' = {
  scope: rg
  name: 'function'
  params: {
    name: '${abbrs.webSitesFunctions}${resourceToken}'
    location: location
    appInsightName: monitoring.outputs.applicationInsightsName
    aspId: appServicePlan.outputs.id
    storageName: storage.outputs.name
    datalakeName: datalake.outputs.datalakeName
  }
}

// Backing storage for Azure functions api
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    containers: [{ name: deploymentStorageContainerName }]
    publicNetworkAccess: 'Enabled'
    networkAcls: {}
  }
}

module datalake 'core/storage/datalake.bicep' = {
  scope: rg
  name: 'datalake'
  params: {
    name: '${abbrs.dataLakeStoreAccounts}${resourceToken}'
    location: location
  }
}

var storageRoleDefinitionId = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' //Storage Blob Data Owner role

// Allow access from api to storage account using a managed identity
module storageRoleAssignmentApi 'app/storage-Access.bicep' = {
  name: 'storageRoleAssignmentapi'
  scope: rg
  params: {
    storageAccountName: storage.outputs.name
    roleDefinitionID: storageRoleDefinitionId
    principalID: function.outputs.functionPrincipalId
  }
}

// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName)
      ? logAnalyticsName
      : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName)
      ? applicationInsightsName
      : '${abbrs.insightsComponents}${resourceToken}'
    disableLocalAuth: disableLocalAuth
  }
}

// var monitoringRoleDefinitionId = '3913510d-42f4-4e42-8a64-420c390055eb' // Monitoring Metrics Publisher role ID

// // Allow access from api to application insights using a managed identity
// module appInsightsRoleAssignmentApi './core/monitor/appinsights-access.bicep' = {
//   name: 'appInsightsRoleAssignmentapi'
//   scope: rg
//   params: {
//     appInsightsName: monitoring.outputs.applicationInsightsName
//     roleDefinitionID: monitoringRoleDefinitionId
//     principalID: apiUserAssignedIdentity.outputs.identityPrincipalId
//   }
// }

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output DATALAKE_NAME string = datalake.outputs.datalakeName
output FILE_SYSTEM_NAME string = datalake.outputs.fileSystemName
output RESOURCE_GROUP_NAME string = rg.name
// output SERVICE_API_NAME string = api.outputs.SERVICE_API_NAME
// output AZURE_FUNCTION_NAME string = api.outputs.SERVICE_API_NAME
