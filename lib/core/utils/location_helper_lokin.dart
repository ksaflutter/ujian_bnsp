import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelperLokin {
  // Jakarta coordinates as default
  static const double defaultLatitude = -6.2088;
  static const double defaultLongitude = 106.8456;
  static const double locationAccuracy = 100.0; // meters

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  static Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  static Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await checkLocationPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  // Get current position with error handling
  static Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException();
    }

    // Check and request permission
    LocationPermission permission = await checkLocationPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestLocationPermission();
      if (permission == LocationPermission.denied) {
        throw PermissionDeniedException('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('Location permission permanently denied');
    }

    // Get current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return position;
    } catch (e) {
      // If high accuracy fails, try with medium accuracy
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
        return position;
      } catch (e) {
        throw LocationException(
          'Failed to get current location: ${e.toString()}',
        );
      }
    }
  }

  // Get address from coordinates
  static Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        return addressParts.isNotEmpty
            ? addressParts.join(', ')
            : 'Unknown Location';
      }

      return 'Unknown Location';
    } catch (e) {
      return 'Failed to get address';
    }
  }

  // Get coordinates from address
  static Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Calculate distance between two points in meters
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Calculate bearing between two points
  static double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Check if location is within radius
  static bool isWithinRadius(
    double centerLatitude,
    double centerLongitude,
    double checkLatitude,
    double checkLongitude,
    double radiusInMeters,
  ) {
    double distance = calculateDistance(
      centerLatitude,
      centerLongitude,
      checkLatitude,
      checkLongitude,
    );

    return distance <= radiusInMeters;
  }

  // Get location stream for real-time tracking
  static Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  // Open location settings
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  // Format coordinates to string
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Parse coordinates from string
  static Map<String, double>? parseCoordinates(String coordinatesString) {
    try {
      List<String> parts = coordinatesString.split(',');
      if (parts.length == 2) {
        double latitude = double.parse(parts[0].trim());
        double longitude = double.parse(parts[1].trim());
        return {'latitude': latitude, 'longitude': longitude};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get location accuracy description
  static String getAccuracyDescription(double accuracy) {
    if (accuracy <= 5) {
      return 'Sangat Akurat';
    } else if (accuracy <= 10) {
      return 'Akurat';
    } else if (accuracy <= 20) {
      return 'Cukup Akurat';
    } else if (accuracy <= 50) {
      return 'Kurang Akurat';
    } else {
      return 'Tidak Akurat';
    }
  }

  // Validate coordinates
  static bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  // Get formatted distance
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  // Check location permission status with detailed result
  static Future<Map<String, dynamic>> getLocationPermissionStatus() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    LocationPermission permission = await checkLocationPermission();

    return {
      'serviceEnabled': serviceEnabled,
      'permission': permission,
      'canGetLocation': serviceEnabled &&
          (permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse),
      'needsPermission': permission == LocationPermission.denied,
      'permanentlyDenied': permission == LocationPermission.deniedForever,
    };
  }

  // Get last known position
  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      return null;
    }
  }

  // Get position with fallback to last known
  static Future<Position> getPositionWithFallback() async {
    try {
      return await getCurrentPosition();
    } catch (e) {
      Position? lastKnown = await getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      rethrow;
    }
  }
}

// Custom exceptions
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

class LocationServiceDisabledException implements Exception {
  @override
  String toString() =>
      'LocationServiceDisabledException: Location services are disabled';
}
