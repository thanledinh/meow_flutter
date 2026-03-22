# Moew API Reference — Full User Endpoints

> **Base URL:** `http://<SERVER_IP>:3000/api`
> **Auth:** Tất cả endpoint có ghi **(Auth)** cần header `Authorization: Bearer <idToken>`
> **Response format:** Mọi response đều có dạng `{ success, message?, data }`

---

## 1. AUTH — `/api/auth`

### POST `/api/auth/register` (Public)

**Request:**
```json
{
  "displayName": "Nguyễn Văn A",
  "email": "a@gmail.com",
  "password": "123456",
  "confirmPassword": "123456"
}
```

**Response 201:**
```json
{
  "success": true,
  "message": "Đăng ký thành công! 🎉",
  "data": {
    "user": {
      "id": "firebase_uid_abc123",
      "email": "a@gmail.com",
      "displayName": "Nguyễn Văn A",
      "avatar": null,
      "bio": null,
      "phone": null,
      "createdAt": "2026-03-22T09:00:00.000Z",
      "updatedAt": "2026-03-22T09:00:00.000Z"
    },
    "token": "eyJhbGciOiJSUzI1NiIs...",
    "refreshToken": "AMf-vBx..."
  }
}
```

---

### POST `/api/auth/login` (Public)

**Request:**
```json
{
  "email": "a@gmail.com",
  "password": "123456"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Đăng nhập thành công! 🎉",
  "data": {
    "user": {
      "id": "firebase_uid_abc123",
      "email": "a@gmail.com",
      "displayName": "Nguyễn Văn A",
      "avatar": "/uploads/avatars/abc-123.jpg",
      "bio": "Yêu mèo",
      "phone": "0912345678",
      "dateOfBirth": "2000-01-15T00:00:00.000Z",
      "gender": "male",
      "address": "123 Nguyễn Huệ",
      "ward": "Bến Nghé",
      "district": "Quận 1",
      "city": "Hồ Chí Minh",
      "emergencyContact": "0987654321",
      "emergencyName": "Mẹ",
      "facebook": null,
      "zalo": "0912345678",
      "createdAt": "2026-03-20T10:00:00.000Z",
      "updatedAt": "2026-03-22T09:00:00.000Z"
    },
    "token": "eyJhbGciOiJSUzI1NiIs...",
    "refreshToken": "AMf-vBx...",
    "expiresIn": "3600"
  }
}
```

---

### POST `/api/auth/logout` (Auth)

**Response 200:**
```json
{
  "success": true,
  "message": "Đăng xuất thành công",
  "data": null
}
```

---

### POST `/api/auth/change-password` (Auth)

**Request:**
```json
{
  "currentPassword": "123456",
  "newPassword": "654321",
  "confirmNewPassword": "654321"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Đổi mật khẩu thành công! Vui lòng đăng nhập lại",
  "data": null
}
```

---

### POST `/api/auth/refresh-token` (Public)

**Request:**
```json
{
  "refreshToken": "AMf-vBx..."
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Làm mới token thành công",
  "data": {
    "token": "eyJhbGciOiJSUzI1NiIs...",
    "refreshToken": "AMf-vBx-NEW...",
    "expiresIn": "3600"
  }
}
```

---

### POST `/api/auth/forgot-password` (Public)

**Request:**
```json
{
  "email": "a@gmail.com"
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Đã gửi email khôi phục mật khẩu, vui lòng kiểm tra hộp thư 📧",
  "data": { "email": "a@gmail.com" }
}
```

---

### GET `/api/auth/profile` (Auth)

**Response 200:**
```json
{
  "success": true,
  "message": "Thông tin cá nhân",
  "data": {
    "id": "firebase_uid_abc123",
    "email": "a@gmail.com",
    "displayName": "Nguyễn Văn A",
    "avatar": "/uploads/avatars/abc-123.jpg",
    "bio": "Yêu mèo",
    "phone": "0912345678",
    "dateOfBirth": "2000-01-15T00:00:00.000Z",
    "gender": "male",
    "address": "123 Nguyễn Huệ",
    "ward": "Bến Nghé",
    "district": "Quận 1",
    "city": "Hồ Chí Minh",
    "emergencyContact": "0987654321",
    "emergencyName": "Mẹ",
    "facebook": null,
    "zalo": "0912345678",
    "createdAt": "2026-03-20T10:00:00.000Z",
    "updatedAt": "2026-03-22T09:00:00.000Z",
    "petCount": 2
  }
}
```

---

### PUT `/api/auth/profile` (Auth)

**Request** (gửi field nào update field đó):
```json
{
  "displayName": "Trần Văn B",
  "bio": "Cat lover",
  "phone": "0912345678",
  "dateOfBirth": "2000-01-15",
  "gender": "male",
  "address": "456 Lê Lợi",
  "ward": "Bến Thành",
  "district": "Quận 1",
  "city": "Hồ Chí Minh",
  "emergencyContact": "0987654321",
  "emergencyName": "Mẹ",
  "facebook": "fb.com/abc",
  "zalo": "0912345678"
}
```

