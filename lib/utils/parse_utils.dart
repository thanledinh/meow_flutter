/// Safe number parsing — API sometimes returns strings instead of numbers
double toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int toInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Extract list from API response data (handles both List and Map with nested 'data')
List<dynamic> toList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    // Try common response patterns
    final d = data['data'];
    if (d is List) return d;
    if (d is Map) {
      if (d['items'] is List) return d['items'];
      if (d['data'] is List) return d['data'];
      if (d['results'] is List) return d['results'];
    }
    if (data['items'] is List) return data['items'];
    if (data['results'] is List) return data['results'];
  }
  return [];
}

/// Format số tiền VND: 1000000 → "1.000.000đ"
String formatVND(dynamic value) {
  final n = toDouble(value).round();
  final s = n.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}${buf}đ';
}
