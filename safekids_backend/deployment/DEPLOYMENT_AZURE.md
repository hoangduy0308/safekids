# 🚀 SafeKids Backend - Deploy Lên Azure App Service (Student)

## 🎯 Ưu Điểm Của Phương Án Này

✅ **Dùng $100 Azure Student Credit**
✅ **Tắt/Bật khi cần → Tiết kiệm credit**
✅ **24/7 uptime khi đang chạy (không sleep)**
✅ **Professional, tốt cho demo/báo cáo**

**Chi phí ước tính:**
- B1 Basic: ~$0.018/giờ = ~$0.43/ngày
- Nếu bật 4 giờ/ngày: ~$2.58/tháng
- **$100 credit → Dùng 3+ năm!**

---

## 📋 Yêu Cầu

- [x] Tài khoản Azure Student (đã có)
- [ ] Backend code trên GitHub
- [ ] MongoDB Atlas (setup ở bước 1)

---

## 📦 BƯỚC 1: Setup MongoDB Atlas

> **Giống guide Railway**, xem chi tiết trong `DEPLOYMENT.md` phần BƯỚC 1

**TÓM TẮT:**
1. Tạo account: https://www.mongodb.com/cloud/atlas/register
2. Tạo M0 Free cluster (Singapore region)
3. Tạo database user: `safekids-admin` / password mạnh
4. Network Access: Allow `0.0.0.0/0`
5. Lấy connection string:
```
mongodb+srv://safekids-admin:<password>@safekids-cluster.xxxxx.mongodb.net/safekids?retryWrites=true&w=majority
```

✅ **Lưu connection string này!**

---

## ☁️ BƯỚC 2: Tạo Azure App Service

### 2.1. Đăng Nhập Azure Portal
1. Truy cập: https://portal.azure.com
2. Đăng nhập với tài khoản student
3. Verify có **$100 credit** ở góc phải trên

### 2.2. Tạo Resource Group
1. Search bar → gõ **"Resource groups"**
2. Click **"+ Create"**
3. Điền thông tin:
   - Subscription: **Azure for Students**
   - Resource group name: `safekids-rg`
   - Region: **Southeast Asia** (Singapore - gần VN)
4. Click **"Review + create"** → **"Create"**

### 2.3. Tạo App Service
1. Search bar → gõ **"App Services"**
2. Click **"+ Create"** → **"Web App"**

3. **Basics tab:**
   - Subscription: **Azure for Students**
   - Resource Group: `safekids-rg`
   - Name: `safekids-backend` (hoặc tên unique)
     - URL sẽ là: `https://safekids-backend.azurewebsites.net`
   - Publish: **Code**
   - Runtime stack: **Node 18 LTS**
   - Operating System: **Linux**
   - Region: **Southeast Asia**

4. **Pricing Plan:**
   - Click **"Change size"**
   - Dev/Test → Chọn **B1 (Basic)**
     - 1 Core, 1.75 GB RAM
     - ~$13/tháng (~$0.018/giờ)
   - Click **"Apply"**

5. **Deployment tab:**
   - GitHub Actions: **Enable**
   - Sign in to GitHub
   - Organization: Chọn GitHub account của bạn
   - Repository: Chọn `safekids-backend` (hoặc repo của bạn)
   - Branch: `main` hoặc `master`

6. **Review + create:**
   - Xem lại thông tin
   - Click **"Create"**
   - Đợi 2-3 phút deployment xong

✅ **App Service đã được tạo!**

---

## 🔧 BƯỚC 3: Configure Environment Variables

### 3.1. Mở App Service Configuration
1. Portal → **App Services** → Click `safekids-backend`
2. Sidebar → **Configuration** (dưới Settings)
3. Tab **"Application settings"**

### 3.2. Thêm Environment Variables
Click **"+ New application setting"** cho từng biến:

```bash
# MongoDB
MONGODB_URI
mongodb+srv://safekids-admin:<password>@safekids-cluster.xxxxx.mongodb.net/safekids?retryWrites=true&w=majority

# Server
NODE_ENV
production

PORT
8080

# JWT
JWT_SECRET
<tạo random string mạnh, ví dụ: Sk2024AzureSecretKey!Random123>

JWT_EXPIRES_IN
7d

# Firebase (nếu dùng)
FIREBASE_PROJECT_ID
<your-firebase-project-id>

FIREBASE_PRIVATE_KEY
<your-firebase-private-key>

FIREBASE_CLIENT_EMAIL
<firebase-email>

# Features
LOCATION_UPDATE_INTERVAL
30000

DEFAULT_GEOFENCE_RADIUS
100

SCREENTIME_CHECK_INTERVAL
60000
```

**⚠️ LƯU Ý:**
- PORT phải là `8080` cho Azure Linux
- FIREBASE_PRIVATE_KEY: giữ nguyên `\n`, wrap trong quotes nếu có dấu cách

### 3.3. Save Configuration
1. Click **"Save"** ở trên cùng
2. Click **"Continue"** khi có warning (app sẽ restart)
3. Đợi 1-2 phút app restart

