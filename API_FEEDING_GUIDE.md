# API Guide — AI Nutritionist & Feeding System

> Base URL: `http://localhost:3000`  
> Auth: `Authorization: Bearer <token>` (tất cả endpoints)

---

## 1. Kho thức ăn

### POST `/api/feeding/products` — Thêm sản phẩm (AI phân tích)

**Request:**
```json
{
  "name": "Mr. Vet 2",
  "brand": "Mr. Vet",
  "weightGrams": 1000,
  "image": "data:image/jpeg;base64,/9j/4AAQ..." 
}
```
> `image` optional. Nếu có → AI Vision đọc bao bì. Không có → AI tra cứu từ tên.

**Response 201:**
```json
{
  "success": true,
  "message": "Đã thêm: Mr. Vet 2",
  "data": {
    "id": 1,
    "userId": "abc123",
    "name": "Mr. Vet 2",
    "brand": "Mr. Vet",
    "imageUrl": "/uploads/products/abc123-1711234567890.jpg",
    "weightGrams": 1000,
    "remainingGrams": 1000,
    "caloriesPer100g": 350,
    "proteinPercent": 30.0,
    "fatPercent": 15.0,
    "fiberPercent": 3.0,
    "ingredients": ["Thịt gà", "Cá hồi", "Gạo lứt"],
    "goodFor": ["Mèo trưởng thành", "Kiểm soát cân nặng"],
    "badFor": ["Mèo dị ứng gia cầm"],
    "aiAnalysis": "Sản phẩm chất lượng tốt, giàu protein...",
    "isActive": true,
    "createdAt": "2026-03-23T06:00:00.000Z"
  }
}
```

---

### GET `/api/feeding/products` — Danh sách kho

**Response 200:**
```json
{
  "success": true,
  "message": "2 sản phẩm",
  "data": [
    {
      "id": 1,
      "name": "Mr. Vet 2",
      "brand": "Mr. Vet",
      "weightGrams": 1000,
      "remainingGrams": 750,
      "caloriesPer100g": 350,
      "proteinPercent": 30.0,
      "fatPercent": 15.0,
      "fiberPercent": 3.0,
      "ingredients": ["Thịt gà", "Cá hồi"],
      "goodFor": ["Mèo trưởng thành"],
      "badFor": ["Mèo dị ứng gia cầm"],
      "aiAnalysis": "...",
      "isActive": true,
      "createdAt": "2026-03-23T06:00:00.000Z",
      "feedingPlans": [
        { "id": 1, "petId": 1, "dailyGrams": 69 },
        { "id": 2, "petId": 2, "dailyGrams": 57 }
      ]
    }
  ]
}
```

---

### DELETE `/api/feeding/products/:id` — Xóa sản phẩm

**Response 200:**
```json
{ "success": true, "message": "Đã xóa sản phẩm", "data": { "id": 1 } }
```

---

### PUT `/api/feeding/products/:id` — Chỉnh sửa / hủy sản phẩm

**Request (hư/rơi/hủy):**
```json
{ "remainingGrams": 500, "reason": "Hạt bị ẩm mốc, bỏ 500g" }
```

**Request (sửa tên):**
```json
{ "name": "Mr. Vet 2 Adult", "brand": "Mr. Vet" }
```

**Request (hủy toàn bộ):**
```json
{ "remainingGrams": 0, "reason": "Hết hạn sử dụng" }
```

> Tất cả fields optional. `reason` để ghi chú lý do thay đổi.

**Response 200 (có lý do):**
```json
{
  "success": true,
  "message": "Đã cập nhật Mr. Vet 2",
  "data": { "id": 1, "remainingGrams": 500, "..." : "..." },
  "funMessage": null,
  "adjustNote": "Hạt bị ẩm mốc, bỏ 500g",
  "reason": "Hạt bị ẩm mốc, bỏ 500g"
}
```

