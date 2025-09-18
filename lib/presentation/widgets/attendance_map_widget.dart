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
  LatLng _currentPosition = LatLng(LocationHelperLokin.defaultLatitude,
      LocationHelperLokin.defaultLongitude);
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
      // Set default Jakarta position first
      _currentPosition = LatLng(LocationHelperLokin.defaultLatitude,
          LocationHelperLokin.defaultLongitude);

      if (widget.initialLat != null && widget.initialLng != null) {
        _currentPosition = LatLng(widget.initialLat!, widget.initialLng!);
        await _updateLocationInfo();
      } else if (widget.showCurrentLocation) {
        // Try to get current location, but keep Jakarta as fallback
        await _getCurrentLocation();
      } else {
        // Use Jakarta default and get address
        await _updateLocationInfo();
      }
    } catch (e) {
      setState(() {
        _currentAddress = "Gagal mendapatkan lokasi: ${e.toString()}";
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
            // Keep Jakarta default if permission denied
            print('Location permission denied, using Jakarta default');
            await _updateLocationInfo();
            return;
          }
        } else {
          print('Location service not available, using Jakarta default');
          await _updateLocationInfo();
          return;
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
      print('Error getting current location: $e');
      // Fallback to Jakarta default
      setState(() {
        _currentAddress = "Menggunakan lokasi default Jakarta";
        _isLoading = false;
        _hasLocationPermission = false;
      });
      await _updateLocationInfo();
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

    // Move to current position (Jakarta by default)
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition, zoom: 16),
      ),
    );
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
                zoom: 16,
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
  bool _isConfirming = false;

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
    print('Location selected: $lat, $lng, $address'); // Debug print
    if (mounted) {
      setState(() {
        _selectedLat = lat;
        _selectedLng = lng;
        _selectedAddress = address;
        _locationSelected = true;
      });
    }
  }

  void _confirmLocation() {
    print('Confirm location called'); // Debug print
    print(
        'Selected: $_selectedLat, $_selectedLng, $_selectedAddress'); // Debug print

    if (!_locationSelected ||
        _selectedLat == null ||
        _selectedLng == null ||
        _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Lokasi belum dipilih. Silakan pilih lokasi terlebih dahulu.'),
          backgroundColor: AppColorsLokin.error,
        ),
      );
      return;
    }

    if (_isConfirming) return; // Prevent double tap

    setState(() {
      _isConfirming = true;
    });

    // Call the callback immediately
    try {
      widget.onLocationConfirmed(
          _selectedLat!, _selectedLng!, _selectedAddress!);
      print('Callback called successfully'); // Debug print

      // Close the dialog with slight delay to show user feedback
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      print('Error in callback: $e'); // Debug print
      if (mounted) {
        setState(() {
          _isConfirming = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColorsLokin.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColorsLokin.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Info panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColorsLokin.primary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: AppColorsLokin.border.withOpacity(0.3),
                ),
              ),
            ),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsLokin.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColorsLokin.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColorsLokin.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lokasi: $_selectedAddress',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColorsLokin.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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

          // Bottom section with coordinates and button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: AppColorsLokin.border.withOpacity(0.3),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Coordinates display
                if (_selectedLat != null && _selectedLng != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColorsLokin.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Koordinat Lokasi:',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColorsLokin.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lat: ${_selectedLat!.toStringAsFixed(6)}\nLng: ${_selectedLng!.toStringAsFixed(6)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColorsLokin.textPrimary,
                                    fontFamily: 'Courier',
                                  ),
                        ),
                      ],
                    ),
                  ),

                // Confirm button
                SizedBox(
                  width: double.infinity,
                  child: _isConfirming
                      ? Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColorsLokin.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Mengkonfirmasi...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed:
                              _locationSelected ? _confirmLocation : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _locationSelected
                                ? AppColorsLokin.primary
                                : AppColorsLokin.textSecondary.withOpacity(0.5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Konfirmasi Lokasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
