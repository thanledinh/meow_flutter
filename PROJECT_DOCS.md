# Moew Flutter — Tài liệu dự án đầy đủ

> **Cập nhật:** 2026-03-24 | **Backend:** `http://171.248.184.99:3000/api` | **Flutter SDK:** `c:\haoquason\flutter`

---

## 1. Tổng quan dự án

**Moew** là ứng dụng quản lý thú cưng toàn diện (Flutter + Node.js backend) bao gồm:
- Quản lý hồ sơ thú cưng, y tế, cân nặng, tiêm chủng
- Hệ thống cho ăn thông minh với AI dinh dưỡng
- Đặt lịch phòng khám, SOS khẩn cấp
- Bản đồ Guardian (Mapbox), Ví điện tử
- AI phân tích thức ăn & chat tư vấn (Gemini)
- Push notification (Firebase FCM)

---

## 2. Cấu trúc dự án

```
lib/
├── main.dart                    # Entry point (Firebase, Mapbox, Auth Provider, 401 handler)
├── api/                         # 14 API files
│   ├── api_client.dart          # Singleton HTTP client, TokenManager, 401 handler
│   ├── endpoints.dart           # ~80 endpoints registry
│   ├── auth_api.dart            # Login, register, profile, eKYC
│   ├── pet_api.dart             # CRUD pets, weight tracking (4), vaccine (5)
│   ├── medical_api.dart         # Medical records, vaccinations, appointments, costs
│   ├── feeding_api.dart         # Products, plans, today, confirm, nutrition, history
│   ├── ai_api.dart              # Food analysis (Gemini), chat start/send
│   ├── clinic_api.dart          # Clinics, bookings, reviews
│   ├── sos_api.dart             # SOS trigger, accept, complete, cancel
│   ├── wallet_api.dart          # Balance, top-up, repay
│   ├── feed_api.dart            # Social feed (posts, likes, comments)
│   ├── notification_api.dart    # Push notifications, token
│   ├── upload_api.dart          # Image upload
│   └── ekyc_api.dart            # eKYC verification
├── config/
│   ├── router.dart              # 30+ named routes, slide/fade transitions
│   ├── theme.dart               # MoewColors, MoewRadius, MoewSpacing, MoewShadows, MoewTextStyles
│   └── secrets.dart             # Mapbox secret token
├── providers/
│   └── auth_provider.dart       # ChangeNotifier: isLoggedIn, user, checkAuth, onLogout
├── services/
│   ├── firebase_messaging_service.dart  # FCM setup, permissions, token
│   └── socket_service.dart              # WebSocket (SOS real-time)
├── widgets/
│   ├── main_shell.dart          # Bottom nav bar (4 tabs: Home, Map, Pets, Clinics)
│   ├── common_widgets.dart      # AppHeader, EmptyState, StatusBadge, etc.
│   └── toast.dart               # MoewToast (success, error, warning, info)
├── utils/
│   └── parse_utils.dart         # toList, toDouble helper functions
└── screens/                     # 12 module folders, 38 screens
```

---

## 3. Kiến trúc & Patterns

| Component | Pattern |
|-----------|---------|
| **API Client** | Singleton `ApiClient()`, auto-attach Bearer token, 401 → force logout + navigate `/login` |
| **Auth** | `AuthProvider` (ChangeNotifier) + `TokenManager` (SharedPreferences) |
| **Navigation** | `onGenerateRoute` + named routes, global `navigatorKey` for 401 redirect |
| **UI Framework** | Custom design system (`theme.dart`), Google Fonts (Inter), no Tailwind |
| **State** | Local `StatefulWidget` + `setState`, Provider for auth only |
| **Bottom Nav** | `MainShell` with `IndexedStack` (Home, Map→push route, Pets, Clinics) |

### Theme Colors
| Token | Color | Hex |
|-------|-------|-----|
| `primary` | Vivid Blue | `#2563EB` |
| `secondary` | Warm Amber | `#F59E0B` |
| `accent` | Violet | `#8B5CF6` |
| `success` | Emerald | `#10B981` |
| `danger` | Red | `#EF4444` |

---

## 4. Tất cả Screens & Routes

### 4.1 Auth (`/screens/auth/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/login` | `LoginScreen` | Đăng nhập (email/password), chuyển `/register` |
| `/register` | `RegisterScreen` | Đăng ký tài khoản mới |

### 4.2 Home (`/screens/home/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/home` | `MainShell` → `HomeScreen` | Trang chủ: avatar, greeting, 4 quick actions grid, SOS FAB, animated drawer |

