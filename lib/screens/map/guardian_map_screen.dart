import 'dart:async';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../widgets/moew_loading.dart';
import '../../api/clinic_api.dart'; // Thêm API Clinics

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

  // Markers
  PointAnnotationManager? _pointAnnotationManager;
  final Map<String, dynamic> _annotationDataMap = {};

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
    // Không nên gọi removeStyleLayer trong dispose vì MapboxView đang bị huỷ bởi OS
    // gây ra PlatformException / C++ crash.
    _mapboxMap = null;
    super.dispose();
  }

  Future<void> _safeCleanRoute() async {
    if (_mapboxMap == null) return;
    try {
      if (await _mapboxMap!.style.styleLayerExists('route-line')) {
        await _mapboxMap!.style.removeStyleLayer('route-line');
      }
      if (await _mapboxMap!.style.styleSourceExists('route-source')) {
        await _mapboxMap!.style.removeStyleSource('route-source');
      }
    } catch (e) {
      debugPrint('Mapbox clean route ignore error: $e');
    }
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
    // Add annotations manager
    map.annotations.createPointAnnotationManager().then((manager) {
      _pointAnnotationManager = manager;
      _pointAnnotationManager!.addOnPointAnnotationClickListener(_AnnotationClickListener((annotation) {
        final data = _annotationDataMap[annotation.id];
        if (data != null) {
          _showClinicBottomSheet(data);
        }
      }));
      _loadMarkers();
    });

    // Auto-navigate to destination (from ClinicDetail)
    _autoNavigate();
  }

  Future<void> _loadMarkers() async {
    try {
      final res = await ClinicApi.getMarkers();
      if (!res.success || res.data?['data'] == null) return;
      final list = res.data!['data'] as List;

      final optionsList = <PointAnnotationOptions>[];
      final clinicList = <Map<String, dynamic>>[];

      for (var item in list) {
        final lat = (item['lat'] as num?)?.toDouble();
        final lng = (item['lng'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        // Giảm kích thước xuống 80 để chống loạn (như user y/c bấm nhầm)
        final avatarUrl = item['avatar']?.toString() ?? '';
        final imgBytes = await _createCircularMarker(avatarUrl, size: 70); 

        optionsList.add(PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          image: imgBytes,
          iconAnchor: IconAnchor.BOTTOM,
        ));
        clinicList.add(item);
      }

      if (_pointAnnotationManager != null && optionsList.isNotEmpty) {
        final annotations = await _pointAnnotationManager!.createMulti(optionsList);
        for (var i = 0; i < annotations.length; i++) {
          final ann = annotations[i];
          if (ann?.id != null) {
            _annotationDataMap[ann!.id] = clinicList[i];
          }
        }
      }
    } catch (e) {
      debugPrint('Load markers error: $e');
    }
  }

  Future<Uint8List> _createCircularMarker(String url, {int size = 70}) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
      final ui.Codec codec = await ui.instantiateImageCodec(response.bodyBytes, targetWidth: size, targetHeight: size);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final Paint paint = Paint()..isAntiAlias = true;

      // Draw background/border
      final double radius = size / 2;
      canvas.drawCircle(Offset(radius, radius), radius, Paint()..color = MoewColors.primary);

      // Clip image inside
      final double innerRadius = radius - 4; // 4px border
      canvas.save();
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(radius, radius), radius: innerRadius)));
      canvas.drawImage(image, Offset.zero, paint);
      canvas.restore();

      final ui.Image finalImage = await pictureRecorder.endRecording().toImage(size, size);
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } catch (_) { // Fallback circle if image load fails
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      canvas.drawCircle(Offset(size/2, size/2), size/2, Paint()..color = MoewColors.primary);
      final ui.Image img = await recorder.endRecording().toImage(size, size);
      final ByteData? bData = await img.toByteData(format: ui.ImageByteFormat.png);
      return bData!.buffer.asUint8List();
    }
  }

  void _showClinicBottomSheet(Map<String, dynamic> data) {
    bool isNavigating = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black12,
      builder: (context) {
        return NotificationListener<DraggableScrollableNotification>(
          onNotification: (notification) {
            // Khi kéo thanh trượt vượt 85%, ném qua màn chi tiết
            if (notification.extent >= 0.85 && !isNavigating) {
              isNavigating = true;
              Navigator.pop(context); // Đóng BottomSheet
              context.push('/clinic-detail', extra: data['id']);
            }
            return false;
          },
          child: DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, -5))],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: data['avatar']?.toString() ?? '',
                            width: 80, height: 80, fit: BoxFit.cover,
                            errorWidget: (_,__,___) => Container(width: 80, height: 80, color: Colors.grey[200], child: const Icon(Icons.apartment)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['name']?.toString() ?? 'Phòng Khám', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MoewColors.textMain)),
                              const SizedBox(height: 6),
                              Row(children: [
                                  Icon(Icons.swipe_up, size: 14, color: MoewColors.primary),
                                  SizedBox(width: 4),
                                  Text('Vuốt lên để xem chi tiết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MoewColors.primary)),
                              ]),
                            ],
                          )
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/clinic-detail', extra: data['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MoewColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Xem Chi Tiết Ngay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
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
    await _safeCleanRoute();

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
    _safeCleanRoute();
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
        body: const MoewLoading(message: 'Đang lấy vị trí...'),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
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
              _circleBtn(Icons.arrow_back, () => context.pop()),
              SizedBox(width: 8),
              Expanded(child: Container(
                height: 46,
                padding: EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                child: Row(children: [
                  Icon(Icons.search, size: 18, color: MoewColors.textSub),
                  SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: 'Tìm địa chỉ, phòng khám...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(fontSize: 15, color: MoewColors.textMain),
                  )),
                  if (_searching) SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: MoewColors.primary)),
                  if (!_searching && _searchCtrl.text.isNotEmpty)
                    GestureDetector(onTap: _clearAll, child: Icon(Icons.cancel, size: 20, color: MoewColors.textSub)),
                ]),
              )),
            ]),
            if (_results.isNotEmpty) Container(
              margin: EdgeInsets.only(top: 4, left: 52),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _results.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: MoewColors.border.withValues(alpha: 0.3)),
                itemBuilder: (_, i) {
                  final item = _results[i] as Map<String, dynamic>;
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.location_on_outlined, size: 18, color: MoewColors.primary),
                    title: Text(item['text']?.toString() ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    subtitle: Text(item['place_name']?.toString() ?? '', style: TextStyle(fontSize: 12, color: MoewColors.textSub), overflow: TextOverflow.ellipsis),
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
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(MoewRadius.xl), boxShadow: MoewShadows.card),
              constraints: const BoxConstraints(maxHeight: 340),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Travel modes
                Row(children: [
                  ..._travelModes.map((m) => GestureDetector(
                    onTap: () => _switchMode(m.key),
                    child: Container(
                      margin: EdgeInsets.only(right: 6),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _travelMode == m.key ? m.color.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(m.icon, size: 18, color: _travelMode == m.key ? m.color : MoewColors.textSub),
                        SizedBox(width: 4),
                        Text(m.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _travelMode == m.key ? m.color : MoewColors.textSub)),
                      ]),
                    ),
                  )),
                  Spacer(),
                  GestureDetector(onTap: _clearAll, child: Icon(Icons.close, size: 20, color: MoewColors.textSub)),
                ]),
                const Divider(height: 16),

                // Duration + distance
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_fmtDuration(_routeInfo!['duration']), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _travelModes.firstWhere((m) => m.key == _travelMode).color)),
                    Text(_fmtDistance(_routeInfo!['distance']), style: TextStyle(fontSize: 13, color: MoewColors.textSub, fontWeight: FontWeight.w600)),
                  ]),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.access_time, size: 14, color: MoewColors.textSub),
                      SizedBox(width: 4),
                      Text('Đến lúc ${_fmtETA(_routeInfo!['eta'])}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
                    ]),
                  ),
                ]),
                SizedBox(height: 8),

                // Destination
                Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: MoewColors.danger, borderRadius: BorderRadius.circular(5))),
                  SizedBox(width: 10),
                  Expanded(child: Text(_selectedPlace!['name'], style: TextStyle(fontSize: 13, color: MoewColors.textMain), maxLines: 2)),
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
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: MoewColors.tintBlue, borderRadius: BorderRadius.circular(14)),
                              child: Icon(_stepIcon(step['type'], step['modifier']), size: 14, color: MoewColors.primary),
                            ),
                            SizedBox(width: 8),
                            Expanded(child: Text(step['instruction'], style: TextStyle(fontSize: 12, color: MoewColors.textMain), maxLines: 2)),
                            Text(_fmtDistance(step['distance']), style: TextStyle(fontSize: 11, color: MoewColors.textSub, fontWeight: FontWeight.w600)),
                          ]),
                        );
                      },
                    ),
                  ),
                ],

                if (_loadingRoute) Padding(
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

class _AnnotationClickListener extends OnPointAnnotationClickListener {
  final void Function(PointAnnotation annotation) onAnnotationClick;
  _AnnotationClickListener(this.onAnnotationClick);

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    onAnnotationClick(annotation);
  }
}
