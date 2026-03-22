import 'api_client.dart';
import 'endpoints.dart';

class WalletApi {
  static final _client = ApiClient();

  /// Xem ví (balance + debt + transactions)
  static Future<ApiResponse> get() => _client.get(Endpoints.wallet);

  /// Nạp tiền
  static Future<ApiResponse> topup(double amount) =>
      _client.post(Endpoints.walletTopup, {'amount': amount});

  /// Trả nợ
  static Future<ApiResponse> repay(double amount) =>
      _client.post(Endpoints.walletRepay, {'amount': amount});
}
