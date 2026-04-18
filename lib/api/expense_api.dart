import 'package:moew_flutter/api/api_client.dart';
import 'package:moew_flutter/api/endpoints.dart';

class ExpenseApi {
  static final _client = ApiClient();

  // Create
  static Future<ApiResponse> createExpense(Map<String, dynamic> data) =>
      _client.post(Endpoints.expenses, data);

  // List
  static Future<ApiResponse> getExpenses({String? from, String? to, String? petId, int page = 1, int limit = 20}) {
    final params = <String>['page=$page', 'limit=$limit'];
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    if (petId != null) params.add('petId=$petId');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return _client.get('${Endpoints.expenses}$query');
  }

  // Update
  static Future<ApiResponse> updateExpense(dynamic id, Map<String, dynamic> data) =>
      _client.put(Endpoints.expenseDetail(id), data);

  // Delete
  static Future<ApiResponse> deleteExpense(dynamic id) =>
      _client.delete(Endpoints.expenseDetail(id));

  // Summary
  static Future<ApiResponse> getSummary({String? from, String? to, String? petId}) {
    final params = <String>[];
    if (from != null) params.add('from=$from');
    if (to != null) params.add('to=$to');
    if (petId != null) params.add('petId=$petId');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    return _client.get('${Endpoints.expenseSummary}$query');
  }

  // Calendar
  static Future<ApiResponse> getCalendar({required String month, String? petId}) {
    final params = <String>['month=$month'];
    if (petId != null) params.add('petId=$petId');
    final query = '?${params.join('&')}';
    return _client.get('${Endpoints.expenseCalendar}$query');
  }

  // Dashboard Aggregator (Replaces Summary & Calendar & Recent)
  static Future<ApiResponse> getAggregatedDashboard({String? month}) {
    final query = month != null ? '?month=$month' : '';
    return _client.get('/api/expenses/dashboard/aggregated$query');
  }

  // Day detail
  static Future<ApiResponse> getDayDetail({required String date, String? petId}) {
    final params = <String>['date=$date'];
    if (petId != null) params.add('petId=$petId');
    final query = '?${params.join('&')}';
    return _client.get('${Endpoints.expenseDay}$query');
  }
}