> **Validation:** `gender` ∈ `["male", "female", "other"]`, `phone` phải đúng regex `^(0|\+84)[0-9]{9,10}$`

**Response 200:**
```json
{
  "success": true,
  "message": "Cập nhật thông tin thành công ✅",
  "data": {
    "id": "firebase_uid_abc123",
    "email": "a@gmail.com",
    "displayName": "Trần Văn B",
    "avatar": "/uploads/avatars/abc-123.jpg",
    "bio": "Cat lover",
    "phone": "0912345678",
    "dateOfBirth": "2000-01-15T00:00:00.000Z",
    "gender": "male",
    "address": "456 Lê Lợi",
    "ward": "Bến Thành",
    "district": "Quận 1",
    "city": "Hồ Chí Minh",
    "emergencyContact": "0987654321",
    "emergencyName": "Mẹ",
    "facebook": "fb.com/abc",
    "zalo": "0912345678",
    "updatedAt": "2026-03-22T10:00:00.000Z"
  }
}
```

---

### POST `/api/auth/avatar` (Auth)

**Request:**
```json
{
  "image": "data:image/png;base64,iVBORw0KGgo..."
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Cập nhật avatar thành công 🖼️",
  "data": {
    "id": "firebase_uid_abc123",
    "avatar": "/uploads/avatars/firebase_uid-1711100000000.png"
  }
}
```

---

### GET `/api/auth/sessions` (Auth)

**Response 200:**
```json
{
  "success": true,
  "message": "2 phiên đăng nhập đang hoạt động",
  "data": [
    {
      "id": 1,
      "ipAddress": "192.168.1.10",
      "userAgent": "Mozilla/5.0...",
      "createdAt": "2026-03-22T08:00:00.000Z",
      "expiresAt": "2026-04-21T08:00:00.000Z"
    }
  ]
}
```

---

### POST `/api/auth/device-token` (Auth)

**Request:**
```json
{
  "token": "ExponentPushToken[xxxx]",
  "platform": "android"
}
```

**Response 200:**
```json
{ "success": true, "message": "Device token đã lưu" }
```

---

### POST `/api/auth/ekyc` (Auth)

**Request:**
```json
{
  "idCardNumber": "079200012345",
  "idCardName": "NGUYEN VAN A",
  "idCardFront": "https://storage.example.com/front.jpg",
  "idCardBack": "https://storage.example.com/back.jpg"
}
```

**Response 200:**
```json
{ "success": true, "message": "Xác minh danh tính thành công!" }
```

---

