import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../config/theme.dart';

import '../../config/secrets.dart';
const String _mapboxToken = mapboxSecretToken;
const String _geocodeUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';
const String _directionsUrl = 'https://api.mapbox.com/directions/v5/mapbox';

class _TravelMode {
  final String key, label;
  final IconData icon;
  final Color color;
  const _TravelMode(this.key, this.label, this.icon, this.color);
}

const _travelModes = [
  _TravelMode('driving', 'Xe', Icons.directions_car, Color(0xFF4285F4)),
  _TravelMode('walking', 'Đi bộ', Icons.directions_walk, Color(0xFF34A853)),
  _TravelMode('cycling', 'Xe đạp', Icons.directions_bike, Color(0xFFEA4335)),
];

class GuardianMapScreen extends StatefulWidget {
  final Map<String, dynamic>? destination;
  const GuardianMapScreen({super.key, this.destination});
  @override
  State<GuardianMapScreen> createState() => _GuardianMapScreenState();
}

class _GuardianMapScreenState extends State<GuardianMapScreen> {
  MapboxMap? _mapboxMap;
  geo.Position? _userLocation;
  bool _loading = true;
  bool _followMode = false;
  bool _autoNavDone = false;

  // Search
  final _searchCtrl = TextEditingController();
  List<dynamic> _results = [];
  bool _searching = false;
  Timer? _searchTimer;

