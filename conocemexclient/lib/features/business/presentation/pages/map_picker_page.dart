import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';

import '/l10n/app_localizations.dart';

/// Resultado de seleccionar una ubicacion en el mapa.
class MapPickerResult {
  final double latitude;
  final double longitude;
  final String? address;

  MapPickerResult({required this.latitude, required this.longitude, this.address});
}

class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerPage({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  static const _darkBlue = Color(0xFF001F3F);
  static const _primaryGreen = Color(0xFF00DF5F);
  static const _googleApiKey = 'AIzaSyBFU8EbdU2JrwHd-4FPkmqfNldU_kmw8Us';

  // Default: Ciudad de Mexico
  static const _defaultLat = 19.4326;
  static const _defaultLng = -99.1332;

  late LatLng _selectedPosition;
  String? _address;
  bool _loadingAddress = false;

  GoogleMapController? _mapController;
  final _dio = Dio();

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(
      widget.initialLat ?? _defaultLat,
      widget.initialLng ?? _defaultLng,
    );
    _reverseGeocode(_selectedPosition);
  }

  Future<void> _reverseGeocode(LatLng pos) async {
    setState(() => _loadingAddress = true);
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'latlng': '${pos.latitude},${pos.longitude}',
          'key': _googleApiKey,
          'language': 'es',
        },
      );

      final results = response.data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        _address = results[0]['formatted_address'] as String?;
      }
    } catch (_) {
      _address = null;
    }
    if (mounted) setState(() => _loadingAddress = false);
  }

  void _onMapTap(LatLng pos) {
    setState(() => _selectedPosition = pos);
    _reverseGeocode(pos);
  }

  void _confirm() {
    Navigator.pop(
      context,
      MapPickerResult(
        latitude: _selectedPosition.latitude,
        longitude: _selectedPosition.longitude,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // ─── Mapa ───
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController = c,
            onTap: _onMapTap,
            markers: {
              Marker(
                markerId: const MarkerId('selected'),
                position: _selectedPosition,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // ─── AppBar transparente ───
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: _darkBlue, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                        ),
                        child: Text(
                          l.selectLocationMap,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: _darkBlue, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Panel inferior con direccion + boton confirmar ───
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Direccion
                      Row(
                        children: [
                          Icon(Icons.location_on, color: _primaryGreen, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _loadingAddress
                                ? Text(l.loadingAddress, style: TextStyle(color: _darkBlue.withValues(alpha: 0.4), fontStyle: FontStyle.italic))
                                : Text(
                                    _address ?? l.tapToSelectLocation,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: _darkBlue, fontSize: 14),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Coordenadas
                      Text(
                        '${_selectedPosition.latitude.toStringAsFixed(6)}, ${_selectedPosition.longitude.toStringAsFixed(6)}',
                        style: TextStyle(fontSize: 12, color: _darkBlue.withValues(alpha: 0.35), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),
                      // Boton confirmar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _confirm,
                          icon: const Icon(Icons.check, size: 20),
                          label: Text(l.confirmLocation, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen, foregroundColor: _darkBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 4, shadowColor: _primaryGreen.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ],
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
