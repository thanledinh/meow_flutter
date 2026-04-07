import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/pet_model.dart';
import '../api/pet_api.dart';
import '../api/local_cache.dart';
import '../api/endpoints.dart';

/// Quản lý dữ liệu Pet (Cache + API + Model Transformation)
/// Giải quyết triệt để lỗi "No Typed Models" & "API Dependency Cao"
class PetRepository extends ChangeNotifier {
  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _error;

  List<PetModel> get pets => _pets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  PetModel? get firstPet => _pets.isNotEmpty ? _pets.first : null;

  /// Load thú cưng ưu tiên local cache (Offline First) sau đó ngầm đồng bộ với server
  Future<void> fetchPets({bool refresh = false}) async {
    if (_pets.isEmpty || refresh) {
      _isLoading = true;
      notifyListeners();
    }

    // 1. Lấy dữ liệu từ Local Cache đưa lên UI trước (Zero Latency)
    final cachedData = await LocalCache.load(Endpoints.pets);
    if (cachedData != null && cachedData['data'] is List) {
      final list = cachedData['data'] as List;
      _pets = list.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
      _isLoading = false;
      notifyListeners();
      
      // Nếu không bắt buộc refresh thì có thể return luôn (tuỳ logic)
      if (!refresh && _pets.isNotEmpty) return;
    }

    // 2. Fetch API ngầm để lấy data mới nhất
    try {
      final res = await PetApi.getAll();
      if (res.success) {
        final resData = res.data as Map<String, dynamic>;
        
        // Lưu đệm lại chuỗi nguyên thủy để dùng offline
        await LocalCache.save(Endpoints.pets, jsonEncode(res.data));
        
        final list = resData['data'] as List? ?? [];
        _pets = list.map((e) => PetModel.fromJson(e as Map<String, dynamic>)).toList();
        _error = null;
      } else {
        _error = res.error;
      }
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Làm mới cưỡng bức
  Future<void> refreshPets() => fetchPets(refresh: true);
}