### GET `/api/auth/ekyc/status` (Auth)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "isVerified": true,
    "idCardName": "NGUYEN VAN A",
    "hasIdCard": true
  }
}
```

---

## 2. PET — `/api/pets` (Auth)

### GET `/api/pets`

**Response 200:**
```json
{
  "success": true,
  "message": "Tìm thấy 2 pet",
  "data": [
    {
      "id": 1,
      "ownerId": "firebase_uid_abc123",
      "name": "Miu",
      "species": "cat",
      "breed": "Munchkin",
      "gender": "female",
      "color": "Trắng cam",
      "features": "Chân ngắn, mắt xanh",
      "birthDate": "2024-06-15T00:00:00.000Z",
      "weight": 3.5,
      "avatar": "https://storage.example.com/pets/miu.jpg",
      "notes": "Hay nhõng nhẽo",
      "createdAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-03-22T10:00:00.000Z"
    }
  ]
}
```

---

### GET `/api/pets/:id`

**Response 200:**
```json
{
  "success": true,
  "message": "Lấy thông tin pet thành công",
  "data": {
    "id": 1,
    "ownerId": "firebase_uid_abc123",
    "name": "Miu",
    "species": "cat",
    "breed": "Munchkin",
    "gender": "female",
    "color": "Trắng cam",
    "features": "Chân ngắn, mắt xanh",
    "birthDate": "2024-06-15T00:00:00.000Z",
    "weight": 3.5,
    "avatar": "https://storage.example.com/pets/miu.jpg",
    "notes": "Hay nhõng nhẽo",
    "createdAt": "2026-01-01T00:00:00.000Z",
    "updatedAt": "2026-03-22T10:00:00.000Z"
  }
}
```

---

### POST `/api/pets`

**Request:**
```json
{
  "name": "Miu",
  "breed": "Munchkin",
  "gender": "female",
  "color": "Trắng cam",
  "features": "Chân ngắn",
  "birthDate": "2024-06-15",
  "weight": 3.5,
  "avatar": "https://storage.example.com/pets/miu.jpg",
  "notes": "Hay nhõng nhẽo"
}
```

> **Validation:** `name` bắt buộc, `gender` ∈ `["male", "female"]`

**Response 201:** (trả về object pet đã tạo — giống GET /:id)

---

### PUT `/api/pets/:id`

**Request** (gửi field nào update field đó):
```json
{
  "name": "Miu Miu",
  "weight": 4.0
}
```

**Response 200:** (trả về object pet đã update)

---

### DELETE `/api/pets/:id`

**Response 200:**
```json
{
  "success": true,
  "message": "Đã xóa pet thành công",
  "data": { "id": 1 }
}
```

---

### POST `/api/pets/:id/avatar` (Multipart)

**Request:** `Content-Type: multipart/form-data`, field name = `image`

**Response 200:** (trả về object pet với avatar mới)

---

### POST `/api/pets/:id/avatar-base64`

**Request:**
```json
{
  "image": "data:image/png;base64,iVBORw0KGgo..."
}
```

**Response 200:** (trả về object pet với avatar mới)

---

## 3. MEDICAL RECORDS — `/api/pets/:petId/medical` (Auth)

### GET `/api/pets/:petId/medical`

**Response 200:**
```json
{
  "success": true,
  "message": "3 hồ sơ bệnh",
  "data": [
    {
      "id": 10,
      "petId": 1,
      "relatedId": null,
      "type": "illness",
      "name": "Viêm đường hô hấp",
      "symptoms": "Ho, sổ mũi, bỏ ăn",
      "diagnosis": "Viêm phế quản cấp",
      "treatment": "Kháng sinh Amoxicillin 5 ngày",
      "startDate": "2026-03-15T00:00:00.000Z",
      "endDate": "2026-03-20T00:00:00.000Z",
      "status": "recovered",
      "veterinarian": "BS. Nguyễn Minh",
      "clinic": "PetCare Quận 1",
      "cost": 850000,
      "notes": "Tái khám sau 1 tuần",
      "createdAt": "2026-03-15T08:00:00.000Z",
      "updatedAt": "2026-03-20T10:00:00.000Z",
      "relatedFrom": null,
      "relapses": [],
      "costItems": [
        {
          "id": 1,
          "type": "consultation",
          "description": "Phí khám",
          "amount": 200000,
          "isPaid": true,
          "date": "2026-03-15T00:00:00.000Z",
          "notes": null
        }
      ]
    }
  ]
}
```

> **`type`** ∈ `["illness", "allergy", "chronic", "injury"]`
> **`status`** ∈ `["ongoing", "recovered", "chronic"]`

---

### POST `/api/pets/:petId/medical`

**Request:**
```json
{
  "type": "illness",
  "name": "Viêm đường hô hấp",
  "symptoms": "Ho, sổ mũi, bỏ ăn",
  "diagnosis": "Viêm phế quản cấp",
  "treatment": "Kháng sinh Amoxicillin 5 ngày",
  "startDate": "2026-03-15",
  "endDate": "2026-03-20",
  "status": "recovered",
  "veterinarian": "BS. Nguyễn Minh",
  "clinic": "PetCare Quận 1",
  "cost": 850000,
  "notes": "Tái khám sau 1 tuần",
  "relatedId": null
}
```

> **Bắt buộc:** `type`, `name`, `startDate`

**Response 201:** (trả về object medical record)

---

### PUT `/api/pets/:petId/medical/:id`

**Request** (gửi field nào update field đó):
```json
{
  "status": "recovered",
  "endDate": "2026-03-20"
}
```

---

### DELETE `/api/pets/:petId/medical/:id`

**Response 200:**
```json
{ "success": true, "message": "Đã xóa hồ sơ bệnh", "data": { "id": 10 } }
```

---

## 4. VACCINATIONS — `/api/pets/:petId/vaccinations` (Auth)

### GET `/api/pets/:petId/vaccinations`

**Response 200:**
```json
{
  "success": true,
  "message": "2 lần tiêm phòng",
  "data": [
    {
      "id": 5,
      "petId": 1,
      "relatedId": null,
      "vaccineName": "FVRCP (3 trong 1)",
      "dose": 2,
      "date": "2026-02-01T00:00:00.000Z",
      "nextDoseDate": "2026-05-01T00:00:00.000Z",
      "veterinarian": "BS. Trần Hùng",
      "clinic": "PetCare Quận 7",
      "batchNumber": "LOT-2026-001",
      "cost": 350000,
      "notes": "Mũi 2, mũi 3 sau 3 tháng",
      "createdAt": "2026-02-01T09:00:00.000Z",
      "updatedAt": "2026-02-01T09:00:00.000Z",
      "relatedFrom": null,
      "followUps": [],
      "costItems": []
    }
  ]
}
```

---

### POST `/api/pets/:petId/vaccinations`

**Request:**
```json
{
  "vaccineName": "FVRCP (3 trong 1)",
  "dose": 2,
  "date": "2026-02-01",
  "nextDoseDate": "2026-05-01",
  "veterinarian": "BS. Trần Hùng",
  "clinic": "PetCare Quận 7",
  "batchNumber": "LOT-2026-001",
  "cost": 350000,
  "notes": "Mũi 2",
  "relatedId": null
}
```

> **Bắt buộc:** `vaccineName`, `date`

**Response 201:** (trả về object vaccination)

---

### PUT `/api/pets/:petId/vaccinations/:id`

**Request** (gửi field nào update field đó):
```json
{ "nextDoseDate": "2026-06-01", "notes": "Đã hoãn lịch" }
```

---

### DELETE `/api/pets/:petId/vaccinations/:id`

**Response 200:**
```json
{ "success": true, "message": "Đã xóa lần tiêm phòng", "data": { "id": 5 } }
```

---

## 5. APPOINTMENTS — `/api/pets/:petId/appointments` (Auth)

### GET `/api/pets/:petId/appointments`

**Query params:** `?status=upcoming` (optional, ∈ `["upcoming", "completed", "cancelled"]`)

**Response 200:**
```json
{
  "success": true,
  "message": "1 lịch khám",
  "data": [
    {
      "id": 3,
      "petId": 1,
      "relatedId": null,
      "title": "Khám tổng quát định kỳ",
      "date": "2026-04-01T09:00:00.000Z",
      "clinic": "PetCare Quận 1",
      "veterinarian": "BS. Nguyễn Minh",
      "reason": "Tổng quát 6 tháng",
      "status": "upcoming",
      "cost": null,
      "notes": "Nhớ nhịn ăn sáng",
      "createdAt": "2026-03-20T08:00:00.000Z",
      "updatedAt": "2026-03-20T08:00:00.000Z",
      "relatedFrom": null,
      "followUps": [],
      "costItems": []
    }
  ]
}
```

---

### POST `/api/pets/:petId/appointments`

**Request:**
```json
{
  "title": "Khám tổng quát định kỳ",
  "date": "2026-04-01T09:00:00.000Z",
  "clinic": "PetCare Quận 1",
  "veterinarian": "BS. Nguyễn Minh",
  "reason": "Tổng quát 6 tháng",
  "status": "upcoming",
  "cost": null,
  "notes": "Nhớ nhịn ăn sáng",
  "relatedId": null
}
```

> **Bắt buộc:** `title`, `date`

---

### PUT `/api/pets/:petId/appointments/:id` & DELETE `/api/pets/:petId/appointments/:id`

Tương tự pattern medical records.

---

## 6. COST ITEMS — `/api/pets/:petId/:entityType/:entityId/costs` (Auth)

> `entityType` ∈ `["medical", "vaccination", "appointment"]`

### GET `/api/pets/:petId/medical/:entityId/costs`

**Response 200:**
```json
{
  "success": true,
  "message": "3 khoản chi phí",
  "data": {
    "items": [
      {
        "id": 1,
        "medicalRecordId": 10,
        "vaccinationId": null,
        "appointmentId": null,
        "type": "consultation",
        "description": "Phí khám bệnh",
        "amount": 200000,
        "isPaid": true,
        "date": "2026-03-15T00:00:00.000Z",
        "notes": null,
        "createdAt": "2026-03-15T08:30:00.000Z"
      },
      {
        "id": 2,
        "medicalRecordId": 10,
        "vaccinationId": null,
        "appointmentId": null,
        "type": "medication",
        "description": "Amoxicillin 500mg x 10 viên",
        "amount": 150000,
        "isPaid": true,
        "date": "2026-03-15T00:00:00.000Z",
        "notes": null,
        "createdAt": "2026-03-15T08:31:00.000Z"
      },
      {
        "id": 3,
        "medicalRecordId": 10,
        "vaccinationId": null,
        "appointmentId": null,
        "type": "lab",
        "description": "Xét nghiệm máu",
        "amount": 500000,
        "isPaid": false,
        "date": "2026-03-15T00:00:00.000Z",
        "notes": "Chờ kết quả",
        "createdAt": "2026-03-15T08:32:00.000Z"
      }
    ],
    "summary": {
      "totalCost": 850000,
      "totalPaid": 350000,
      "unpaid": 500000,
      "itemCount": 3
    }
  }
}
```

> **`type`** ∈ `["consultation", "medication", "lab", "surgery", "vaccine", "additional", "other"]`

---

### POST `/api/pets/:petId/medical/:entityId/costs`

**Request:**
```json
{
  "type": "medication",
  "description": "Amoxicillin 500mg x 10 viên",
  "amount": 150000,
  "isPaid": true,
  "date": "2026-03-15",
  "notes": null
}
```

> **Bắt buộc:** `type`, `description`, `amount`

**Response 201:**
```json
{
  "success": true,
  "message": "Thêm chi phí: Amoxicillin 500mg x 10 viên - 150.000đ",
  "data": { "id": 2, "type": "medication", "description": "Amoxicillin 500mg x 10 viên", "amount": 150000, "isPaid": true, "date": "2026-03-15T00:00:00.000Z", "notes": null }
}
```

---

### PUT `/api/pets/:petId/medical/:entityId/costs/:costId`

### DELETE `/api/pets/:petId/medical/:entityId/costs/:costId`

Pattern tương tự.

---

## 7. CLINICS — `/api/clinics`

### GET `/api/clinics/nearby` (Public)

**Query:** `?lat=10.7769&lng=106.7009&radius=10&sort=distance&page=1&limit=20`

> `sort` ∈ `["distance", "rating", "price"]`

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "PetCare Quận 1",
      "slug": "petcare-quan-1-1711100000000",
      "description": "Phòng khám thú y uy tín 10 năm",
      "address": "123 Nguyễn Huệ, Q1, HCM",
      "district": "Quận 1",
      "city": "Hồ Chí Minh",
      "latitude": 10.7769,
      "longitude": 106.7009,
      "phone": "028-1234-5678",
      "avatar": "https://storage.example.com/clinics/petcare.jpg",
      "openHours": {
        "mon": "08:00-20:00",
        "tue": "08:00-20:00",
        "wed": "08:00-20:00",
        "thu": "08:00-20:00",
        "fri": "08:00-20:00",
        "sat": "09:00-17:00",
        "sun": "closed"
      },
      "priceRange": "200K-500K",
      "rating": 4.8,
      "reviewCount": 120,
      "isVerified": true,
      "distance": 1.25
    }
  ]
}
```

