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
  LatLng _currentPosition = LatLng(-6.200000, 106.816666); // Default to Jakarta
  String _currentAddress = "Mendapatkan lokasi...";
  Marker? _marker;
  bool _isLoading = true;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      if (widget.initialLat != null && widget.initialLng != null) {
        _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
        await _updateLocationInfo();
      } else if (widget.showCurrentLocation) {
        await _getCurrentLocation();
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal mendapatkan lokasi";
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permission
      final permissionStatus =
          await LocationHelperLokin.getLocationPermissionStatus();

      if (!permissionStatus['canGetLocation']) {
        if (permissionStatus['needsPermission']) {
          final permission =
              await LocationHelperLokin.requestLocationPermission();
          if (permission != LocationPermission.whileInUse &&
              permission != LocationPermission.always) {
            throw Exception('Izin lokasi diperlukan untuk absensi');
          }
        } else {
          throw Exception('Layanan lokasi tidak tersedia');
        }
      }

      // Get current position
      final position = await LocationHelperLokin.getCurrentPosition();
      _currentPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _hasLocationPermission = true;
      });

      await _updateLocationInfo();
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal mendapatkan lokasi: ${e.toString()}";
        _isLoading = false;
        _hasLocationPermission = false;
      });
    }
  }

  Future<void> _updateLocationInfo() async {
    try {
      // Get address from coordinates
      final address = await LocationHelperLokin.getAddressFromCoordinates(
        _currentPosition.latitude,
        _currentPosition.longitude,
      );

      setState(() {
        _marker = Marker(
          markerId: const MarkerId("current_location"),
          position: _currentPosition,
          infoWindow: InfoWindow(
            title: 'Lokasi Anda',
            snippet: address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
        _currentAddress = address;
        _isLoading = false;
      });

      // Notify parent widget
      widget.onLocationSelected?.call(
        _currentPosition.latitude,
        _currentPosition.longitude,
        address,
      );

      // Move camera to current position
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 16),
        ),
      );
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal mendapatkan alamat";
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Move to current position if available
    if (!_isLoading) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 16),
        ),
      );
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _currentPosition = position;
      _isLoading = true;
    });

    _updateLocationInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorsLokin.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 12,
              ),
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              markers: _marker != null ? {_marker!} : {},
              zoomControlsEnabled: false,
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),

            // Top info panel
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColorsLokin.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lokasi Absensi',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColorsLokin.textPrimary,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentAddress,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColorsLokin.textSecondary,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Control buttons
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  // Get current location button
                  if (widget.showCurrentLocation)
                    FloatingActionButton(
                      heroTag: "current_location",
                      mini: true,
                      backgroundColor: AppColorsLokin.primary,
                      onPressed: _getCurrentLocation,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                  if (widget.showCurrentLocation) const SizedBox(height: 8),

                  // Zoom in button
                  FloatingActionButton(
                    heroTag: "zoom_in",
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.add,
                      color: AppColorsLokin.textPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomIn());
                    },
                  ),

                  const SizedBox(height: 8),

                  // Zoom out button
                  FloatingActionButton(
                    heroTag: "zoom_out",
                    mini: true,
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.remove,
                      color: AppColorsLokin.textPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.zoomOut());
                    },
                  ),
                ],
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

  void _onLocationSelected(double lat, double lng, String address) {
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
      _selectedAddress = address;
      _locationSelected = true;
    });
  }

  void _confirmLocation() {
    if (_locationSelected &&
        _selectedLat != null &&
        _selectedLng != null &&
        _selectedAddress != null) {
      widget.onLocationConfirmed(
          _selectedLat!, _selectedLng!, _selectedAddress!);
      Navigator.of(context).pop();
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
              ),
            ),
          ),

          // Confirm button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _locationSelected ? _confirmLocation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsLokin.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Konfirmasi Lokasi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
