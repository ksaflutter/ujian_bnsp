import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors_lokin.dart';
import '../../core/utils/location_helper_lokin.dart';

class AttendanceMapWidget extends StatefulWidget {
  final Function(double lat, double lng, String address)? onLocationSelected;
  final bool showCurrentLocation;
  final double? initialLat;
  final double? initialLng;

  const AttendanceMapWidget({
    super.key,
    this.onLocationSelected,
    this.showCurrentLocation = true,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<AttendanceMapWidget> createState() => _AttendanceMapWidgetState();
}

class _AttendanceMapWidgetState extends State<AttendanceMapWidget> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = LatLng(
      LocationHelperLokin.defaultLatitude,
      LocationHelperLokin
          .defaultLongitude); // Default to Jakarta using LocationHelper
  String _currentAddress = "Mendapatkan lokasi...";
  Marker? _selectedMarker;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    // Set initial position based on parameters
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
    }

    // Get address for initial position
    final address = await LocationHelperLokin.getAddressFromCoordinates(
      _currentPosition.latitude,
      _currentPosition.longitude,
    );

    if (mounted) {
      setState(() {
        _currentAddress = address;
        _selectedMarker = Marker(
          markerId: const MarkerId('selected_location'),
          position: _currentPosition,
          infoWindow: InfoWindow(
            title: 'Lokasi Dipilih',
            snippet: address,
          ),
        );
      });

      // Notify parent widget about initial location
      widget.onLocationSelected?.call(
        _currentPosition.latitude,
        _currentPosition.longitude,
        address,
      );
    }

    // Get current location if enabled
    if (widget.showCurrentLocation) {
      await _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check permissions using the correct method
      final permissionStatus =
          await LocationHelperLokin.getLocationPermissionStatus();
      if (!permissionStatus['canGetLocation']) {
        // If can't get location, request permission
        if (permissionStatus['needsPermission']) {
          final permission =
              await LocationHelperLokin.requestLocationPermission();
          if (permission != LocationPermission.whileInUse &&
              permission != LocationPermission.always) {
            throw Exception('Location permission denied');
          }
        } else {
          throw Exception('Location service not available');
        }
      }

      // Get current position
      final position = await LocationHelperLokin.getCurrentPosition();
      final address = await LocationHelperLokin.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentAddress = address;
          _selectedMarker = Marker(
            markerId: const MarkerId('selected_location'),
            position: _currentPosition,
            infoWindow: InfoWindow(
              title: 'Lokasi Saat Ini',
              snippet: address,
            ),
          );
        });

        // Move camera to current location
        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 16),
        );

        // Notify parent widget
        widget.onLocationSelected?.call(
          _currentPosition.latitude,
          _currentPosition.longitude,
          address,
        );
      }
    } catch (e) {
      // If failed to get current location, use default Jakarta location
      if (mounted) {
        final address = await LocationHelperLokin.getAddressFromCoordinates(
          LocationHelperLokin.defaultLatitude,
          LocationHelperLokin.defaultLongitude,
        );

        setState(() {
          _currentPosition = LatLng(
            LocationHelperLokin.defaultLatitude,
            LocationHelperLokin.defaultLongitude,
          );
          _currentAddress = address;
          _selectedMarker = Marker(
            markerId: const MarkerId('selected_location'),
            position: _currentPosition,
            infoWindow: InfoWindow(
              title: 'Lokasi Default',
              snippet: address,
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    final address = await LocationHelperLokin.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (mounted) {
      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _selectedMarker = Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: InfoWindow(
            title: 'Lokasi Dipilih',
            snippet: address,
          ),
        );
      });

      // Notify parent widget
      widget.onLocationSelected?.call(
        position.latitude,
        position.longitude,
        address,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorsLokin.primary.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: _onMapTap,
              markers: _selectedMarker != null ? {_selectedMarker!} : {},
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
            ),

            // Get current location button (top right)
            if (widget.showCurrentLocation)
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.small(
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                  backgroundColor: Colors.white,
                  child: _isGettingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: AppColorsLokin.primary,
                        ),
                ),
              ),

            // Address info (bottom)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColorsLokin.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentAddress,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Coordinates info (bottom left)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_currentPosition.latitude.toStringAsFixed(6)}, ${_currentPosition.longitude.toStringAsFixed(6)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontFamily: 'Courier',
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Usage widget for attendance screens
class AttendanceLocationSelector extends StatefulWidget {
  final Function(double lat, double lng, String address) onLocationConfirmed;
  final String title;
  final String subtitle;

  const AttendanceLocationSelector({
    super.key,
    required this.onLocationConfirmed,
    this.title = 'Pilih Lokasi Absensi',
    this.subtitle = 'Pastikan lokasi sudah sesuai sebelum melanjutkan',
  });

  @override
  State<AttendanceLocationSelector> createState() =>
      _AttendanceLocationSelectorState();
}

class _AttendanceLocationSelectorState
    extends State<AttendanceLocationSelector> {
  double? _selectedLat;
  double? _selectedLng;
  String? _selectedAddress;
  bool _locationSelected = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Set default to Jakarta immediately
    _selectedLat = LocationHelperLokin.defaultLatitude;
    _selectedLng = LocationHelperLokin.defaultLongitude;
    _selectedAddress = "Jakarta, Indonesia (Default)";
    _locationSelected = true;
  }

  void _onLocationSelected(double lat, double lng, String address) {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _selectedAddress = address;
      _locationSelected = true;
    });
  }

  Future<void> _confirmLocation() async {
    if (_isProcessing) return;

    if (_locationSelected &&
        _selectedLat != null &&
        _selectedLng != null &&
        _selectedAddress != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Tutup dialog terlebih dahulu
        Navigator.of(context).pop();

        // Panggil callback SETELAH dialog tertutup
        await Future.delayed(const Duration(milliseconds: 100));

        widget.onLocationConfirmed(
          _selectedLat!,
          _selectedLng!,
          _selectedAddress!,
        );
      } catch (e) {
        print('Error in _confirmLocation: $e');
        // Jika ada error, tetap tutup dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColorsLokin.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isProcessing
              ? null
              : () {
                  Navigator.of(context).pop();
                },
        ),
      ),
      body: Column(
        children: [
          // Info panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColorsLokin.primary.withOpacity(0.1),
            child: Column(
              children: [
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColorsLokin.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (_selectedAddress != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lokasi: $_selectedAddress',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColorsLokin.primary,
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          // Map
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AttendanceMapWidget(
                onLocationSelected: _onLocationSelected,
                showCurrentLocation: true,
                initialLat: LocationHelperLokin.defaultLatitude,
                initialLng: LocationHelperLokin.defaultLongitude,
              ),
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_locationSelected && !_isProcessing)
                    ? _confirmLocation
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLokin.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Konfirmasi Lokasi',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