---

### GET `/api/clinics` (Public)

**Query:** `?search=petcare&district=Quận 1&city=Hồ Chí Minh&sort=rating&page=1&limit=20`

> `sort` ∈ `["rating", "name", "newest"]`

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "PetCare Quận 1",
      "slug": "petcare-quan-1-1711100000000",
      "address": "123 Nguyễn Huệ",
      "district": "Quận 1",
      "city": "Hồ Chí Minh",
      "latitude": 10.7769,
      "longitude": 106.7009,
      "phone": "028-1234-5678",
      "avatar": "https://storage.example.com/clinics/petcare.jpg",
      "openHours": { "mon": "08:00-20:00" },
      "images": ["https://img1.jpg", "https://img2.jpg"],
      "priceRange": "200K-500K",
      "rating": 4.8,
      "reviewCount": 120,
      "isVerified": true,
      "isActive": true,
      "services": [
        { "id": 1, "name": "Khám tổng quát", "category": "checkup", "price": 200000 }
      ]
    }
  ],
  "pagination": { "total": 50, "page": 1, "limit": 20, "totalPages": 3 }
}
```

---

### GET `/api/clinics/:id` (Public)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "PetCare Quận 1",
    "slug": "petcare-quan-1-1711100000000",
    "description": "Phòng khám thú y uy tín 10 năm",
    "address": "123 Nguyễn Huệ, Q1, HCM",
    "district": "Quận 1",
    "city": "Hồ Chí Minh",
    "latitude": 10.7769,
    "longitude": 106.7009,
    "phone": "028-1234-5678",
    "email": "contact@petcare.vn",
    "website": "https://petcare.vn",
    "avatar": "https://storage.example.com/clinics/petcare.jpg",
    "openHours": { "mon": "08:00-20:00", "sat": "09:00-17:00", "sun": "closed" },
    "images": ["https://img1.jpg"],
    "priceRange": "200K-500K",
    "rating": 4.8,
    "reviewCount": 120,
    "isVerified": true,
    "services": [
      {
        "id": 1, "name": "Khám tổng quát", "category": "checkup",
        "price": 200000, "priceMax": 350000, "duration": 30,
        "description": "Khám sức khỏe tổng quát", "isActive": true
      }
    ],
    "reviews": [
      {
        "id": 1, "userId": "uid_xyz", "clinicId": 1,
        "rating": 5, "comment": "Bác sĩ tận tâm!",
        "images": ["https://review-img.jpg"],
        "createdAt": "2026-03-20T10:00:00.000Z",
        "user": { "displayName": "Chị Lan", "avatar": "/uploads/avatars/lan.jpg" }
      }
    ]
  }
}
```

