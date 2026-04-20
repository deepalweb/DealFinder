// Main infrastructure file for DealFinder App Service deployment
// This Bicep template configures the existing App Service with proper settings

param appServiceName string = 'dealfinderlk'
param resourceGroupName string = 'DealFinder'
param location string = 'southindia'
param environmentName string = 'production'

// App Service configuration
param nodeVersion string = '20-lts'
param linuxFxVersion string = 'NODE|20-lts'

// Environment variables
@secure()
param mongoUri string
@secure()
param jwtSecret string
@secure()
param jwtRefreshSecret string
param googleMapsApiKey string
@secure()
param firebaseProjectId string
@secure()
param firebaseClientEmail string
@secure()
param firebasePrivateKey string
param vapidPublicKey string
@secure()
param vapidPrivateKey string
@secure()
param azureStorageConnectionString string
param azureStorageContainerName string = 'deals'

// Reference existing App Service
resource appService 'Microsoft.Web/sites@2023-01-01' existing = {
  name: appServiceName
}

// Configure App Service settings
resource appServiceConfig 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: appService
  name: 'web'
  properties: {
    numberOfWorkers: 1
    defaultDocuments: []
    netFrameworkVersion: 'v4.0'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: true
    detailedErrorLoggingEnabled: true
    publishingUsername: 'dealfinderlk'
    scmType: 'None'
    use32BitWorkerProcess: false
    webSocketsEnabled: true
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    cors: {
      allowedOrigins: [
        '*'
      ]
      supportCredentials: false
    }
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 2147483647
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: true
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.0'
    ftpsState: 'FtpsOnly'
    preWarmedInstanceCount: 0
    fileChangeAuditEnabled: false
    functionAppScaleLimit: 0
    healthCheckPath: '/api/status'
    fileChangeAuditEnabled: false
    functionsRuntimeScaleMonitoringEnabled: false
    websiteTimeZone: 'India Standard Time'
    minimumElasticInstanceCount: 0
    azureStorageAccounts: {}
    machineKey: {
      validation: 'SHA1'
      decryption: 'Auto'
      decryptionKey: ''
      validationKey: ''
    }
  }
}

// Application settings
resource appSettings 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: appService
  name: 'appsettings'
  properties: {
    NODE_ENV: environmentName
    WEBSITE_NODE_DEFAULT_VERSION: '20.0.0'
    
    // Backend environment variables
    MONGO_URI: mongoUri
    JWT_SECRET: jwtSecret
    JWT_REFRESH_SECRET: jwtRefreshSecret
    GOOGLE_MAPS_API_KEY: googleMapsApiKey
    FIREBASE_PROJECT_ID: firebaseProjectId
    FIREBASE_CLIENT_EMAIL: firebaseClientEmail
    FIREBASE_PRIVATE_KEY: firebasePrivateKey
    VAPID_PUBLIC_KEY: vapidPublicKey
    VAPID_PRIVATE_KEY: vapidPrivateKey
    AZURE_STORAGE_CONNECTION_STRING: azureStorageConnectionString
    AZURE_STORAGE_CONTAINER_NAME: azureStorageContainerName
    
    // Application configuration
    PORT: '8080'
    LOG_LEVEL: 'info'
    ENABLE_METRICS: 'true'
  }
}

// Startup command configuration for Linux App Service
resource startupCommand 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: appService
  name: 'configAppsettings'
  properties: {
    WEBSITES_CONTAINER_START_TIME_LIMIT: '900'
    WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'true'
    DOCKER_REGISTRY_SERVER_URL: ''
    DOCKER_REGISTRY_SERVER_USERNAME: ''
    DOCKER_REGISTRY_SERVER_PASSWORD: ''
    DOCKER_CUSTOM_IMAGE_NAME: ''
    WEBSITE_PULL_IMAGE_OVER_VNET: 'false'
  }
}

// Logging configuration
resource diagnosticsLogs 'Microsoft.Web/sites/diagnosticSettings@2017-05-01-preview' = {
  name: '${appService.name}/AppServiceConsoleLogs'
  properties: {
    logs: [
      {
        category: 'AppServiceConsole'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

// Output the deployed App Service endpoint
output appServiceUrl string = 'https://${appService.properties.defaultHostName}'
output appServiceName string = appService.name
output resourceGroupName string = resourceGroupName