**Quick Actions:** Thú cưng, Cho ăn, AI Phân tích, Phòng khám

**Drawer Menu (12 items):** Hồ sơ cá nhân, Trang công khai, AI Thức ăn, Camera, Phòng khám, Ví Meow-Care, Lịch sử SOS, Thông báo, Lịch sử đặt lịch, Cho ăn hôm nay, Chat AI cũ

### 4.3 Profile (`/screens/profile/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/profile` | `ProfileScreen` | Xem/sửa hồ sơ, upload avatar, đổi mật khẩu |
| `/public-profile` | `PublicProfileScreen` | Trang công khai xem bởi người khác |
| `/ekyc` | `EkycScreen` | Xác minh danh tính (upload CCCD) |

### 4.4 Pet (`/screens/pet/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/pet-profile` | `PetProfileScreen` | Danh sách thú cưng (bottom tab 3) |
| `/pet-detail` | `PetDetailScreen` | Chi tiết pet: avatar, thông tin, 4 action rows |
| `/add-pet` | `AddPetScreen` | Thêm pet mới (name, species, breed, gender, weight, color, features) |
| `/pet-weight` | `PetWeightScreen` | Theo dõi cân nặng: biểu đồ, trend, thêm/xóa log |
| `/pet-vaccines` | `PetVaccineScreen` | Lịch tiêm chủng: grouped by vaccine name, overdue badges |

**Pet Detail Action Rows:**
1. Hồ sơ y tế → `/medical`
2. Lịch sử ăn → `/food-history`
3. Theo dõi cân nặng → `/pet-weight`
4. Lịch tiêm chủng → `/pet-vaccines`

### 4.5 Medical (`/screens/medical/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/medical` | `MedicalScreen` | 3 tabs: Bệnh, Tiêm chủng, Lịch khám |
| `/add-medical` | `AddMedicalScreen` | Thêm record (type: medical/vaccination/appointment) |
| `/medical-detail` | `MedicalDetailScreen` | Chi tiết record + costs |
| `/cost-breakdown` | `CostBreakdownScreen` | Quản lý chi phí y tế |

### 4.6 Feeding System (`/screens/feeding/`) — AI Nutritionist
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/feeding-today` | `FeedingTodayScreen` | Dashboard: streak, schedule hôm nay, confirm cho ăn (isEarly/isLate warning) |
| `/food-products` | `FoodProductsScreen` | Kho thức ăn: thêm/sửa/xóa/restock (EXCEEDS_BAG_WEIGHT flow), dispose (funMessage/adjustNote) |
| `/feeding-plan` | `FeedingPlanScreen` | Khẩu phần: AI generate (activityLevel picker), edit plan (5 fields), tap card to edit |
| `/food-transition` | `FoodTransitionScreen` | Chuyển đổi thức ăn (transition plan) |
| `/nutrition-dashboard` | `NutritionDashboardScreen` | Thống kê dinh dưỡng: calorie ring (tolerance zones), week chart, pet selector |
| `/food-history` | `FoodHistoryScreen` | Lịch sử ăn: day-grouped, feeding + ai_scan items, infinite scroll |

**Feeding Features Chi Tiết:**
- **Confirm cho ăn**: POST `/feeding/confirm/:scheduleId` → `isEarly`, `isLate`, `warning` toast
- **Restock 3-step**: Normal → EXCEEDS_BAG_WEIGHT dialog → Force restock
- **Dispose**: `funMessage` (toast vui) + `adjustNote` (toast nghiêm túc)
- **AI Generate**: productId, petIds[], mealsPerDay, activityLevel (active/normal/neutered/weight_loss/senior)
- **Edit Plan**: activityLevel, healthNote, dailyGrams, mealsPerDay, isActive + changes[] summary
- **Calorie Tolerance**: ≤110% xanh, 110-120% vàng, >120% đỏ (không harsh khi AI tự chia gram)
- **Quick Add**: Scan AI → Thêm vào kho → nhập trọng lượng bao → POST `/feeding/products/quick-add`

### 4.7 AI (`/screens/ai/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/food-analysis` | `FoodAnalysisScreen` | Chụp/chọn ảnh → AI phân tích → score, ingredients, advice + "Thêm vào kho" button |
| `/ai-chat` | `AiChatScreen` | Chat với AI về dinh dưỡng (có context foodLogId) |
| `/chat-sessions` | `ChatSessionsScreen` | Lịch sử chat sessions |
| `/camera` | `CameraScreen` | Camera chụp ảnh (ImagePicker) |

### 4.8 Clinic (`/screens/clinic/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/clinic-list` | `ClinicListScreen` | Danh sách phòng khám (bottom tab 4) |
| `/clinic-detail` | `ClinicDetailScreen` | Chi tiết: info, services, reviews, đặt lịch |
| `/book-appointment` | `BookAppointmentScreen` | Form đặt lịch (chọn pet, ngày, giờ, dịch vụ, ghi chú) |
| `/booking-history` | `BookingHistoryScreen` | Lịch sử đặt lịch (status tabs, cancel) |

### 4.9 SOS (`/screens/sos/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/sos` | `SosScreen` | Trigger SOS khẩn cấp + WebSocket real-time (auto-expand radius 5→10→15km) |
| `/sos-history` | `SosHistoryScreen` | Lịch sử SOS |

### 4.10 Map (`/screens/map/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/guardian-map` | `GuardianMapScreen` | Bản đồ Mapbox: vị trí người dùng, clinics nearby, navigation |

### 4.11 Wallet (`/screens/wallet/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/wallet` | `WalletScreen` | Ví: số dư, nạp tiền, lịch sử giao dịch |

### 4.12 Notification (`/screens/notification/`)
| Route | Screen | Chức năng |
|-------|--------|-----------|
| `/notifications` | `NotificationScreen` | Danh sách thông báo đẩy |

---

## 5. API Endpoints Registry

### Auth
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/auth/register` | Đăng ký |
| POST | `/auth/login` | Đăng nhập → token |
| POST | `/auth/forgot-password` | Quên mật khẩu |
| GET | `/auth/profile` | Lấy profile |
| PUT | `/auth/profile` | Cập nhật profile |
| POST | `/auth/avatar` | Upload avatar |
| PUT | `/auth/account` | Đổi mật khẩu |
| POST | `/auth/ekyc` | Gửi eKYC |
| GET | `/auth/ekyc/status` | Check eKYC status |

