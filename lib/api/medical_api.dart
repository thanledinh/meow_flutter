import 'api_client.dart';
import 'endpoints.dart';

// ─── Medical Records ─────────────────
class MedicalApi {
  static final _client = ApiClient();

  static Future<ApiResponse> getAll(dynamic petId) =>
      _client.get(Endpoints.medicalList(petId));
  static Future<ApiResponse> create(
          dynamic petId, Map<String, dynamic> data) =>
      _client.post(Endpoints.medicalCreate(petId), data);
  static Future<ApiResponse> update(
          dynamic petId, dynamic id, Map<String, dynamic> data) =>
      _client.put(Endpoints.medicalUpdate(petId, id), data);
  static Future<ApiResponse> delete(dynamic petId, dynamic id) =>
      _client.delete(Endpoints.medicalDelete(petId, id));
}

// ─── Vaccinations ────────────────────
class VaccinationApi {
  static final _client = ApiClient();

  static Future<ApiResponse> getAll(dynamic petId) =>
      _client.get(Endpoints.vaccinationList(petId));
  static Future<ApiResponse> create(
          dynamic petId, Map<String, dynamic> data) =>
      _client.post(Endpoints.vaccinationCreate(petId), data);
  static Future<ApiResponse> update(
          dynamic petId, dynamic id, Map<String, dynamic> data) =>
      _client.put(Endpoints.vaccinationUpdate(petId, id), data);
  static Future<ApiResponse> delete(dynamic petId, dynamic id) =>
      _client.delete(Endpoints.vaccinationDelete(petId, id));
}

// ─── Appointments ────────────────────
class AppointmentApi {
  static final _client = ApiClient();

  static Future<ApiResponse> getAll(dynamic petId) =>
      _client.get(Endpoints.appointmentList(petId));
  static Future<ApiResponse> create(
          dynamic petId, Map<String, dynamic> data) =>
      _client.post(Endpoints.appointmentCreate(petId), data);
  static Future<ApiResponse> update(
          dynamic petId, dynamic id, Map<String, dynamic> data) =>
      _client.put(Endpoints.appointmentUpdate(petId, id), data);
  static Future<ApiResponse> delete(dynamic petId, dynamic id) =>
      _client.delete(Endpoints.appointmentDelete(petId, id));
}

// ─── Costs (dùng chung) ──────────────
class CostApi {
  static final _client = ApiClient();

  static String _costUrl(String type, dynamic petId, dynamic id) {
    if (type == 'medical') return Endpoints.medicalCosts(petId, id);
    if (type == 'vaccine') return Endpoints.vaccineCosts(petId, id);
    return Endpoints.appointmentCosts(petId, id);
  }

  static String _costIdUrl(
      String type, dynamic petId, dynamic id, dynamic costId) {
    if (type == 'medical') return Endpoints.medicalCostId(petId, id, costId);
    if (type == 'vaccine') return Endpoints.vaccineCostId(petId, id, costId);
    return Endpoints.appointmentCostId(petId, id, costId);
  }

  static Future<ApiResponse> getAll(
          String type, dynamic petId, dynamic id) =>
      _client.get(_costUrl(type, petId, id));
  static Future<ApiResponse> create(
          String type, dynamic petId, dynamic id, Map<String, dynamic> data) =>
      _client.post(_costUrl(type, petId, id), data);
  static Future<ApiResponse> update(String type, dynamic petId, dynamic id,
          dynamic costId, Map<String, dynamic> data) =>
      _client.put(_costIdUrl(type, petId, id, costId), data);
  static Future<ApiResponse> delete(
          String type, dynamic petId, dynamic id, dynamic costId) =>
      _client.delete(_costIdUrl(type, petId, id, costId));
}
