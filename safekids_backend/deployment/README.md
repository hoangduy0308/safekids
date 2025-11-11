# SafeKids Backend - Deployment Files

This folder contains all deployment-related configurations and documentation.

## 📁 Contents

### Docker Files
- **`Dockerfile`** - Container image definition
- **`.dockerignore`** - Files to exclude from Docker build
- **`docker-compose.yml`** - Local/testing container orchestration

### Azure Deployment
- **`DEPLOYMENT_AZURE.md`** - Complete Azure deployment guide
- **`azure-control.ps1`** - PowerShell script to start/stop Azure App Service

### Alternative Deployment
- **`DEPLOYMENT.md`** - Railway.app deployment guide (backup option)

## 🚀 Quick Start

### Current Production: Azure App Service

**Backend URL:**
```
https://safekids-backend-ggfdezcpc4cgcnfx.southeastasia-01.azurewebsites.net
```

**Management:**
- Portal: https://portal.azure.com
- Resource Group: `safekids-rg`
- App Service: `safekids-backend`

### Stop/Start (Save Credits)

**Via Portal:**
1. Go to Azure Portal → App Services → `safekids-backend`
2. Click "Stop" or "Start" button

**Via PowerShell (requires Azure CLI):**
```powershell
.\deployment\azure-control.ps1 start   # Start app
.\deployment\azure-control.ps1 stop    # Stop app
.\deployment\azure-control.ps1 status  # Check status
```

## 🐳 Docker Usage

### Local Testing with Docker

**Build image:**
```bash
cd deployment
docker build -t safekids-backend .
```

**Run container:**
```bash
docker run -p 3000:3000 \
  -e MONGODB_URI="your_mongodb_uri" \
  -e JWT_SECRET="your_secret" \
  safekids-backend
```

**Using docker-compose:**
```bash
cd deployment
docker-compose up -d
```

## 📚 Documentation

- **Azure Guide:** `DEPLOYMENT_AZURE.md` - Primary deployment guide
- **Railway Guide:** `DEPLOYMENT.md` - Alternative platform

## 🔗 Related Files

Main application code is in parent directory:
- `../server.js` - Main entry point
- `../package.json` - Dependencies
- `../src/` - Source code
- `../.env.example` - Environment variables template

## 💡 Tips

1. **Always stop Azure App Service when not testing** to save credits
2. **Docker files are backup options** if need to switch platforms
3. **Check Azure credit balance weekly** at https://www.microsoftazuresponsorships.com/Balance
