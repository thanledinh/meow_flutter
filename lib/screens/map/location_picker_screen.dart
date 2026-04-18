import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../config/theme.dart';
import '../../widgets/moew_loading.dart';
import '../../widgets/toast.dart';
import '../../config/secrets.dart';

const String _mapboxToken = mapboxSecretToken;
const String _geocodeUrl = 'https://api.mapbox.com/geocoding/v5/mapbox.places';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MapboxMap? _mapboxMap;
  bool _loading = true;
  bool _parsing = false;
  
  double _currentLat = 10.8;
  double _currentLng = 106.7;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentLat = widget.initialLat!;
      _currentLng = widget.initialLng!;
      _loading = false;
    } else {
      _getLocation();
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
      if (mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLng = pos.longitude;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onMapCreated(MapboxMap map) {
    _mapboxMap = map;
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(_currentLng, _currentLat)),
        zoom: 16,
      ),
      MapAnimationOptions(duration: 800),
    );
  }

  Future<void> _confirmLocation() async {
    setState(() => _parsing = true);
    try {
      final camera = await _mapboxMap?.getCameraState();
      if (camera == null) {
        MoewToast.show(context, message: 'Bản đồ chưa sẵn sàng', type: ToastType.error);
        setState(() => _parsing = false);
        return;
      }
      
      final double lat = camera.center.coordinates.lat.toDouble();
      final double lng = camera.center.coordinates.lng.toDouble();
      
      final url = '$_geocodeUrl/$lng,$lat.json?access_token=$_mapboxToken&language=vi';
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data['features'] != null && (data['features'] as List).isNotEmpty) {
        final features = data['features'] as List;
        
        String placeName = features[0]['place_name']?.toString() ?? '';
        List<String> parts = placeName.split(',').map((e) => e.trim()).toList();
        
        // Loại bỏ quốc gia và mã bưu điện (Vietnam, 700000)
        parts.removeWhere((p) => p.toLowerCase() == 'vietnam' || p.toLowerCase() == 'việt nam' || int.tryParse(p.replaceAll(' ', '')) != null);
        
        String address = '';
        String ward = '';
        String district = '';
        String city = '';

        if (parts.isNotEmpty) {
          if (parts.length >= 4) {
            city = parts.removeLast();
            district = parts.removeLast();
            ward = parts.removeLast();
            address = parts.join(', ');
          } else if (parts.length == 3) {
            city = parts.removeLast();
            district = parts.removeLast();
            address = parts.removeLast();
          } else if (parts.length == 2) {
            city = parts.removeLast();
            address = parts.removeLast();
          } else {
            address = parts.first;
          }
        }

        if (!mounted) return;
        Navigator.pop(context, {
          'address': address,
          'ward': ward,
          'district': district,
          'city': city,
          'latitude': _currentLat,
          'longitude': _currentLng,
        });
      } else {
        MoewToast.show(context, message: 'Không thể giải mã toạ độ này', type: ToastType.error);
        setState(() => _parsing = false);
      }
    } catch (e) {
      if (!mounted) return;
      MoewToast.show(context, message: 'Lỗi lấy địa chỉ: $e', type: ToastType.error);
      setState(() => _parsing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: MoewColors.background,
        body: const MoewLoading(message: 'Đang mở bản đồ...'),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          MapWidget(
            key: const ValueKey('location_picker_mapbox'),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(_currentLng, _currentLat)),
              zoom: 16,
            ),
            onMapCreated: _onMapCreated,
          ),
          
          // Center Marker Crosshair
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30), // Offset slightly to point the pin exactly
              child: Icon(Icons.location_on, size: 40, color: MoewColors.primary),
            ),
          ),
          
          // Back UI
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: MoewShadows.card),
                child: Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
          ),

          // Action bottom
          Positioned(
            bottom: 24, left: 24, right: 24,
            child: ElevatedButton(
              onPressed: _parsing ? null : _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: MoewColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.lg)),
                elevation: 4,
              ),
              child: _parsing 
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Chốt địa điểm này', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
