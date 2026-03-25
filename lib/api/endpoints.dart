/// ============================================
/// API ENDPOINTS REGISTRY
/// ============================================
/// Tất cả endpoints nằm ở ĐÂY.
/// Backend thay đổi URL → chỉ sửa file này.
class Endpoints {
  // ─── Auth ────────────────────────────────
  static const authRegister = '/auth/register';
  static const authLogin = '/auth/login';
  static const authForgotPassword = '/auth/forgot-password';
  static const authProfile = '/auth/profile';
  static const authAvatar = '/auth/avatar';
  static const authAccount = '/auth/account';
  static const authEkyc = '/auth/ekyc';
  static const authEkycStatus = '/auth/ekyc/status';

  // ─── Pets ────────────────────────────────
  static const pets = '/pets';
  static String petDetail(dynamic id) => '/pets/$id';
  static String petUpdate(dynamic id) => '/pets/$id';
  static String petDelete(dynamic id) => '/pets/$id';
  static String petAvatar(dynamic id) => '/pets/$id/avatar';
  static String petAvatarB64(dynamic id) => '/pets/$id/avatar-base64';

  // ─── Notifications ──────────────────────
  static const notificationsSend = '/notifications/send';
  static const notificationsSendAll = '/notifications/send-all';
  static const notificationsToken = '/notifications/token';
  static const notifications = '/notifications';

  // ─── Upload ─────────────────────────────
  static const uploadImage = '/upload/image';
  static const uploadAvatar = '/upload/avatar';

  // ─── Social / Feed ──────────────────────
  static const feed = '/feed';
  static String feedDetail(dynamic id) => '/feed/$id';
  static String feedLike(dynamic id) => '/feed/$id/like';
  static String feedComments(dynamic id) => '/feed/$id/comments';

  // ─── AI / Food Analysis & Chat ─────────
  static const aiAnalyzeFood = '/ai/analyze-food';
  static const aiChatStart = '/ai/chat/start';
  static String aiChatSend(dynamic sessionId) => '/ai/chat/$sessionId/send';
  static String aiChatHistory(dynamic sessionId) => '/ai/chat/$sessionId';

  // ─── Food Logs ────────────────────────
  static String foodHistory(dynamic petId) => '/pets/$petId/food-history';
  static String foodLogCreate(dynamic petId) => '/pets/$petId/food-logs';
  static String foodLogDelete(dynamic petId, dynamic id) =>
      '/pets/$petId/food-logs/$id';

  // ─── Medical Records ─────────────────
  static String medicalList(dynamic petId) => '/pets/$petId/medical';
  static String medicalCreate(dynamic petId) => '/pets/$petId/medical';
  static String medicalUpdate(dynamic petId, dynamic id) =>
      '/pets/$petId/medical/$id';
  static String medicalDelete(dynamic petId, dynamic id) =>
      '/pets/$petId/medical/$id';

  // ─── Vaccinations ──────────────────────
  static String vaccinationList(dynamic petId) => '/pets/$petId/vaccinations';
  static String vaccinationCreate(dynamic petId) => '/pets/$petId/vaccinations';
  static String vaccinationUpdate(dynamic petId, dynamic id) =>
      '/pets/$petId/vaccinations/$id';
  static String vaccinationDelete(dynamic petId, dynamic id) =>
      '/pets/$petId/vaccinations/$id';

  // ─── Appointments ──────────────────────
  static String appointmentList(dynamic petId) => '/pets/$petId/appointments';
  static String appointmentCreate(dynamic petId) => '/pets/$petId/appointments';
  static String appointmentUpdate(dynamic petId, dynamic id) =>
      '/pets/$petId/appointments/$id';
  static String appointmentDelete(dynamic petId, dynamic id) =>
      '/pets/$petId/appointments/$id';

  // ─── Costs ────────────────────────────
  static String medicalCosts(dynamic petId, dynamic id) =>
      '/pets/$petId/medical/$id/costs';
  static String medicalCostId(dynamic petId, dynamic id, dynamic costId) =>
      '/pets/$petId/medical/$id/costs/$costId';
  static String vaccineCosts(dynamic petId, dynamic id) =>
      '/pets/$petId/vaccination/$id/costs';
  static String vaccineCostId(dynamic petId, dynamic id, dynamic costId) =>
      '/pets/$petId/vaccination/$id/costs/$costId';
  static String appointmentCosts(dynamic petId, dynamic id) =>
      '/pets/$petId/appointment/$id/costs';
  static String appointmentCostId(
          dynamic petId, dynamic id, dynamic costId) =>
      '/pets/$petId/appointment/$id/costs/$costId';

  // ─── Weight Tracking ──────────────────
  static String petWeight(dynamic petId) => '/pets/$petId/weight';
  static String petWeightDelete(dynamic petId, dynamic logId) => '/pets/$petId/weight/$logId';
  static const petWeightReminder = '/pets/weight/reminder';

  // ─── Vaccine Schedule ─────────────────
  static String petVaccines(dynamic petId) => '/pets/$petId/vaccines';
  static String petVaccineDetail(dynamic petId, dynamic vaccineId) => '/pets/$petId/vaccines/$vaccineId';
  static const petVaccinesUpcoming = '/pets/vaccines/upcoming';

  // ─── Clinics ──────────────────────────
  static const clinics = '/clinics';
  static String clinicNearby(double lat, double lng,
          {int radius = 10, String sort = 'distance', int page = 1, int limit = 20}) =>
      '/clinics/nearby?lat=$lat&lng=$lng&radius=$radius&sort=$sort&page=$page&limit=$limit';
  static String clinicDetail(dynamic id) => '/clinics/$id';
  static String clinicReviews(dynamic id, {int page = 1, int limit = 10}) =>
      '/clinics/$id/reviews?page=$page&limit=$limit';
  static String clinicBook(dynamic id) => '/clinics/$id/book';
  static String clinicAddReview(dynamic id) => '/clinics/$id/reviews';
  static const bookings = '/bookings';
  static String bookingCancel(dynamic id) => '/bookings/$id/cancel';

  // ─── SOS ──────────────────────────────
  static const sosTrigger = '/sos/trigger';
  static String sosAccept(dynamic id) => '/sos/$id/accept';
  static String sosComplete(dynamic id) => '/sos/$id/complete';
  static String sosCancel(dynamic id) => '/sos/$id/cancel';
  static const sosHistory = '/sos';

  // ─── Wallet ───────────────────────────
  static const wallet = '/wallet';
  static const walletTopup = '/wallet/topup';
  static const walletRepay = '/wallet/repay';

  // ─── Feeding System ───────────────────
  static const feedingProducts = '/feeding/products';
  static const feedingProductQuickAdd = '/feeding/products/quick-add';
  static String feedingProductDelete(dynamic id) => '/feeding/products/$id';
  static String feedingProductUpdate(dynamic id) => '/feeding/products/$id';
  static String feedingProductRestock(dynamic id) => '/feeding/products/$id/restock';
  static const feedingPlansGenerate = '/feeding/plans/generate';
  static const feedingPlans = '/feeding/plans';
  static String feedingPlanUpdate(dynamic id) => '/feeding/plans/$id';
  static const feedingToday = '/feeding/today';
  static String feedingConfirm(dynamic scheduleId) => '/feeding/confirm/$scheduleId';
  static const feedingStreak = '/feeding/streak';
  static const feedingTransition = '/feeding/transition';

  // ─── Nutrition Stats ──────────────────
  static String nutritionStats(dynamic petId) => '/feeding/nutrition/$petId';
  static const feedingHistory = '/feeding/history';
  static const aiChatSessions = '/ai/chat/sessions';
}