---

### GET `/api/clinics/:id/reviews` (Public)

**Query:** `?page=1&limit=20`

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1, "userId": "uid_xyz", "clinicId": 1,
      "rating": 5, "comment": "Bác sĩ tận tâm!",
      "images": ["https://review-img.jpg"],
      "createdAt": "2026-03-20T10:00:00.000Z",
      "user": { "displayName": "Chị Lan", "avatar": "/uploads/avatars/lan.jpg" }
    }
  ],
  "pagination": { "total": 120, "page": 1, "limit": 20, "totalPages": 6 }
}
```

---

### POST `/api/clinics/:id/reviews` (Auth)

**Request:**
```json
{
  "rating": 5,
  "comment": "Bác sĩ tận tâm, dịch vụ tốt!",
  "images": ["https://img1.jpg", "https://img2.jpg"]
}
```

> **Validation:** `rating` bắt buộc, 1–5. Nếu đã review → tự update.

**Response 201:**
```json
{
  "success": true,
  "message": "Đã gửi đánh giá",
  "data": {
    "id": 15, "userId": "uid_abc", "clinicId": 1,
    "rating": 5, "comment": "Bác sĩ tận tâm, dịch vụ tốt!",
    "images": "[\"https://img1.jpg\"]",
    "createdAt": "2026-03-22T10:00:00.000Z"
  }
}
```

---

## 8. BOOKINGS — `/api/clinics/:id/book` & `/api/bookings`

### POST `/api/clinics/:id/book` (Auth)

**Request:**
```json
{
  "petId": 1,
  "serviceType": "checkup",
  "date": "2026-04-01",
  "timeSlot": "09:00",
  "notes": "Khám tổng quát"
}
```

> **Bắt buộc:** `petId`, `serviceType`, `date`

**Response 201:**
```json
{
  "success": true,
  "message": "Đặt lịch thành công!",
  "data": {
    "id": 7,
    "userId": "firebase_uid_abc123",
    "clinicId": 1,
    "petId": 1,
    "serviceType": "checkup",
    "date": "2026-04-01T00:00:00.000Z",
    "timeSlot": "09:00",
    "status": "pending",
    "notes": "Khám tổng quát",
    "totalCost": null,
    "cancelReason": null,
    "createdAt": "2026-03-22T10:00:00.000Z",
    "clinic": { "name": "PetCare Quận 1", "address": "123 Nguyễn Huệ", "phone": "028-1234-5678" },
    "pet": { "name": "Miu" }
  }
}
```

---

### GET `/api/bookings` (Auth)

**Query:** `?status=pending&page=1&limit=20`

> `status` ∈ `["pending", "confirmed", "completed", "cancelled"]`

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 7,
      "userId": "firebase_uid_abc123",
      "clinicId": 1,
      "petId": 1,
      "serviceType": "checkup",
      "date": "2026-04-01T00:00:00.000Z",
      "timeSlot": "09:00",
      "status": "pending",
      "notes": "Khám tổng quát",
      "totalCost": null,
      "cancelReason": null,
      "createdAt": "2026-03-22T10:00:00.000Z",
      "clinic": {
        "id": 1, "name": "PetCare Quận 1", "address": "123 Nguyễn Huệ",
        "phone": "028-1234-5678", "avatar": "https://img.jpg"
      },
      "pet": { "id": 1, "name": "Miu", "avatar": "https://pet.jpg" }
    }
  ],
  "pagination": { "total": 5, "page": 1, "limit": 20, "totalPages": 1 }
}
```