**Response 200 (không ghi lý do → message vui):**
```json
{
  "success": true,
  "message": "Đã cập nhật Mr. Vet 2",
  "data": { "id": 1, "remainingGrams": 500, "..." : "..." },
  "funMessage": "Hạt bay đi đâu hết rồi ta?? Mèo lén ăn vụng à 😹",
  "adjustNote": null,
  "reason": null
}
```

> **`funMessage`**: hiện toast vui khi giảm gram mà không ghi lý do. Random 1 trong 5 câu.
> **`adjustNote`**: hiện khi hủy hết (0g) hoặc mất > 50%.

---

## 2. Khẩu phần ăn

### POST `/api/feeding/plans/generate` — AI tạo khẩu phần (multi-pet)

**Request:**
```json
{
  "productId": 1,
  "petIds": [1, 2],
  "mealsPerDay": 3
}
```

**Response 201:**
```json
{
  "success": true,
  "message": "Đã tạo khẩu phần cho 2 bé",
  "data": {
    "plans": [
      {
        "id": 1,
        "petId": 1,
        "foodProductId": 1,
        "dailyGrams": 69,
        "dailyCalories": 242,
        "mealsPerDay": 3,
        "aiRecommendation": "Khẩu phần chuẩn cho Miu (4kg).",
        "isActive": true,
        "pet": { "id": 1, "name": "Miu", "weight": 4.0, "avatar": null },
        "schedules": [
          { "id": 1, "time": "07:00", "portionGrams": 23, "label": "Sáng", "isNotifyOn": true },
          { "id": 2, "time": "12:00", "portionGrams": 23, "label": "Trưa", "isNotifyOn": true },
          { "id": 3, "time": "19:00", "portionGrams": 23, "label": "Tối", "isNotifyOn": true }
        ]
      }
    ],
    "summary": {
      "productName": "Mr. Vet 2",
      "totalDailyGrams": 126,
      "daysRemaining": 7,
      "bagWeight": 1000
    }
  }
}
```

> **Logic:** Pet khỏe → backend formula (35 kcal/kg adult, 70 kcal/kg kitten). Pet bệnh → AI điều chỉnh.

---

### GET `/api/feeding/plans` — Xem tất cả plans (kèm confirm status hôm nay)

**Response 200:**
```json
{
  "success": true,
  "message": "2 khẩu phần",
  "data": [
    {
      "id": 1,
      "dailyGrams": 69,
      "dailyCalories": 242,
      "mealsPerDay": 3,
      "pet": { "id": 1, "name": "Miu", "weight": 4.0, "species": "Mèo" },
      "foodProduct": { "id": 1, "name": "Mr. Vet 2", "brand": "Mr. Vet", "caloriesPer100g": 350, "remainingGrams": 750, "weightGrams": 1000 },
      "schedules": [
        {
          "id": 1, "time": "07:00", "portionGrams": 23, "label": "Sáng",
          "feedingLogs": [{ "id": 1, "fedAt": "2026-03-23T07:05:00.000Z" }]
        },
        {
          "id": 2, "time": "12:00", "portionGrams": 23, "label": "Trưa",
          "feedingLogs": []
        }
      ]
    }
  ]
}
```

> `feedingLogs` rỗng = chưa cho ăn. Có item = đã confirm.

---

### PUT `/api/feeding/plans/:id` — Cập nhật plan

**Request:**
```json
{ "dailyGrams": 80, "mealsPerDay": 4, "isActive": false }
```
> Tất cả fields optional.

---

## 3. Lịch cho ăn & Xác nhận

### GET `/api/feeding/today` — Timeline hôm nay

