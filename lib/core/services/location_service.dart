import 'dart:async';
import 'dart:math' as math;

import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

/// Titik koordinat ringkas (lat, lng) yang netral dari plugin.
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  bool get isValid => latitude != 0 || longitude != 0;
}

/// Service lokasi real-time: izin, posisi saat ini, stream live, dan jarak haversine.
class LocationService {
  static const _defaultSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
    timeLimit: Duration(seconds: 20),
  );

  /// Minta & cek izin lokasi. Kembalikan true bila siap dipakai.
  Future<bool> ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Ambil posisi saat ini satu kali.
  Future<LatLng?> getCurrentPosition() async {
    if (!await ensurePermission()) return null;
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: _defaultSettings,
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Stream posisi live (update ~2 dtk sementara bergerak).
  Stream<LatLng> positionStream() {
    final controller = StreamController<LatLng>();
    StreamSubscription<Position>? sub;
    Geolocator.requestPermission().then((permission) async {
      if (permission == LocationPermission.denied) {
        controller.close();
        return;
      }
      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
          timeLimit: Duration(seconds: 30),
        ),
      ).listen(
        (p) {
          if (!controller.isClosed) {
            controller.add(LatLng(p.latitude, p.longitude));
          }
        },
        onError: (_) {
          if (!controller.isClosed) controller.close();
        },
        onDone: () {
          if (!controller.isClosed) controller.close();
        },
      );
    });
    controller.onCancel = () {
      sub?.cancel();
    };
    return controller.stream;
  }

  /// Konversi koordinat → nama tempat (mis. "Jakarta Selatan"). Null bila gagal.
  Future<String?> placeName(LatLng p) async {
    try {
      final list = await geo
          .placemarkFromCoordinates(p.latitude, p.longitude);
      if (list.isEmpty) return null;
      final m = list.first;
      final locality = m.locality ?? m.subAdministrativeArea ?? m.administrativeArea;
      if (locality != null && locality.isNotEmpty) return locality;
      final sub = m.subLocality;
      if (sub != null && sub.isNotEmpty) return sub;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Jarak haversine dua koordinat dalam kilometer.
  static double distanceKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final sin2Lat = math.pow(math.sin(dLat / 2), 2).toDouble();
    final sin2Lng = math.pow(math.sin(dLng / 2), 2).toDouble();
    final h = sin2Lat + math.cos(lat1) * math.cos(lat2) * sin2Lng;
    final c = 2 * math.asin(math.sqrt(math.min(1, h)));
    return r * c;
  }

  static double _rad(double deg) => deg * 3.141592653589793 / 180;
}