---

### PUT `/api/bookings/:id/cancel` (Auth)

**Request:**
```json
{ "reason": "Bận việc đột xuất" }
```

**Response 200:**
```json
{
  "success": true,
  "message": "Đã hủy lịch hẹn",
  "data": {
    "id": 7, "status": "cancelled", "cancelReason": "Bận việc đột xuất"
  }
}
```

---

## 9. SOS — `/api/sos` (Auth)

### POST `/api/sos/trigger`

**Request:**
```json
{
  "petId": 1,
  "description": "Mèo bị nôn liên tục, bỏ ăn 2 ngày",
  "latitude": 10.7769,
  "longitude": 106.7009
}
```

> **Bắt buộc:** `petId`, `latitude`, `longitude`

**Response 201:**
```json
{
  "success": true,
  "message": "SOS đã được gửi đi! Đang quét phòng khám...",
  "data": {
    "sosId": 15,
    "aiSummary": "🔴 Nguy hiểm — Nghi ngờ ngộ độc hoặc tắc ruột. Sơ cứu: giữ mèo ấm, không cho ăn thêm. Cần tới phòng khám ngay để siêu âm bụng và xét nghiệm máu.",
    "clinicsNotified": 3,
    "radius": 5,
    "status": "searching",
    "expandSchedule": "5km ngay → 10km (10s) → 15km (20s) → lặp 15km mỗi 15s"
  }
}
```

**Socket events nhận được (real-time):**
- `sos:wave` — `{ sosId, wave, radius, clinicsNotified, repeat? }`
- `sos:matched` — `{ sosId, clinic: {...}, bookingId }`

---

### POST `/api/sos/:id/cancel`

**Response 200:**
```json
{ "success": true, "message": "Đã hủy SOS" }
```

---

### GET `/api/sos`