**Response 200:**
```json
{
  "success": true,
  "message": "2/6 bữa đã cho ăn",
  "data": {
    "date": "2026-03-23",
    "totalMeals": 6,
    "fedCount": 2,
    "pendingCount": 4,
    "timeline": [
      {
        "scheduleId": 1, "time": "07:00", "label": "Sáng", "portionGrams": 23,
        "petName": "Miu", "petAvatar": null, "petId": 1, "foodName": "Mr. Vet 2",
        "isFed": true, "fedAt": "2026-03-23T07:05:00.000Z", "feedingNote": "Bé ăn hết"
      },
      {
        "scheduleId": 2, "time": "12:00", "label": "Trưa", "portionGrams": 23,
        "petName": "Miu", "petId": 1, "foodName": "Mr. Vet 2",
        "isFed": false, "fedAt": null, "feedingNote": null
      }
    ]
  }
}
```

> Timeline sorted by `time`. Dùng `isFed` để hiển thị ✅ / chờ.

---

### POST `/api/feeding/confirm/:scheduleId` — Xác nhận đã cho ăn

**Request:**
```json
{
  "note": "Bé ăn hết",
  "portionAte": 20
}
```
> Cả 2 fields optional. `portionAte` null = ăn hết đúng khẩu phần.

**Response 200 (đúng giờ):**
```json
{
  "success": true,
  "message": "Đã xác nhận cho Miu ăn bữa Trưa",
  "data": {
    "id": 3, "scheduleId": 2, "fedAt": "2026-03-23T12:05:00.000Z",
    "note": "Bé ăn hết", "portionAte": 20, "date": "2026-03-23",
    "isEarly": false, "isLate": false, "warning": null
  }
}
```

**Response 200 (cho ăn SỚM > 1 tiếng):**
```json
{
  "success": true,
  "message": "Đã xác nhận cho Miu ăn bữa Tối",
  "data": {
    "id": 4, "scheduleId": 3,
    "isEarly": true, "isLate": false,
    "warning": "Còn 5h30p nữa mới tới bữa Tối (19:00). Cho ăn sớm có thể làm lệch lịch bữa sau."
  }
}
```

**Response 200 (cho ăn TRỄ > 2 tiếng):**
```json
{
  "data": {
    "isEarly": false, "isLate": true,
    "warning": "Đã qua giờ bữa Sáng (07:00) hơn 3 tiếng. Nên cho ăn đúng giờ để bé không bị đói."
  }
}
```

> **Mobile UI:** Nếu `isEarly` hoặc `isLate` = true → hiện toast/banner `warning`. Vẫn confirm thành công.

**Error 409** (đã confirm rồi):
```json
{ "success": false, "error": "Bữa này đã được xác nhận rồi", "code": "ALREADY_CONFIRMED" }
```

> Khi confirm: tự động trừ `remainingGrams` trong FoodProduct.

---

### GET `/api/feeding/streak` — Streak cho ăn đầy đủ

**Response 200:**
```json
{
  "success": true,
  "data": {
    "streak": 5,
    "totalSchedulesPerDay": 6,
    "message": "Tuyệt vời! 5 ngày liên tục cho ăn đầy đủ 🔥"
  }
}
```

> Streak tính = số ngày liên tục cho ăn đủ TẤT CẢ bữa.

---

## 4. Chuyển đổi thức ăn

### POST `/api/feeding/transition` — Lịch chuyển đổi

**Request:**
```json
{
  "oldProductId": 1,
  "newProductId": 2,
  "petIds": [1],
  "transitionDays": 7
}
```

