param name string
param location string

resource datalake 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: {
    Description: 'Datalake'
  }
  properties: {
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled'
    isHnsEnabled: true
    isSftpEnabled: false
    largeFileSharesState: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      ipRules: []
    }
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource fileservice 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: datalake
  name: 'default'
  properties: {}
}

output datalakeName string = datalake.name
output datalakeStorageId string = datalake.id
output fileSystemName string = fileservice.name
