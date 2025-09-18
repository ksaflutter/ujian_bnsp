import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationHelperLokin {
  // Jakarta coordinates as default
  static const double defaultLatitude = -6.2088;
  static const double defaultLongitude = 106.8456;
  static const double locationAccuracy = 100.0; // meters

  // Get default position (Jakarta)
  static Position getDefaultPosition() {
    return Position(
      latitude: defaultLatitude,
      longitude: defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: locationAccuracy,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

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

  // Get current position with error handling and Jakarta fallback
  static Future<Position> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location service disabled, using Jakarta default');
        return getDefaultPosition();
      }

      // Check and request permission
      LocationPermission permission = await checkLocationPermission();
      if (permission == LocationPermission.denied) {
        permission = await requestLocationPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied, using Jakarta default');
          return getDefaultPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission permanently denied, using Jakarta default');
        return getDefaultPosition();
      }

      // Get current position with timeout
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        print(
            'Got current location: ${position.latitude}, ${position.longitude}');
        return position;
      } catch (e) {
        print('High accuracy failed, trying medium accuracy: $e');
        // If high accuracy fails, try with medium accuracy
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 15),
          );
          print(
              'Got current location with medium accuracy: ${position.latitude}, ${position.longitude}');
          return position;
        } catch (e) {
          print('Medium accuracy failed, using Jakarta default: $e');
          return getDefaultPosition();
        }
      }
    } catch (e) {
      print('Error getting current location, using Jakarta default: $e');
      return getDefaultPosition();
    }
  }

  // Get address from coordinates with Jakarta fallback
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

        String address = addressParts.isNotEmpty
            ? addressParts.join(', ')
            : 'Unknown Location';

        // Check if we're using Jakarta default coordinates
        if (_isJakartaDefault(latitude, longitude)) {
          return 'Jakarta, Indonesia (Default Location)';
        }

        return address;
      }

      // Check if we're using Jakarta default coordinates
      if (_isJakartaDefault(latitude, longitude)) {
        return 'Jakarta, Indonesia (Default Location)';
      }

      return 'Unknown Location';
    } catch (e) {
      print('Error getting address: $e');
      // Check if we're using Jakarta default coordinates
      if (_isJakartaDefault(latitude, longitude)) {
        return 'Jakarta, Indonesia (Default Location)';
      }
      return 'Failed to get address';
    }
  }

  // Helper method to check if coordinates are Jakarta default
  static bool _isJakartaDefault(double latitude, double longitude) {
    const double tolerance =
        0.001; // Small tolerance for floating point comparison
    return (latitude - defaultLatitude).abs() < tolerance &&
        (longitude - defaultLongitude).abs() < tolerance;
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

  // Get last known position with Jakarta fallback
  static Future<Position?> getLastKnownPosition() async {
    try {
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        print(
            'Got last known position: ${lastKnown.latitude}, ${lastKnown.longitude}');
        return lastKnown;
      } else {
        print('No last known position, using Jakarta default');
        return getDefaultPosition();
      }
    } catch (e) {
      print('Error getting last known position, using Jakarta default: $e');
      return getDefaultPosition();
    }
  }

  // Get position with fallback to last known, then Jakarta default
  static Future<Position> getPositionWithFallback() async {
    try {
      return await getCurrentPosition();
    } catch (e) {
      print('getCurrentPosition failed: $e');
      Position? lastKnown = await getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      print('Using Jakarta default as final fallback');
      return getDefaultPosition();
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