**Response 200:**
```json
{
  "success": true,
  "message": "Lịch chuyển đổi 7 ngày: Mr. Vet 2 → Royal Canin",
  "data": {
    "oldProduct": { "id": 1, "name": "Mr. Vet 2", "remainingGrams": 750 },
    "newProduct": { "id": 2, "name": "Royal Canin" },
    "transitionDays": 7,
    "petPlans": [
      {
        "petId": 1,
        "petName": "Miu",
        "dailyCalories": 140,
        "schedule": [
          { "day": 1, "oldGrams": 34, "newGrams": 6,  "oldPercent": 86, "newPercent": 14, "label": "86% Mr. Vet 2 + 14% Royal Canin" },
          { "day": 2, "oldGrams": 28, "newGrams": 11, "oldPercent": 71, "newPercent": 29, "label": "71% Mr. Vet 2 + 29% Royal Canin" },
          { "day": 3, "oldGrams": 23, "newGrams": 17, "oldPercent": 57, "newPercent": 43, "label": "..." },
          { "day": 4, "oldGrams": 17, "newGrams": 23, "oldPercent": 43, "newPercent": 57, "label": "..." },
          { "day": 5, "oldGrams": 11, "newGrams": 28, "oldPercent": 29, "newPercent": 71, "label": "..." },
          { "day": 6, "oldGrams": 6,  "newGrams": 34, "oldPercent": 14, "newPercent": 86, "label": "..." },
          { "day": 7, "oldGrams": 0,  "newGrams": 40, "oldPercent": 0,  "newPercent": 100, "label": "100% mới" }
        ]
      }
    ],
    "warnings": [
      { "level": "danger", "message": "Miu bị bệnh thận — Royal Canin có 35% protein (cao)." },
      { "level": "info", "message": "Nếu mèo bị tiêu chảy → kéo dài thời gian chuyển đổi." }
    ],
    "oldFoodNeeded": 119,
    "hasEnoughOldFood": true
  }
}
```

> `warnings.level`: `danger` (đỏ), `warning` (vàng), `caution` (cam), `info` (xanh)

---

## 5. Nutrition Dashboard

### GET `/api/ai/nutrition-stats/:petId` — Dashboard data

**Response 200:**
```json
{
  "success": true,
  "data": {
    "today": { "calories": 285, "meals": 2, "avgScore": 7.5 },
    "target": { "dailyCalories": 140, "weight": 4.0, "isKitten": false },
    "weekChart": [
      { "date": "2026-03-17", "day": "T2", "calories": 120, "meals": 3 },
      { "date": "2026-03-18", "day": "T3", "calories": 140, "meals": 3 },
      { "date": "2026-03-19", "day": "T4", "calories": 0,   "meals": 0 },
      { "date": "2026-03-20", "day": "T5", "calories": 135, "meals": 2 },
      { "date": "2026-03-21", "day": "T6", "calories": 150, "meals": 3 },
      { "date": "2026-03-22", "day": "T7", "calories": 130, "meals": 3 },
      { "date": "2026-03-23", "day": "CN", "calories": 285, "meals": 2 }
    ],
    "totalLogs": 45
  }
}
```

> `weekChart` dùng cho bar chart. `target.dailyCalories` dùng cho calorie ring.

---

## 6. Chat Sessions List

### GET `/api/ai/chat/sessions?petId=1` — Danh sách chat AI cũ

**Response 200:**
```json
{
  "success": true,
  "message": "5 phiên chat",
  "data": [
    {
      "id": 3,
      "title": "Hỏi về Mr. Vet 2",
      "petName": "Miu",
      "petAvatar": null,
      "foodName": "Mr. Vet 2",
      "messageCount": 8,
      "createdAt": "2026-03-23T06:00:00.000Z",
      "updatedAt": "2026-03-23T06:15:00.000Z"
    }
  ]
}
```

> `petId` query param optional. Bỏ = lấy tất cả sessions.

---

## Push Notifications

Server tự gửi push mỗi **15 phút**:

| Thời điểm | Title | Body |
|---|---|---|
| Đúng giờ (±7 phút) | 🍽️ Đến giờ cho Miu ăn bữa Tối | 23g Mr. Vet 2 — nhấn để xác nhận |
| Quá 30 phút chưa confirm | 😾 Miu vẫn chưa được ăn! | Đã quá giờ 19:00! 23g Mr. Vet 2 — hãy cho ăn ngay! |

**Push data payload:**
```json
{ "screen": "FeedingToday", "scheduleId": "3" }
```
