# 🚀 DealFinder Deployment to Existing App Service

## Quick Start (Easiest Method)

Your App Service `dealfinderlk` is ready for code deployment. Choose one of these methods:

---

## Method 1: Git Deployment (Recommended)

Git deployment automatically deploys whenever you push to a branch.

### Step 1: Get your Git deployment URL
```powershell
az webapp deployment source config-local-git `
  --name dealfinderlk `
  --resource-group DealFinder
```

This returns your Git URL: `https://dealfinderlk.scm.azurewebsites.net/dealfinderlk.git`

### Step 2: Add Azure as a Git remote
```powershell
git remote add azure https://dealfinderlk.scm.azurewebsites.net/dealfinderlk.git
```

### Step 3: Push your code
```powershell
git push azure main
```

App Service will automatically:
- Pull your code
- Install dependencies
- Start your application

---

## Method 2: ZIP Deployment (Quick One-Time Deploy)

```powershell
# 1. Compress your code
Compress-Archive -Path backend, frontend-next -DestinationPath app.zip -Force

# 2. Deploy the ZIP file
az webapp deployment source config-zip `
  --name dealfinderlk `
  --resource-group DealFinder `
  --src-path app.zip
```

---

## Method 3: Azure CLI (Simplest)

```powershell
# Deploy directly from current folder
az webapp up `
  --name dealfinderlk `
  --resource-group DealFinder `
  --runtime "node|20-lts"
```

---

## Configure App Service Settings

After deployment, configure these in Azure Portal or CLI:

### Set Environment Variables
```powershell
az webapp config appsettings set `
  --name dealfinderlk `
  --resource-group DealFinder `
  --settings `
    MONGO_URI="your-mongo-uri" `
    JWT_SECRET="your-jwt-secret" `
    JWT_REFRESH_SECRET="your-jwt-refresh" `
    GOOGLE_MAPS_API_KEY="your-maps-key" `
    FIREBASE_PROJECT_ID="your-firebase-id" `
    FIREBASE_CLIENT_EMAIL="your-firebase-email" `
    FIREBASE_PRIVATE_KEY="your-firebase-key" `
    VAPID_PUBLIC_KEY="your-vapid-public" `
    VAPID_PRIVATE_KEY="your-vapid-private" `
    AZURE_STORAGE_CONNECTION_STRING="your-storage-string" `
    AZURE_STORAGE_CONTAINER_NAME="deals" `
    NODE_ENV="production"
```

### Set Startup Command
```powershell
az webapp config set `
  --name dealfinderlk `
  --resource-group DealFinder `
  --startup-file "node backend/server.js"
```

---

## Verify Deployment

```powershell
# Check deployment status
az webapp deployment list `
  --name dealfinderlk `
  --resource-group DealFinder `
  --query "[0]"

# Check app is running
Invoke-WebRequest -Uri "https://dealfinderlk.azurewebsites.net/api/status"

# View logs
az webapp log tail `
  --name dealfinderlk `
  --resource-group DealFinder
```

---

## Troubleshooting

### App won't start
```powershell
# Check logs
az webapp log download `
  --name dealfinderlk `
  --resource-group DealFinder `
  --log-file "logs.zip"
```

### Restart app
```powershell
az webapp restart `
  --name dealfinderlk `
  --resource-group DealFinder
```

### Scale up
```powershell
az appservice plan update `
  --name dealfinderlk `
  --resource-group DealFinder `
  --sku P2V2
```

---

## Next Steps

1. **Choose your deployment method** (Git recommended)
2. **Deploy** the code to App Service
3. **Verify** endpoints are working:
   - Frontend: `https://dealfinderlk.azurewebsites.net/`
   - Backend: `https://dealfinderlk.azurewebsites.net/api/status`
4. **Monitor** with Azure Portal or CLI logs

---

## Your App Service Details

- **Name**: dealfinderlk
- **Region**: South India (southindia)
- **OS**: Linux
- **Plan**: P5mv3 (Premium)
- **Domain**: dealfinderlk-eafsbyd7ghaph0az.southindia-01.azurewebsites.net
- **Subscription**: Microsoft Azure Sponsorship
- **Resource Group**: DealFinder

Good luck! 🎉
