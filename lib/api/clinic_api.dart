import 'api_client.dart';
import 'endpoints.dart';

class ClinicApi {
  static final _client = ApiClient();

  /// Tìm phòng khám gần nhất theo GPS
  static Future<ApiResponse> getNearby(double lat, double lng,
          {int radius = 10,
          String sort = 'distance',
          int page = 1,
          int limit = 20}) =>
      _client.get(
        Endpoints.clinicNearby(lat, lng,
            radius: radius, sort: sort, page: page, limit: limit),
        auth: false,
      );

  /// Danh sách tất cả phòng khám
  static Future<ApiResponse> getAll({
    String? search,
    String? district,
    String? city,
    String sort = 'rating',
    int page = 1,
    int limit = 20,
  }) {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (district != null) params['district'] = district;
    if (city != null) params['city'] = city;
    params['sort'] = sort;
    params['page'] = page.toString();
    params['limit'] = limit.toString();
    final qs = Uri(queryParameters: params).query;
    return _client.get('${Endpoints.clinics}?$qs', auth: false);
  }

  /// Chi tiết phòng khám
  static Future<ApiResponse> getById(dynamic id) =>
      _client.get(Endpoints.clinicDetail(id), auth: false);

  /// Danh sách đánh giá
  static Future<ApiResponse> getReviews(dynamic id,
          {int page = 1, int limit = 10}) =>
      _client.get(Endpoints.clinicReviews(id, page: page, limit: limit),
          auth: false);

  /// Đặt lịch khám
  static Future<ApiResponse> book(
          dynamic clinicId, Map<String, dynamic> data) =>
      _client.post(Endpoints.clinicBook(clinicId), data);

  /// Viết đánh giá
  static Future<ApiResponse> addReview(
          dynamic clinicId, Map<String, dynamic> data) =>
      _client.post(Endpoints.clinicAddReview(clinicId), data);

  /// Lịch sử booking
  static Future<ApiResponse> getBookings(
      {String? status, int page = 1, int limit = 20}) {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    params['page'] = page.toString();
    params['limit'] = limit.toString();
    final qs = Uri(queryParameters: params).query;
    return _client.get('${Endpoints.bookings}?$qs');
  }

  /// Hủy booking
  static Future<ApiResponse> cancelBooking(dynamic bookingId,
          {String reason = ''}) =>
      _client.put(Endpoints.bookingCancel(bookingId), {'reason': reason});
}
