# Story 2.3: Location History & Timeline - API Test Cases

## Setup - Chuẩn bị dữ liệu

### 1. Tạo Test Users
```bash
# Tạo parent
POST http://localhost:3000/api/auth/register
{
  "fullName": "Test Parent",
  "phone": "0912345678",
  "email": "parent@test.com",
  "password": "password123",
  "role": "parent"
}

# Tạo child
POST http://localhost:3000/api/auth/register
{
  "fullName": "Test Child",
  "phone": "0987654321",
  "email": "child@test.com",
  "password": "password123",
  "role": "child",
  "age": 10
}
```

### 2. Link Parent - Child
```bash
POST http://localhost:3000/api/link/request
Authorization: Bearer {parentToken}
{
  "childEmail": "child@test.com"
}

POST http://localhost:3000/api/link/approve
Authorization: Bearer {childToken}
{
  "requestId": "{requestId}"
}
```

### 3. Tạo Sample Location Data
```bash
POST http://localhost:3000/api/location
Authorization: Bearer {childToken}
Content-Type: application/json

{
  "latitude": 21.0285,
  "longitude": 105.8542,
  "accuracy": 5,
  "timestamp": "2025-10-08T08:00:00Z"
}

# Repeat với những vị trí khác khác thời gian
- 2025-10-08T09:00:00Z, lat: 21.0315, lon: 105.8560
- 2025-10-08T10:00:00Z, lat: 21.0345, lon: 105.8580
- 2025-10-08T14:00:00Z, lat: 10.123, lon: 106.456 (khác địa điểm)
```

---

## Test Cases

### ✅ AC 2.3.1: Fetch Location History

#### T1.1: Valid Date Range - 200 Success
```bash
GET http://localhost:3000/api/location/child/{childId}/history?startDate=2025-10-08T00:00:00Z&endDate=2025-10-08T23:59:59Z
Authorization: Bearer {parentToken}
```
**Expected:**
- Status: 200
- Response: { success: true, data: { locations: [...], count: 4 } }
- locations sorted by timestamp DESC

#### T1.2: Default Date Range (Last 24h)
```bash
GET http://localhost:3000/api/location/child/{childId}/history
Authorization: Bearer {parentToken}
```
**Expected:**
- Status: 200
- Default: startDate = 24h ago, endDate = now

#### T1.3: With Limit Parameter
```bash
GET http://localhost:3000/api/location/child/{childId}/history?limit=2
Authorization: Bearer {parentToken}
```
**Expected:**
- Status: 200
- Returns max 2 locations

#### T1.4: Unlinked Parent - 403 Forbidden
```bash
GET http://localhost:3000/api/location/child/{childId}/history
Authorization: Bearer {unauthorizedParentToken}
```
**Expected:**
- Status: 403
- Message: "Bạn không có quyền xem lịch sử vị trí của trẻ này"

#### T1.5: No Authorization - 401 Unauthorized
```bash
GET http://localhost:3000/api/location/child/{childId}/history
# No Authorization header
```
**Expected:**
- Status: 401

#### T1.6: Invalid Date Format - 400 Bad Request (optional)
```bash
GET http://localhost:3000/api/location/child/{childId}/history?startDate=invalid-date
Authorization: Bearer {parentToken}
```
**Expected:**
- Status: 400 or use fallback defaults

#### T1.7: Max Limit Check (> 1000)
```bash
GET http://localhost:3000/api/location/child/{childId}/history?limit=5000
Authorization: Bearer {parentToken}
```
**Expected:**
- Status: 200
- Actual limit: max 1000 (capped)

---

### ✅ AC 2.3.4: Location Stats Calculation

