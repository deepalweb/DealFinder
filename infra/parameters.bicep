// Azure deployment parameters for DealFinder App Service
@description('App Service name')
param appServiceName string = 'dealfinderlk'

@description('Resource group name')
param resourceGroupName string = 'DealFinder'

@description('Azure region')
param location string = 'southindia'

@description('Environment name')
param environmentName string = 'production'

@description('Node.js version')
param nodeVersion string = '20-lts'

@description('Linux FX version')
param linuxFxVersion string = 'NODE|20-lts'

// These will be provided at deployment time via AZD
@secure()
@description('MongoDB connection string')
param mongoUri string

@secure()
@description('JWT secret key')
param jwtSecret string

@secure()
@description('JWT refresh secret key')
param jwtRefreshSecret string

@description('Google Maps API key')
param googleMapsApiKey string

@secure()
@description('Firebase project ID')
param firebaseProjectId string

@secure()
@description('Firebase client email')
param firebaseClientEmail string

@secure()
@description('Firebase private key')
param firebasePrivateKey string

@description('VAPID public key')
param vapidPublicKey string

@secure()
@description('VAPID private key')
param vapidPrivateKey string

@secure()
@description('Azure Storage connection string')
param azureStorageConnectionString string

@description('Azure Storage container name')
param azureStorageContainerName string = 'deals'