---

## 🚀 BƯỚC 4: Deploy Code

### 4.1. GitHub Actions Auto Deploy
Khi bạn chọn GitHub Actions ở bước 2.3, Azure đã tự tạo workflow file.

**Kiểm tra:**
1. Vào GitHub repo của bạn
2. Folder `.github/workflows/` sẽ có file mới
3. File này auto deploy khi push code

### 4.2. Trigger Deployment
**Cách 1: Push code mới**
```bash
git add .
git commit -m "Initial Azure deployment"
git push origin main
```

**Cách 2: Manual deploy từ Azure**
1. App Service → **Deployment Center**
2. Click **"Sync"** để pull code mới
3. Xem logs để track progress

### 4.3. Verify Deployment
1. Đợi deployment xong (3-5 phút)
2. Mở browser:
```
https://safekids-backend.azurewebsites.net/health
```
3. Nếu thấy response:
```json
{
  "status": "OK",
  "message": "SafeKids Backend is running!",
  "timestamp": "..."
}
```
✅ **DEPLOYMENT THÀNH CÔNG!**

---

## 💡 BƯỚC 5: Tắt/Bật App Service (Tiết Kiệm Credit)

### Cách 1: Qua Azure Portal (Đơn Giản) ⭐

#### TẮT App Service:
1. Portal → **App Services** → `safekids-backend`
2. Click **"Stop"** ở trên cùng
3. Confirm → App tắt trong 10 giây
4. **Status:** Stopped (Not running)
5. ⚠️ **Không tính phí khi stopped!**

#### BẬT App Service:
1. Portal → **App Services** → `safekids-backend`
2. Click **"Start"** ở trên cùng
3. Đợi 30-60 giây app khởi động
4. **Status:** Running
5. Test lại `/health` endpoint

---

### Cách 2: Azure CLI (Nhanh, Cho Power User)

#### Cài Đặt Azure CLI:
**Windows:**
```bash
# Download installer từ:
https://aka.ms/installazurecliwindows
```

**macOS:**
```bash
brew install azure-cli
```

**Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### Login Azure:
```bash
az login
```

#### TẮT App:
```bash
az webapp stop --name safekids-backend --resource-group safekids-rg
```

#### BẬT App:
```bash
az webapp start --name safekids-backend --resource-group safekids-rg
```

#### Kiểm Tra Status:
```bash
az webapp show --name safekids-backend --resource-group safekids-rg --query "state"
```

---

### Cách 3: Script Tự Động (Recommended!)

Tạo file `azure-control.sh` (macOS/Linux) hoặc `azure-control.ps1` (Windows):

**PowerShell (Windows):**
```powershell
# Lưu file: azure-control.ps1

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "status")]
    [string]$Action
)

$AppName = "safekids-backend"
$ResourceGroup = "safekids-rg"

switch ($Action) {
    "start" {
        Write-Host "🚀 Starting App Service..." -ForegroundColor Green
        az webapp start --name $AppName --resource-group $ResourceGroup
        Write-Host "✅ App started! URL: https://$AppName.azurewebsites.net" -ForegroundColor Green
    }
    "stop" {
        Write-Host "🛑 Stopping App Service..." -ForegroundColor Yellow
        az webapp stop --name $AppName --resource-group $ResourceGroup
        Write-Host "✅ App stopped! No charges while stopped." -ForegroundColor Green
    }
    "status" {
        Write-Host "📊 Checking status..." -ForegroundColor Cyan
        az webapp show --name $AppName --resource-group $ResourceGroup --query "state" -o tsv
    }
}
```

**Sử dụng:**
```powershell
# Bật app
.\azure-control.ps1 start

# Tắt app
.\azure-control.ps1 stop

# Kiểm tra status
.\azure-control.ps1 status
```

**Bash (macOS/Linux):**
```bash
#!/bin/bash
# Lưu file: azure-control.sh

APP_NAME="safekids-backend"
RESOURCE_GROUP="safekids-rg"

case "$1" in
    start)
        echo "🚀 Starting App Service..."
        az webapp start --name $APP_NAME --resource-group $RESOURCE_GROUP
        echo "✅ App started! URL: https://$APP_NAME.azurewebsites.net"
        ;;
    stop)
        echo "🛑 Stopping App Service..."
        az webapp stop --name $APP_NAME --resource-group $RESOURCE_GROUP
        echo "✅ App stopped! No charges while stopped."
        ;;
    status)
        echo "📊 Status:"
        az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP --query "state" -o tsv
        ;;
    *)
        echo "Usage: ./azure-control.sh {start|stop|status}"
        exit 1
        ;;
esac
```

**Sử dụng:**
```bash
chmod +x azure-control.sh
./azure-control.sh start   # Bật
./azure-control.sh stop    # Tắt
./azure-control.sh status  # Check
```

---

## 📱 BƯỚC 6: Cập Nhật Flutter App

Trong Flutter project, update API URL:

```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String baseUrl = 'https://safekids-backend.azurewebsites.net';
  static const String apiVersion = '/api';
  static const String socketUrl = 'https://safekids-backend.azurewebsites.net';
}
```

**Test:**
1. Build APK: `flutter build apk --debug`
2. Install trên điện thoại
3. Test các chức năng

---

## 📊 Monitoring & Management

### 1. Xem Logs Real-time
**Portal:**
1. App Service → **Log stream**
2. Xem console.log() từ Node.js

**CLI:**
```bash
az webapp log tail --name safekids-backend --resource-group safekids-rg
```

### 2. Kiểm Tra Credit Còn Lại
1. Portal → Click icon credit ở góc phải trên
2. Hoặc: https://www.microsoftazuresponsorships.com/Balance

### 3. Metrics & Performance
1. App Service → **Metrics**
2. Xem: CPU, Memory, Response time, Requests

### 4. Alerts (Tùy chọn)
Set alert khi credit gần hết:
1. Portal → **Cost Management + Billing**
2. **Budgets** → **+ Add**
3. Set budget $10/tháng → Email alert

---

## 💰 Tối Ưu Chi Phí

### Strategy: Chỉ Bật Khi Cần

**Workflow hàng ngày:**
1. **Sáng (trước khi test):**
   ```bash
   ./azure-control.sh start
   ```
   Đợi 1 phút → Test app

2. **Tối (sau khi test xong):**
   ```bash
   ./azure-control.sh stop
   ```

3. **Khi demo/báo cáo:**
   - Bật trước 5 phút
   - Demo xong → Tắt ngay

**Ước tính chi phí:**
- Test 4 giờ/ngày: $0.072/ngày = $2.16/tháng
- Demo 2 giờ/tuần: $0.144/tuần = $0.58/tháng
- **Tổng:** ~$2.74/tháng
- **$100 credit → 36 tháng (3 năm!)** 🎉

### Backup Plan: Nếu Credit Gần Hết
1. **Scale down:** B1 → Free tier (có giới hạn)
2. **Chuyển sang Railway:** Free tier với sleep
3. **Render.com:** Free tier khác

---

## 🔧 Troubleshooting

### App không start sau khi deploy
**Check:**
1. Logs: App Service → **Log stream**
2. Environment variables có đúng không
3. PORT phải là `8080` (không phải 3000)

**Fix:**
```bash
# Update server.js nếu cần
const PORT = process.env.PORT || 8080;
```

### MongoDB connection failed
**Check:**
1. MONGODB_URI có đúng password không
2. Atlas Network Access có `0.0.0.0/0`
3. Test connection string locally

### GitHub Actions deploy failed
**Check:**
1. Repo → Actions → Xem log lỗi
2. Verify workflow file có đúng branch
3. Re-sync: Deployment Center → Sync

### App Service start chậm
- Cold start 30-60s là bình thường
- Lần đầu sau khi stop sẽ lâu hơn

---

## 🎯 Best Practices

### 1. Git Workflow
```bash
# Development
git checkout -b feature/new-feature
# Code...
git push origin feature/new-feature

# Merge to main → Auto deploy
git checkout main
git merge feature/new-feature
git push origin main
```

### 2. Environment Management
- Không commit `.env` lên Git
- Dùng Azure App Settings cho production
- Local dev dùng `.env` file

### 3. Database Backup
MongoDB Atlas Free tier không có auto backup:
```bash
# Manual export
mongodump --uri="mongodb+srv://..."
```

### 4. Security
- JWT_SECRET: Random mạnh, unique
- Không share environment variables
- Enable HTTPS only (Azure default)

---

## 📞 Quick Reference

### URLs
- **Portal:** https://portal.azure.com
- **API Health:** https://safekids-backend.azurewebsites.net/health
- **Credit Balance:** https://www.microsoftazuresponsorships.com/Balance

### Commands
```bash
# Start app
az webapp start --name safekids-backend --resource-group safekids-rg

# Stop app
az webapp stop --name safekids-backend --resource-group safekids-rg

# View logs
az webapp log tail --name safekids-backend --resource-group safekids-rg

# Check status
az webapp show --name safekids-backend --resource-group safekids-rg --query "state"
```

---

## 🎉 Hoàn Thành!

**Checklist cuối cùng:**
- [x] MongoDB Atlas setup
- [x] Azure App Service created
- [x] Environment variables configured
- [x] Code deployed
- [x] Health check passed
- [x] Flutter app updated
- [x] Stop/Start script ready

**Next steps:**
1. ⭐ Bookmark Portal URL
2. 📱 Test trên điện thoại thật
3. 🛑 Nhớ STOP app sau khi test
4. 📊 Check credit balance hàng tuần

**Chúc bạn deploy thành công! 🚀**

---

## 📚 Tài Nguyên Thêm

- Azure Student: https://azure.microsoft.com/en-us/free/students/
- Azure CLI Docs: https://docs.microsoft.com/en-us/cli/azure/
- App Service Docs: https://docs.microsoft.com/en-us/azure/app-service/
- MongoDB Atlas: https://docs.atlas.mongodb.com/