### Pets
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/pets` | Danh sách pets |
| GET | `/pets/:id` | Chi tiết pet |
| POST | `/pets` | Thêm pet |
| PUT | `/pets/:id` | Cập nhật pet |
| DELETE | `/pets/:id` | Xóa pet |
| POST | `/pets/:id/avatar-base64` | Upload avatar (base64) |

### Weight Tracking
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/pets/:id/weight` | Ghi nhận cân nặng (auto update cùng ngày) |
| GET | `/pets/:id/weight?months=3` | Lịch sử + chart + trend + stats |
| DELETE | `/pets/:id/weight/:logId` | Xóa log |
| GET | `/pets/weight/reminder` | Check tất cả pets cần cân |

### Vaccine Schedule
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/pets/:id/vaccines` | Ghi nhận tiêm (vaccineName, dose, date, nextDoseDate, vet, clinic, batch, cost, notes) |
| GET | `/pets/:id/vaccines` | Lịch sử tiêm (grouped by name) |
| PUT | `/pets/:id/vaccines/:vaccineId` | Cập nhật |
| DELETE | `/pets/:id/vaccines/:vaccineId` | Xóa |
| GET | `/pets/vaccines/upcoming?days=30` | Lịch tiêm sắp tới (overdue/urgent/upcoming) |

### Medical Records
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET/POST | `/pets/:petId/medical` | CRUD bệnh án |
| GET/POST | `/pets/:petId/vaccinations` | CRUD tiêm chủng (legacy) |
| GET/POST | `/pets/:petId/appointments` | CRUD lịch khám |
| GET/POST | `/pets/:petId/medical/:id/costs` | Chi phí y tế |

### Feeding System
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET/POST | `/feeding/products` | Kho thức ăn |
| POST | `/feeding/products/quick-add` | Quick add từ AI scan |
| PUT | `/feeding/products/:id` | Edit/dispose (remainingGrams, reason → funMessage, adjustNote) |
| PUT | `/feeding/products/:id/restock` | Restock (addGrams, force) |
| DELETE | `/feeding/products/:id` | Xóa sản phẩm |
| POST | `/feeding/plans/generate` | AI tạo khẩu phần (productId, petIds[], mealsPerDay, activityLevel) |
| GET | `/feeding/plans` | Danh sách khẩu phần |
| PUT | `/feeding/plans/:id` | Edit plan (activityLevel, healthNote, dailyGrams, mealsPerDay, isActive) |
| GET | `/feeding/today` | Bữa ăn hôm nay |
| POST | `/feeding/confirm/:scheduleId` | Confirm cho ăn → isEarly, isLate, warning |
| GET | `/feeding/streak` | Streak cho ăn |
| GET | `/feeding/transition` | Transition plan |
| GET | `/feeding/nutrition/:petId` | Thống kê dinh dưỡng (today, target, weekChart) |
| GET | `/feeding/history?petId=&page=&limit=` | Lịch sử ăn (grouped by date, feeding + ai_scan) |

### AI
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/ai/analyze-food` | Phân tích thức ăn bằng AI (image base64) |
| POST | `/ai/chat/start` | Bắt đầu chat session |
| POST | `/ai/chat/:sessionId/send` | Gửi tin nhắn |
| GET | `/ai/chat/:sessionId` | Lịch sử chat |
| GET | `/ai/chat/sessions` | Danh sách sessions |