**Response 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 15,
      "userId": "firebase_uid_abc123",
      "petId": 1,
      "description": "Mèo bị nôn liên tục",
      "aiSummary": "🔴 Nguy hiểm...",
      "latitude": 10.7769,
      "longitude": 106.7009,
      "radius": 15,
      "status": "completed",
      "clinicsNotified": 8,
      "acceptedClinicId": 1,
      "acceptedAt": "2026-03-22T09:05:00.000Z",
      "totalCost": 1500000,
      "paidByWallet": true,
      "bookingId": 12,
      "expiresAt": "2026-03-22T09:10:00.000Z",
      "createdAt": "2026-03-22T09:00:00.000Z",
      "pet": { "name": "Miu", "species": "cat" },
      "clinic": { "id": 1, "name": "PetCare Quận 1", "phone": "028-1234-5678" }
    }
  ]
}
```

> **`status`** ∈ `["searching", "accepted", "completed", "cancelled", "expired"]`

---

### POST `/api/sos/:id/accept` (Clinic)

**Request:**
```json
{ "clinicId": 1 }
```

**Response 200:**
```json
{
  "success": true,
  "message": "Đã nhận ca cấp cứu!",
  "data": {
    "sos": { "id": 15, "status": "accepted", "acceptedClinicId": 1 },
    "booking": { "id": 12, "status": "confirmed", "serviceType": "emergency" }
  }
}
```

---

### POST `/api/sos/:id/complete` (Clinic)

**Request:**
```json
{
  "totalCost": 1500000,
  "payByWallet": true
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Ca cấp cứu hoàn thành!",
  "data": { "id": 15, "status": "completed", "totalCost": 1500000, "paidByWallet": true }
}
```

---

## 10. WALLET — `/api/wallet` (Auth)

### GET `/api/wallet`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "balance": 500000,
    "debt": 0,
    "isVerified": true,
    "transactions": [
      {
        "id": 1,
        "userId": "firebase_uid_abc123",
        "amount": 1000000,
        "type": "topup",
        "ref": null,
        "note": "Nạp tiền vào ví",
        "createdAt": "2026-03-20T08:00:00.000Z"
      },
      {
        "id": 2,
        "userId": "firebase_uid_abc123",
        "amount": 500000,
        "type": "debit",
        "ref": "sos:15",
        "note": "Thanh toán cấp cứu",
        "createdAt": "2026-03-22T09:10:00.000Z"
      }
    ]
  }
}
```

> **`type`** ∈ `["topup", "debit", "debt", "repay"]`

---

### POST `/api/wallet/topup`

**Request:**
```json
{ "amount": 500000 }
```

**Response 200:**
```json
{ "success": true, "message": "Đã nạp 500.000đ" }
```

---

### POST `/api/wallet/repay`

**Request:**
```json
{ "amount": 200000 }
```

**Response 200:**
```json
{ "success": true, "message": "Đã trả 200.000đ" }
```

---

## 11. AI — `/api/ai` (Auth)

### POST `/api/ai/analyze-food`

**Request:**
```json
{
  "image": "data:image/jpeg;base64,/9j/4AAQSkZ...",
  "petId": 1,
  "mealTime": "morning",
  "notes": "Thức ăn hạt mới mua"
}
```

> **Bắt buộc:** `image` (base64), `petId`

**Response 201:**
```json
{
  "success": true,
  "message": "Đã phân tích: Royal Canin Indoor 🍗",
  "data": {
    "id": 8,
    "petId": 1,
    "userId": "firebase_uid_abc123",
    "source": "ai",
    "imageUrl": "/uploads/food/1-1711100000000.jpg",
    "foodName": "Royal Canin Indoor",
    "estimatedCalories": 375,
    "suitabilityScore": 7.5,
    "goodIngredients": ["Protein gia cầm đã khử nước", "Chất xơ thực vật"],
    "badIngredients": ["Ngũ cốc (bột mì, bắp)", "Chất bảo quản BHA"],
    "aiAdvice": "Thức ăn phù hợp cho mèo indoor. Tuy nhiên, hàm lượng ngũ cốc khá cao. Cho ăn 50-60g/ngày chia 2 bữa. Nên bổ sung thêm pate hoặc thịt tươi.",
    "mealTime": "morning",
    "notes": "Thức ăn hạt mới mua",
    "createdAt": "2026-03-22T10:00:00.000Z"
  }
}
```

---

### POST `/api/ai/chat/start`

**Request:**
```json
{
  "petId": 1,
  "foodLogId": 8
}
```

> **Bắt buộc:** `petId`. `foodLogId` là optional (nếu muốn chat về kết quả phân tích thức ăn).

**Response 201:**
```json
{
  "success": true,
  "message": "Đã tạo phiên chat",
  "data": {
    "sessionId": 5,
    "title": "Chat: Royal Canin Indoor",
    "greeting": "Chào bạn! 🐱 Mình đã xem kết quả phân tích \"Royal Canin Indoor\" cho Miu. Bạn muốn hỏi thêm gì về món này không?"
  }
}
```

---

### POST `/api/ai/chat/:sessionId/send`

**Request:**
```json
{ "message": "Cho bé ăn bao nhiêu gram mỗi ngày?" }
```

**Response 200:**
```json
{
  "success": true,
  "message": "OK",
  "data": {
    "role": "assistant",
    "content": "Với Miu nặng 3.5kg, mình khuyên cho ăn khoảng 50-55g/ngày chia 2 bữa sáng tối nhé! 🐱",
    "tokens": 285
  }
}
```

---

### GET `/api/ai/chat/:sessionId`

