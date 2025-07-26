import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:sixam_mart_delivery/util/app_constants.dart';

class MapScreen extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;

  const MapScreen({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentLatLng;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  final List<LatLng> _polylinePoints = [];

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    await Geolocator.requestPermission();

    // Get current location
    Position position = await Geolocator.getCurrentPosition();
    _currentLatLng = LatLng(position.latitude, position.longitude);
    LatLng destination = LatLng(widget.destinationLat, widget.destinationLng);

    _markers.add(Marker(
      markerId: const MarkerId('destination'),
      position: destination,
      infoWindow: const InfoWindow(title: 'Destination'),
    ));

    await _getPolylinePoints(_currentLatLng!, destination);

    if (_mapController != null) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          (_currentLatLng!.latitude < destination.latitude)
              ? _currentLatLng!.latitude
              : destination.latitude,
          (_currentLatLng!.longitude < destination.longitude)
              ? _currentLatLng!.longitude
              : destination.longitude,
        ),
        northeast: LatLng(
          (_currentLatLng!.latitude > destination.latitude)
              ? _currentLatLng!.latitude
              : destination.latitude,
          (_currentLatLng!.longitude > destination.longitude)
              ? _currentLatLng!.longitude
              : destination.longitude,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    }


    setState(() {});
  }


  Future<void> _getPolylinePoints(LatLng start, LatLng end) async {
    const apiKey = AppConstants.googleMapkey;

    final url = Uri.parse(
      'https://maps.gomaps.pro/maps/api/directions/json'
          '?origin=${start.latitude},${start.longitude}'
          '&destination=${end.latitude},${end.longitude}'
          '&key=$apiKey',
    );

    final response = await http.get(url);

    print('Directions API URL: $url');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    final data = json.decode(response.body);

    if (data['status'] != 'OK') {
      print('Google Directions API Error: ${data['status']} - ${data['error_message'] ?? 'No error message'}');
      return;
    }

    if (data['routes'].isNotEmpty) {
      final encodedPolyline = data['routes'][0]['overview_polyline']['points'];
      final points = PolylinePoints().decodePolyline(encodedPolyline);

      _polylinePoints.clear();
      for (var point in points) {
        _polylinePoints.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.blue,
          width: 5,
          points: _polylinePoints,
        ));
      });
    } else {
      print('No routes returned from API.');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Directions")),
      body: _currentLatLng == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLatLng!,
          zoom: 16,
        ),
        onMapCreated: (controller) => _mapController = controller,
        markers: _markers,
        polylines: _polylines,

        myLocationEnabled: true,          // ✅ Shows blue dot
        myLocationButtonEnabled: true,    // ✅ Re-center button
      ),
    );
  }
}