#### T2.1: Stats with Valid Date Range
```bash
GET http://localhost:3000/api/location/child/{childId}/stats?startDate=2025-10-08T00:00:00Z&endDate=2025-10-08T23:59:59Z
Authorization: Bearer {parentToken}
```
**Expected:**
- Status: 200
- Response:
```json
{
  "success": true,
  "data": {
    "totalDistance": 12.34,  // km
    "totalTime": 6.5,        // hours
    "mostVisited": [
      {
        "latitude": 21.0315,
        "longitude": 105.8560,
        "count": 3,
        "address": "Địa điểm"
      },
      {
        "latitude": 10.123,
        "longitude": 106.456,
        "count": 1,
        "address": "Địa điểm"
      }
    ]
  }
}
```

#### T2.2: Stats - Default Last 24h
```bash
GET http://localhost:3000/api/location/child/{childId}/stats
Authorization: Bearer {parentToken}
```
**Expected:**
- Status: 200
- Uses default 24h range

#### T2.3: Stats - Less Than 2 Locations
```bash
# Tạo child mới chỉ có 1 location
GET http://localhost:3000/api/location/child/{newChildId}/stats
Authorization: Bearer {parentToken}
```
**Expected:**
- Status: 200
- Response: { totalDistance: 0, totalTime: 0, mostVisited: [] }

#### T2.4: Stats - Unlinked Parent
```bash
GET http://localhost:3000/api/location/child/{childId}/stats
Authorization: Bearer {unauthorizedParentToken}
```
**Expected:**
- Status: 403

#### T2.5: Verify Clustering (100m radius)
```bash
# Create 10 locations trong vòng 100m
# Expected: Grouped thành 1 cluster với count=10
```

#### T2.6: Verify Haversine Distance Calculation
```
Location 1: (21.0285, 105.8542)
Location 2: (21.0315, 105.8560)
Expected distance ≈ 3.5 km (thực tế phụ thuộc vào kinh độ/vĩ độ)
```

---

## cURL Test Commands

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"parent@test.com","password":"password123"}'
```

### Get History
```bash
curl -X GET "http://localhost:3000/api/location/child/{childId}/history" \
  -H "Authorization: Bearer {token}"
```

### Get History with Date Range
```bash
curl -X GET "http://localhost:3000/api/location/child/{childId}/history?startDate=2025-10-08T00:00:00Z&endDate=2025-10-08T23:59:59Z" \
  -H "Authorization: Bearer {token}"
```

### Get Stats
```bash
curl -X GET "http://localhost:3000/api/location/child/{childId}/stats" \
  -H "Authorization: Bearer {token}"
```

### Get Stats with Date Range
```bash
curl -X GET "http://localhost:3000/api/location/child/{childId}/stats?startDate=2025-10-08T00:00:00Z&endDate=2025-10-08T23:59:59Z" \
  -H "Authorization: Bearer {token}"
```

### Test 403 Unauthorized
```bash
curl -X GET "http://localhost:3000/api/location/child/{childId}/history" \
  -H "Authorization: Bearer {wrongToken}"
```

---

## Manual Test Flow

1. **Register** parent & child
2. **Link** parent-child
3. **Create** 5-10 sample locations tại các thời điểm khác nhau
4. **Get History** - verify locations sorted correctly
5. **Get Stats** - verify distance/time calculated
6. **Filter by date** - verify correct date range
7. **Test unauthorized** - verify 403 error
8. **Test clustering** - verify mostVisited grouping

---

## Expected Response Formats

### Location History Success
```json
{
  "success": true,
  "data": {
    "locations": [
      {
        "_id": "507f1f77bcf86cd799439011",
        "userId": "507f1f77bcf86cd799439012",
        "latitude": 21.0285,
        "longitude": 105.8542,
        "accuracy": 5,
        "timestamp": "2025-10-08T08:00:00Z"
      }
    ],
    "count": 1
  }
}
```

### Stats Success
```json
{
  "success": true,
  "data": {
    "totalDistance": 12.5,
    "totalTime": 8.5,
    "mostVisited": [
      {
        "latitude": 21.0285,
        "longitude": 105.8542,
        "count": 3,
        "address": "Địa điểm"
      }
    ]
  }
}
```

### Error Response
```json
{
  "error": "Bạn không có quyền xem lịch sử vị trí của trẻ này"
}
```