**Response 200:**
```json
{
  "success": true,
  "data": {
    "id": 5,
    "title": "Chat: Royal Canin Indoor",
    "petName": "Miu",
    "foodLog": { "foodName": "Royal Canin Indoor", "suitabilityScore": 7.5 },
    "messages": [
      { "role": "assistant", "content": "Chào bạn! 🐱...", "createdAt": "2026-03-22T10:00:00.000Z" },
      { "role": "user", "content": "Cho bé ăn bao nhiêu gram?", "createdAt": "2026-03-22T10:01:00.000Z" },
      { "role": "assistant", "content": "Với Miu nặng 3.5kg...", "createdAt": "2026-03-22T10:01:05.000Z" }
    ]
  }
}
```

---

## 12. FOOD LOGS — `/api/pets/:petId/food-*` (Auth)

### GET `/api/pets/:petId/food-history`

**Query:** `?date=2026-03-22` hoặc `?from=2026-03-01&to=2026-03-31`

**Response 200:**
```json
{
  "success": true,
  "message": "3 bữa ăn",
  "data": {
    "totalCalories": 825,
    "mealCount": 3,
    "meals": [
      {
        "id": 8,
        "petId": 1,
        "userId": "firebase_uid_abc123",
        "source": "ai",
        "imageUrl": "/uploads/food/1-1711100000.jpg",
        "foodName": "Royal Canin Indoor",
        "estimatedCalories": 375,
        "suitabilityScore": 7.5,
        "goodIngredients": ["Protein gia cầm"],
        "badIngredients": ["Ngũ cốc"],
        "aiAdvice": "Phù hợp cho mèo indoor...",
        "mealTime": "morning",
        "notes": null,
        "createdAt": "2026-03-22T07:00:00.000Z"
      },
      {
        "id": 9,
        "petId": 1,
        "userId": "firebase_uid_abc123",
        "source": "manual",
        "imageUrl": null,
        "foodName": "Pate Whiskas",
        "estimatedCalories": 450,
        "suitabilityScore": null,
        "goodIngredients": [],
        "badIngredients": [],
        "aiAdvice": null,
        "mealTime": "evening",
        "notes": "1/2 hộp",
        "createdAt": "2026-03-22T18:00:00.000Z"
      }
    ]
  }
}
```

---

### POST `/api/pets/:petId/food-logs`

**Request:**
```json
{
  "foodName": "Pate Whiskas",
  "calories": 450,
  "mealTime": "evening",
  "notes": "1/2 hộp"
}
```

> **Bắt buộc:** `foodName`

**Response 201:**
```json
{ "success": true, "message": "Đã ghi: Pate Whiskas", "data": { "id": 9, "..." : "..." } }
```

---

### DELETE `/api/pets/:petId/food-logs/:id`

**Response 200:**
```json
{ "success": true, "message": "Đã xóa bản ghi", "data": { "id": 9 } }
```

---

## 13. NOTIFICATIONS — `/api/notifications` (Auth)

### POST `/api/notifications/token`

**Request:**
```json
{
  "fcmToken": "ExponentPushToken[xxxxx]",
  "platform": "android",
  "deviceName": "Samsung Galaxy S24"
}
```

> Cũng hỗ trợ field name `token` thay cho `fcmToken`

**Response 200:**
```json
{ "success": true, "message": "Đã lưu token", "data": { "token": "ExponentPushToken[xxxxx]" } }
```

---

### POST `/api/notifications/test`

**Response 200:**
```json
{ "success": true, "message": "Đã gửi test notification", "data": { "..." : "..." } }
```

---

## 14. UPLOAD — `/api/upload` (Auth)

### POST `/api/upload/image` (Multipart)

**Request:** `Content-Type: multipart/form-data`, field = `image`, query `?folder=uploads`

> `folder` ∈ `["uploads", "avatars", "pets", "medical"]`
> Max 5MB, chỉ JPG/PNG/WebP/GIF

**Response 201:**
```json
{
  "success": true,
  "message": "Upload ảnh thành công",
  "data": {
    "url": "https://storage.googleapis.com/bucket/uploads/abc-123.jpg",
    "filePath": "uploads/abc-123.jpg"
  }
}
```

---

## Error Response Format

Tất cả lỗi đều trả về cùng format:

```json
{
  "success": false,
  "message": "Mô tả lỗi bằng tiếng Việt",
  "code": "ERROR_CODE"
}
```

**Common error codes:**
| Code | HTTP | Mô tả |
|------|------|-------|
| `MISSING_FIELDS` | 400 | Thiếu field bắt buộc |
| `INVALID_EMAIL` | 400 | Email sai format |
| `WEAK_PASSWORD` | 400 | Mật khẩu < 6 ký tự |
| `EMAIL_EXISTS` | 409 | Email đã đăng ký |
| `EMAIL_NOT_FOUND` | 401 | Email chưa đăng ký |
| `INVALID_PASSWORD` | 401 | Sai mật khẩu |
| `PET_NOT_FOUND` | 404 | Pet không tồn tại hoặc không thuộc user |
| `UNAUTHORIZED` | 401 | Token không hợp lệ / hết hạn |
| `IP_MISMATCH` | 401 | Refresh token từ IP khác |
