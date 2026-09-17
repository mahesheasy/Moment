import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MomentContextSnapshot {
  const MomentContextSnapshot({
    required this.timeLabel,
    this.locationLabel,
    this.weatherLabel,
  });

  final String timeLabel;
  final String? locationLabel;
  final String? weatherLabel;
}

class MomentContextService {
  Future<MomentContextSnapshot> load() async {
    final timeLabel = _formatTime(DateTime.now());
    String? locationLabel;
    String? weatherLabel;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );

        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          locationLabel = _formatPlace(placemarks.first);
        }

        weatherLabel = await _fetchWeather(
          position.latitude,
          position.longitude,
        );
      }
    } on Object {
      // Location/weather are optional enrichments.
    }

    return MomentContextSnapshot(
      timeLabel: timeLabel,
      locationLabel: locationLabel,
      weatherLabel: weatherLabel,
    );
  }

  static String? _formatPlace(Placemark place) {
    final parts = <String>[];
    for (final part in [
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ]) {
      final trimmed = part?.trim();
      if (trimmed != null &&
          trimmed.isNotEmpty &&
          !parts.contains(trimmed)) {
        parts.add(trimmed);
      }
    }
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Future<String?> _fetchWeather(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,weather_code,relative_humidity_2m'
      '&timezone=auto',
    );

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != 200) return null;
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final temp = current['temperature_2m'];
      final code = current['weather_code'] as int?;
      if (temp == null) return null;

      final rounded = (temp as num).round();
      final label = _weatherLabelForCode(code);
      return '$rounded°C · $label';
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static String _weatherLabelForCode(int? code) {
    return switch (code) {
      0 => 'Clear',
      1 || 2 || 3 => 'Partly cloudy',
      45 || 48 => 'Foggy',
      51 || 53 || 55 || 56 || 57 => 'Drizzle',
      61 || 63 || 65 || 66 || 67 => 'Rain',
      71 || 73 || 75 || 77 => 'Snow',
      80 || 81 || 82 => 'Showers',
      95 || 96 || 99 => 'Storm',
      _ => 'Cloudy',
    };
  }
}