### Clinics & Bookings
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/clinics` | Danh sách phòng khám |
| GET | `/clinics/nearby?lat=&lng=&radius=` | Tìm phòng khám gần |
| GET | `/clinics/:id` | Chi tiết |
| GET | `/clinics/:id/reviews` | Reviews |
| POST | `/clinics/:id/reviews` | Thêm review |
| POST | `/clinics/:id/book` | Đặt lịch |
| GET | `/bookings` | Lịch sử booking |
| PUT | `/bookings/:id/cancel` | Hủy booking |

### SOS
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/sos/trigger` | Trigger SOS (auto-expand 5→10→15km) |
| PUT | `/sos/:id/accept` | Clinic accept |
| PUT | `/sos/:id/complete` | Hoàn thành |
| PUT | `/sos/:id/cancel` | Hủy |
| GET | `/sos` | Lịch sử |

### Wallet
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | `/wallet` | Số dư + lịch sử |
| POST | `/wallet/topup` | Nạp tiền |
| POST | `/wallet/repay` | Trả tiền |

### Other
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | `/notifications/token` | Lưu FCM token |
| GET | `/notifications` | Danh sách thông báo |
| POST | `/upload/image` | Upload ảnh |
| GET/POST | `/feed` | Social feed |

---

## 6. Cấu hình quan trọng

```dart
// api_client.dart
class ApiConfig {
  static const String baseUrl = 'http://171.248.184.99:3000/api';
  static const Duration timeout = Duration(seconds: 15);
}

// Singleton pattern
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
}

// 401 Handler (main.dart)
ApiClient().setOnUnauthorized(() {
  auth.onLogout();
  navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
});

// TokenManager keys
static const String _tokenKey = '@moew_auth_token';
static const String _userKey = '@moew_auth_user';
```

---

## 7. Dependencies chính

| Package | Dùng cho |
|---------|---------|
| `provider` | Auth state management |
| `http` | HTTP requests |
| `shared_preferences` | Token storage |
| `firebase_core` + `firebase_messaging` | Push notifications |
| `mapbox_maps_flutter` | Guardian Map |
| `cached_network_image` | Image caching |
| `image_picker` | Camera / gallery |
| `google_fonts` | Typography (Inter) |

---

## 8. Business Logic đặc biệt

### Feeding Calorie Tolerance
```
≤ 50%   → primary    "Tiếp tục cho ăn"
50-80%  → primary    "Gần đạt!"
80-110% → success    "Đạt mục tiêu!"   ← tolerance zone
110-120% → warning   "Hơi vượt một chút"
> 120%  → danger     "Vượt nhiều!"
```

### Activity Level (Feeding Plans)
```
active      → ×1.4  (Vận động nhiều / Chưa triệt sản)
normal      → ×1.2  (Trưởng thành bình thường)
neutered    → ×1.0  (Đã triệt sản / Ít vận động)
weight_loss → ×0.8  (Đang giảm cân)
senior      → ×0.9  (Mèo già > 7 tuổi)
Kitten (< 1 tuổi) → ×2.5
Công thức: RER = 70 × weight^0.75, dailyCal = RER × hệ số
```

### Weight Trend
```
gaining  → changeKg > 0.2kg   (Tăng cân)
losing   → changeKg < -0.2kg  (Giảm cân)
stable   → trong khoảng ±0.2kg (Ổn định)
needsWeighIn → chưa cân hoặc ≥ 14 ngày
```

### SOS Auto-Expand
```
0s   → 5km
10s  → 10km
20s  → 15km
30s+ → 15km mỗi 15s cho đến khi accepted/cancelled/expired
```

### Restock 3-Step Flow
```
1. Normal: addGrams ≤ bagWeight → success
2. EXCEEDS_BAG_WEIGHT → dialog confirm (show currentGrams, bagWeight, maxCanAdd)
3. Force: addGrams + force:true → success + warning
```