  // Route
  Map<String, dynamic>? _selectedPlace;
  Map<String, dynamic>? _routeInfo;
  List<Map<String, dynamic>> _routeSteps = [];
  String _travelMode = 'driving';
  bool _loadingRoute = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchTimer?.cancel();
    // Clean up map layers before dispose to prevent Surface crash
    try { _mapboxMap?.style.removeStyleLayer('route-line'); } catch (_) {}
    try { _mapboxMap?.style.removeStyleSource('route-source'); } catch (_) {}
    _mapboxMap = null;
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      geo.LocationPermission perm = await geo.Geolocator.checkPermission();
      if (perm == geo.LocationPermission.denied) {
        perm = await geo.Geolocator.requestPermission();
      }
      if (perm == geo.LocationPermission.deniedForever || perm == geo.LocationPermission.denied) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final pos = await geo.Geolocator.getCurrentPosition(locationSettings: const geo.LocationSettings(accuracy: geo.LocationAccuracy.high));
      if (mounted) setState(() { _userLocation = pos; _loading = false; });
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    if (_userLocation != null) {
      _mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(_userLocation!.longitude, _userLocation!.latitude)),
          zoom: 15,
        ),
        MapAnimationOptions(duration: 800),
      );
    }
    // Auto-navigate to destination (from ClinicDetail)
    _autoNavigate();
  }

  void _autoNavigate() {
    if (_autoNavDone || widget.destination == null || _userLocation == null) return;
    _autoNavDone = true;
    final dest = widget.destination!;
    final lat = (dest['latitude'] as num).toDouble();
    final lng = (dest['longitude'] as num).toDouble();
    final name = dest['name']?.toString() ?? 'Điểm đến';

    setState(() {
      _selectedPlace = {'lng': lng, 'lat': lat, 'name': name};
      _searchCtrl.text = name;
    });

    _mapboxMap?.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15),
      MapAnimationOptions(duration: 800),
    );

    _getDirections(_userLocation!.longitude, _userLocation!.latitude, lng, lat);
  }

  // ── Search ──
  void _onSearch(String text) {
    _searchTimer?.cancel();
    setState(() { _selectedPlace = null; _routeInfo = null; _routeSteps = []; });
    if (text.trim().length < 2) { setState(() => _results = []); return; }

    _searchTimer = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      try {
        final lng = _userLocation?.longitude ?? 106.7;
        final lat = _userLocation?.latitude ?? 10.8;
        final url = '$_geocodeUrl/${Uri.encodeComponent(text)}.json?access_token=$_mapboxToken&language=vi&limit=8&country=vn&types=poi,address,neighborhood,locality,place&proximity=$lng,$lat&fuzzyMatch=true';
        final res = await http.get(Uri.parse(url));
        final data = jsonDecode(res.body);
        if (mounted) setState(() => _results = data['features'] ?? []);
      } catch (e) { debugPrint('Search error: $e'); }
      if (mounted) setState(() => _searching = false);
    });
  }

  Future<void> _selectPlace(Map<String, dynamic> place) async {
    final coords = place['center'] as List;
    final lng = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    final name = place['place_name']?.toString() ?? '';

    setState(() {
      _selectedPlace = {'lng': lng, 'lat': lat, 'name': name};
      _searchCtrl.text = name;
      _results = [];
    });
    FocusScope.of(context).unfocus();

    _mapboxMap?.flyTo(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 16),
      MapAnimationOptions(duration: 1000),
    );

    if (_userLocation != null) {
      await _getDirections(_userLocation!.longitude, _userLocation!.latitude, lng, lat);
    }
  }

  // ── Directions ──
  Future<void> _getDirections(double fromLng, double fromLat, double toLng, double toLat, [String? mode]) async {
    setState(() => _loadingRoute = true);
    try {
      final m = mode ?? _travelMode;
      final url = '$_directionsUrl/$m/$fromLng,$fromLat;$toLng,$toLat?geometries=geojson&overview=full&steps=true&language=vi&access_token=$_mapboxToken';
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final distance = (route['distance'] as num).toDouble();
        final duration = (route['duration'] as num).toDouble();

        final rawSteps = route['legs']?[0]?['steps'] as List? ?? [];
        final steps = rawSteps
            .where((s) => s['maneuver']?['instruction'] != null && s['maneuver']['instruction'].toString().isNotEmpty)
            .map<Map<String, dynamic>>((s) => {
              'instruction': s['maneuver']['instruction'].toString(),
              'distance': (s['distance'] as num?)?.toDouble() ?? 0.0,
              'type': s['maneuver']?['type']?.toString() ?? '',
              'modifier': s['maneuver']?['modifier']?.toString() ?? '',
            })
            .toList();

        await _drawRoute(route['geometry']);

        if (mounted) {
          setState(() {
            _routeInfo = {'distance': distance, 'duration': duration, 'eta': DateTime.now().add(Duration(seconds: duration.round()))};
            _routeSteps = steps;
          });
        }
      }
    } catch (e) { debugPrint('Direction error: $e'); }
    if (mounted) setState(() => _loadingRoute = false);
  }

  Future<void> _drawRoute(Map<String, dynamic> geometry) async {
    try { await _mapboxMap?.style.removeStyleLayer('route-line'); } catch (_) {}
    try { await _mapboxMap?.style.removeStyleSource('route-source'); } catch (_) {}

    final geojson = jsonEncode({
      'type': 'FeatureCollection',
      'features': [{'type': 'Feature', 'geometry': geometry, 'properties': <String, dynamic>{}}],
    });

    final modeColor = _travelModes.firstWhere((m) => m.key == _travelMode).color;
    final colorInt = (0xFF << 24) | ((modeColor.r * 255).round() << 16) | ((modeColor.g * 255).round() << 8) | (modeColor.b * 255).round();

    await _mapboxMap?.style.addSource(GeoJsonSource(id: 'route-source', data: geojson));
    await _mapboxMap?.style.addLayer(LineLayer(
      id: 'route-line',
      sourceId: 'route-source',
      lineColor: colorInt,
      lineWidth: 5.0,
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
    ));
  }

  void _switchMode(String mode) {
    setState(() => _travelMode = mode);
    if (_userLocation != null && _selectedPlace != null) {
      _getDirections(_userLocation!.longitude, _userLocation!.latitude, _selectedPlace!['lng'], _selectedPlace!['lat'], mode);
    }
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() { _results = []; _selectedPlace = null; _routeInfo = null; _routeSteps = []; _followMode = false; });
    try { _mapboxMap?.style.removeStyleLayer('route-line'); } catch (_) {}
    try { _mapboxMap?.style.removeStyleSource('route-source'); } catch (_) {}
    FocusScope.of(context).unfocus();
  }

  void _recenter() {
    if (_userLocation != null) {
      _mapboxMap?.flyTo(
        CameraOptions(center: Point(coordinates: Position(_userLocation!.longitude, _userLocation!.latitude)), zoom: 17),
        MapAnimationOptions(duration: 600),
      );
    }
  }

  // ── Formatting ──
  String _fmtDistance(double m) => m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.round()} m';
  String _fmtDuration(double s) {
    final mins = (s / 60).round();
    if (mins < 60) return '$mins phút';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return '$hrs h${rem > 0 ? ' ${rem}p' : ''}';
  }
  String _fmtETA(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  IconData _stepIcon(String type, String modifier) {
    if (type == 'turn' && modifier.contains('left')) return Icons.turn_left;
    if (type == 'turn' && modifier.contains('right')) return Icons.turn_right;
    if (type == 'arrive') return Icons.flag;
    if (type == 'depart') return Icons.navigation;
    if (type == 'roundabout') return Icons.sync;
    return Icons.arrow_upward;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: MoewColors.background,
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(color: MoewColors.primary),
          const SizedBox(height: 16),
          Text('Đang lấy vị trí...', style: MoewTextStyles.caption),
        ])),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      },
      child: Scaffold(
      body: Stack(children: [
        // ── MAP ──
        MapWidget(
          key: const ValueKey('mapbox'),
          styleUri: MapboxStyles.MAPBOX_STREETS,
          cameraOptions: CameraOptions(
            center: _userLocation != null
                ? Point(coordinates: Position(_userLocation!.longitude, _userLocation!.latitude))
                : Point(coordinates: Position(106.7, 10.8)),
            zoom: 15,
          ),
          onMapCreated: _onMapCreated,
        ),

        // ── SEARCH BAR ──
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 12, right: 12,
          child: Column(children: [
            Row(children: [
              _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
              const SizedBox(width: 8),
              Expanded(child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                child: Row(children: [
                  const Icon(Icons.search, size: 18, color: MoewColors.textSub),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: const InputDecoration(
                      hintText: 'Tìm địa chỉ, phòng khám...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 15, color: MoewColors.textMain),
                  )),
                  if (_searching) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: MoewColors.primary)),
                  if (!_searching && _searchCtrl.text.isNotEmpty)
                    GestureDetector(onTap: _clearAll, child: const Icon(Icons.cancel, size: 20, color: MoewColors.textSub)),
                ]),
              )),
            ]),
            if (_results.isNotEmpty) Container(
              margin: const EdgeInsets.only(top: 4, left: 52),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: MoewColors.border.withValues(alpha: 0.3)),
                itemBuilder: (_, i) {
                  final item = _results[i] as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, size: 18, color: MoewColors.primary),
                    title: Text(item['text']?.toString() ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    subtitle: Text(item['place_name']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: MoewColors.textSub), overflow: TextOverflow.ellipsis),
                    onTap: () => _selectPlace(item),
                  );
                },
              ),
            ),
          ]),
        ),

        // ── RECENTER ──
        Positioned(
          right: 16,
          bottom: _routeInfo != null ? 360 : 32,
          child: _circleBtn(
            _followMode ? Icons.navigation : Icons.my_location,
            _recenter,
            active: _followMode,
          ),
        ),

        // ── ROUTE INFO CARD ──
        if (_routeInfo != null && _selectedPlace != null)
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(MoewRadius.xl), boxShadow: MoewShadows.card),
              constraints: const BoxConstraints(maxHeight: 340),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Travel modes
                Row(children: [
                  ..._travelModes.map((m) => GestureDetector(
                    onTap: () => _switchMode(m.key),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _travelMode == m.key ? m.color.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(m.icon, size: 18, color: _travelMode == m.key ? m.color : MoewColors.textSub),
                        const SizedBox(width: 4),
                        Text(m.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _travelMode == m.key ? m.color : MoewColors.textSub)),
                      ]),
                    ),
                  )),
                  const Spacer(),
                  GestureDetector(onTap: _clearAll, child: const Icon(Icons.close, size: 20, color: MoewColors.textSub)),
                ]),
                const Divider(height: 16),

                // Duration + distance
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_fmtDuration(_routeInfo!['duration']), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _travelModes.firstWhere((m) => m.key == _travelMode).color)),
                    Text(_fmtDistance(_routeInfo!['distance']), style: const TextStyle(fontSize: 13, color: MoewColors.textSub, fontWeight: FontWeight.w600)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.access_time, size: 14, color: MoewColors.textSub),
                      const SizedBox(width: 4),
                      Text('Đến lúc ${_fmtETA(_routeInfo!['eta'])}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),

                // Destination
                Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: MoewColors.danger, borderRadius: BorderRadius.circular(5))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_selectedPlace!['name'], style: const TextStyle(fontSize: 13, color: MoewColors.textMain), maxLines: 2)),
                ]),

                // Steps
                if (_routeSteps.isNotEmpty) ...[
                  const Divider(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _routeSteps.length > 8 ? 8 : _routeSteps.length,
                      itemBuilder: (_, i) {
                        final step = _routeSteps[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: MoewColors.tintBlue, borderRadius: BorderRadius.circular(14)),
                              child: Icon(_stepIcon(step['type'], step['modifier']), size: 14, color: MoewColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(step['instruction'], style: const TextStyle(fontSize: 12, color: MoewColors.textMain), maxLines: 2)),
                            Text(_fmtDistance(step['distance']), style: const TextStyle(fontSize: 11, color: MoewColors.textSub, fontWeight: FontWeight.w600)),
                          ]),
                        );
                      },
                    ),
                  ),
                ],

                if (_loadingRoute) const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: MoewColors.primary)),
                ),
              ]),
            ),
          ),
      ]),
    )); // PopScope + Scaffold
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: active ? MoewColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: MoewShadows.card,
        ),
        child: Icon(icon, size: 22, color: active ? Colors.white : MoewColors.primary),
      ),
    );
  }
}
