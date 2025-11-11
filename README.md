# SafeKids - Parental Control & Family Safety App

![SafeKids Logo](https://img.shields.io/badge/SafeKids-Family%20Safety-blue?style=for-the-badge&logo=shield-check)
![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Node.js-informational?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

A comprehensive family safety application designed to help parents keep track of their children's location, screen time, and ensure their well-being through real-time monitoring and communication features.

## 🌟 Key Features

### 👨‍👩‍👧‍👦 Family Management
- **Parent-Child Linking**: Secure invitation system for connecting family members
- **Role-Based Access**: Separate interfaces for parents and children
- **Multi-Child Support**: Monitor multiple children from a single parent account

### 📍 Location Tracking & Safety
- **Real-Time GPS Tracking**: Live location monitoring of children
- **Location History**: Detailed tracking of places visited
- **Geofencing**: Create safe zones with instant alerts when children enter/leave
- **Smart Geofence Suggestions**: AI-powered recommendations for frequently visited locations
- **SOS Alerts**: Emergency alerts with precise location information

### 📱 Screen Time Management
- **Usage Monitoring**: Track app usage and screen time patterns
- **Time Limits**: Set daily screen time restrictions
- **App Blocking**: Restrict access to specific applications
- **Usage Reports**: Detailed analytics and insights
- **Automated Locking**: Child's device locks when time limits are exceeded

### 💬 Communication
- **Real-Time Chat**: Secure messaging between parents and children
- **Audio Calling**: Voice calls for immediate communication (via Agora)
- **Push Notifications**: Instant alerts for important events

### 🔔 Smart Notifications
- **Customizable Alerts**: Tailored notification preferences
- **Email Integration**: Email notifications for important events
- **SMS Support**: SMS alerts via Twilio integration
- **Real-Time Updates**: WebSocket-based live notifications

## 🏗️ Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.9.2+
- **State Management**: Provider pattern
- **Platform Support**: iOS, Android, Windows, Web
- **Key Dependencies**:
  - Location & Maps: `geolocator`, `flutter_map`, `geocoding`
  - Real-time: `socket_io_client`
  - Storage: `hive_flutter`, `shared_preferences`
  - Notifications: `firebase_messaging`, `flutter_local_notifications`
  - UI: `provider`, `fl_chart`, `google_fonts`

### Backend (Node.js + Express)
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Real-Time**: Socket.IO
- **Authentication**: JWT with bcrypt
- **API Documentation**: Swagger/OpenAPI
- **Key Dependencies**:
  - Database: `mongoose`
  - Authentication: `jsonwebtoken`, `bcryptjs`
  - Real-time: `socket.io`
  - Notifications: `firebase-admin`, `nodemailer`, `twilio`
  - Validation: `joi`, `express-validator`

## 📂 Project Structure

```
SafeKids/
├── safekids_fe/                 # Flutter Mobile App
│   ├── lib/
│   │   ├── screens/            # UI Screens
│   │   │   ├── auth/          # Authentication screens
│   │   │   ├── parent/        # Parent-specific screens
│   │   │   ├── child/         # Child-specific screens
│   │   │   └── chat/          # Chat and communication
│   │   ├── widgets/           # Reusable UI components
│   │   ├── services/          # Business logic & API calls
│   │   ├── providers/         # State management
│   │   ├── models/            # Data models
│   │   └── theme/             # App theming
│   ├── android/               # Android configuration
│   ├── ios/                   # iOS configuration
│   └── pubspec.yaml           # Flutter dependencies
│
├── safekids_backend/            # Node.js API Server
│   ├── src/
│   │   ├── controllers/       # Request handlers
│   │   ├── models/           # MongoDB schemas
│   │   ├── routes/           # API endpoints
│   │   ├── services/         # Business logic
│   │   ├── middleware/       # Authentication, validation
│   │   ├── utils/            # Helper functions
│   │   └── config/           # Configuration files
│   ├── tests/                # Test suites
│   ├── deployment/           # Docker & deployment configs
│   └── package.json          # Node.js dependencies
│
└── README.md                  # This file
```

## 🚀 Getting Started

### Prerequisites

**For Frontend:**
- Flutter SDK 3.9.2 or higher
- Dart SDK compatible with Flutter version
- Android Studio / Xcode for mobile development
- Firebase account for push notifications

**For Backend:**
- Node.js 18.0+ and npm
- MongoDB 4.4+ (MongoDB Atlas recommended for production)
- Firebase Admin SDK configuration
- Gmail account for email notifications
- Twilio account for SMS notifications

### Installation

#### 1. Clone the Repository
```bash
git clone <repository-url>
cd SafeKids
```

#### 2. Backend Setup
```bash
cd safekids_backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env
# Edit .env with your configuration

# Start development server
npm run dev
```

**Backend Environment Variables (.env):**
```env
# Server
PORT=3000
NODE_ENV=development

# Database
MONGODB_URI=mongodb://localhost:27017/safekids

# Authentication
JWT_SECRET=your-super-secret-jwt-key

# Firebase
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=your-firebase-private-key
FIREBASE_CLIENT_EMAIL=your-firebase-client-email

# Email (Gmail)
GMAIL_USER=your-email@gmail.com
GMAIL_PASS=your-app-password

# SMS (Twilio)
TWILIO_ACCOUNT_SID=your-twilio-sid
TWILIO_AUTH_TOKEN=your-twilio-token
TWILIO_PHONE_NUMBER=+1234567890

# Agora (Audio Calling)
AGORA_APP_ID=your-agora-app-id
```

#### 3. Frontend Setup
```bash
cd safekids_fe

# Install dependencies
flutter pub get

# Configure Firebase
# Download google-services.json for Android
# Download GoogleService-Info.plist for iOS

# Run the app
flutter run
```

**Frontend Configuration (lib/config/environment.dart):**
```dart
class Environment {
  static const String apiUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';

  // Firebase configuration handled automatically
  // via google-services.json and GoogleService-Info.plist
}
```

### 🧪 Testing

#### Backend Tests
```bash
cd safekids_backend

# Run all tests
npm test

# Run specific test suites
npm run test:story-2.1    # Authentication tests
npm run test:story-3.2    # Notification tests
npm run test:coverage     # Generate coverage report
```

#### Frontend Tests
```bash
cd safekids_fe

# Run unit and widget tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app_test.dart
```

## 📱 API Documentation

Once the backend is running, you can access the API documentation at:
- **Swagger UI**: `http://localhost:3000/api-docs`

### Key API Endpoints

**Authentication:**
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/verify-email` - Email verification

**Location:**
- `POST /api/location/update` - Update child location
- `GET /api/location/history` - Get location history
- `GET /api/location/current/:childId` - Get current location

**Geofencing:**
- `POST /api/geofence/create` - Create geofence
- `GET /api/geofence/list` - List all geofences
- `DELETE /api/geofence/:id` - Delete geofence

**Screen Time:**
- `POST /api/screentime/usage` - Log screen time usage
- `GET /api/screentime/reports` - Get usage reports
- `POST /api/screentime/config` - Update screen time limits

## 🚀 Deployment

### Backend Deployment

#### Azure App Service (Current Production)
```bash
# Deployment files are in /deployment folder
cd safekids_backend/deployment

# Follow DEPLOYMENT_AZURE.md for complete setup
```

**Production URL**: `https://safekids-backend-ggfdezcpc4cgcnfx.southeastasia-01.azurewebsites.net`

#### Docker Deployment
```bash
# Build Docker image
docker build -t safekids-backend .

# Run container
docker run -p 3000:3000 safekids-backend
```

### Frontend Deployment

#### Mobile Apps
```bash
# Android Release Build
cd safekids_fe
flutter build apk --release

# iOS Release Build
flutter build ios --release
```

#### Web Deployment
```bash
# Build for web
flutter build web

# Deploy to hosting service (Firebase Hosting, Netlify, etc.)
firebase deploy --only hosting
```

## 🔧 Configuration Details

### Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project

2. **Enable Services**
   - Cloud Messaging (FCM) for push notifications
   - Authentication for user management
   - Firestore (optional for additional features)

3. **Download Configuration**
   - Android: `google-services.json` → `safekids_fe/android/app/`
   - iOS: `GoogleService-Info.plist` → `safekids_fe/ios/Runner/`

4. **Backend Firebase Admin**
   - Generate service account key
   - Save as `serviceAccountKey.json` in backend root

### MongoDB Setup

**Local Development:**
```bash
# Install MongoDB Community Server
# Start MongoDB service
mongod --dbpath /path/to/your/db
```

**MongoDB Atlas (Recommended for Production):**
1. Create free cluster at [MongoDB Atlas](https://www.mongodb.com/atlas)
2. Get connection string
3. Add to `.env` file as `MONGODB_URI`

## 🎯 Core Stories & Features Implementation

### Story 2.1: Family Linking System
- ✅ Parent-child invitation workflow
- ✅ Secure QR code and email invitations
- ✅ Accept/reject functionality
- ✅ Family member management

### Story 2.3: Real-Time Location Tracking
- ✅ GPS location updates every 30 seconds
- ✅ Background location tracking
- ✅ Location history storage and retrieval
- ✅ Battery optimization handling

### Story 3.2: Geofencing & Safety Zones
- ✅ Geofence creation and management
- ✅ Real-time entry/exit detection
- ✅ Push notifications for geofence alerts
- ✅ Smart geofence suggestions using location clustering

### Story 3.3: SOS Emergency System
- ✅ One-tap SOS button
- ✅ Emergency alerts with location
- ✅ Parent notification via push, email, and SMS
- ✅ Rate limiting to prevent abuse

### Story 5.2: Screen Time Monitoring
- ✅ App usage tracking
- ✅ Time-based usage analytics
- ✅ Parent dashboard for monitoring
- ✅ Historical usage reports

### Story 5.3: Screen Time Control
- ✅ Daily time limits configuration
- ✅ Automated device locking
- ✅ Parent remote control
- ✅ Emergency override functionality

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Development Guidelines:**
- Follow Flutter/Dart coding standards
- Use ESLint and Prettier for backend code
- Write tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔒 Security & Privacy

- **End-to-End Encryption**: All communication is encrypted
- **Data Privacy**: Minimal data collection with user consent
- **Secure Authentication**: JWT-based authentication with bcrypt hashing
- **GDPR Compliant**: Data handling follows privacy regulations
- **Firebase Security**: Uses Firebase for secure data storage

## 🐛 Bug Reports & Feature Requests

For bug reports and feature requests, please use the [GitHub Issues](https://github.com/your-repo/safekids/issues) page.

## 📞 Support

For technical support or questions:
- Email: support@safekids.com
- Documentation: [Wiki](https://github.com/your-repo/safekids/wiki)
- API Documentation: Available at `/api-docs` endpoint

## 🙏 Acknowledgments

- **Flutter Team** - For the amazing cross-platform framework
- **Firebase** - For providing backend services
- **MongoDB** - For the flexible database solution
- **Agora** - For real-time communication services
- **Mapbox** - For mapping services and geocoding

---

**SafeKids** - Keeping families connected and safe, wherever they are. ❤️