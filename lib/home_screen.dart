// ignore_for_file: prefer_final_fields, avoid_init_to_null, no_leading_underscores_for_local_identifiers, avoid_print, avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapcontroller =
      Completer<GoogleMapController>();

  static const LatLng _pGooglePlex = LatLng(5.316667, -4.033333); // Abidjan
  static const LatLng basiliqueLatLng =
      LatLng(6.818380, -5.275950); // Yamoussoukro
  // plateau

  LatLng? _currentP = null;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then((_) {
      getPolylinePoints().then((coordinates) {
        generatePolylinesFromPoints(coordinates);
        _fitPolylineBounds(coordinates);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentP == null
          ? const Center(
              child: Text('Loading...'),
            )
          : GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  _mapcontroller.complete(controller),
              initialCameraPosition: CameraPosition(
                target: _currentP!,
                zoom: 13,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('currentLocation'),
                  position: _currentP!,
                  icon: BitmapDescriptor.defaultMarker,
                ),
                Marker(
                  markerId: const MarkerId('sourceLocation'),
                  position: _pGooglePlex,
                  icon: BitmapDescriptor.defaultMarker,
                ),
                Marker(
                  markerId: const MarkerId('destinationLocation'),
                  position: basiliqueLatLng,
                  icon: BitmapDescriptor.defaultMarker,
                ),
              },
              polylines: Set<Polyline>.of(polylines.values),
            ),
    );
  }

  Future<void> _cameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _mapcontroller.future;

    CameraPosition _newCameraPosition = CameraPosition(
      target: position,
      zoom: 13,
    );
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  Future<void> getLocationUpdates() async {
    try {
      bool _serviceEnabled = await _locationController.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _locationController.requestService();
        if (!_serviceEnabled) {
          return;
        }
      }

      PermissionStatus _permissionGranted =
          await _locationController.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await _locationController.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      LocationData? _previousLocation;
      _locationController.onLocationChanged
          .listen((LocationData currentLocation) {
        if (currentLocation.latitude != null &&
            currentLocation.longitude != null &&
            (_previousLocation == null ||
                currentLocation.latitude != _previousLocation?.latitude ||
                currentLocation.longitude != _previousLocation?.longitude)) {
          setState(() {
            _currentP =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _cameraToPosition(_currentP!);
          });
          _previousLocation = currentLocation;
          print("Current Position: $_currentP");
        }
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<List<LatLng>> getPolylinePoints() async {
    List<LatLng> polylineCoordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: 'AIzaSyD_rNUjBjnXv41xA0rg-jjPAo1RM501ecw',
      request: PolylineRequest(
        origin: PointLatLng(_pGooglePlex.latitude, _pGooglePlex.longitude),
        destination:
            PointLatLng(basiliqueLatLng.latitude, basiliqueLatLng.longitude),
        mode: TravelMode.driving,
      ),
    );
    print(result.points);
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
      print("Polyline points: ${result.points.length}");
    } else {
      print("Error fetching polyline: ${result.errorMessage}");
    }
    return polylineCoordinates;
  }

  void generatePolylinesFromPoints(List<LatLng> polylineCoordinates) async {
    if (polylineCoordinates.isEmpty) {
      print("No coordinates to generate polyline.");
      return;
    }

    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.red,
        points: polylineCoordinates,
        width: 5);

    setState(() {
      polylines[id] = polyline;
    });
    print("Polyline ajoutée avec ${polylineCoordinates.length} points.");
  }

  void _fitPolylineBounds(List<LatLng> points) async {
    if (points.isEmpty) return;

    LatLngBounds bounds = LatLngBounds(
      southwest: points.reduce((a, b) => LatLng(
            a.latitude < b.latitude ? a.latitude : b.latitude,
            a.longitude < b.longitude ? a.longitude : b.longitude,
          )),
      northeast: points.reduce((a, b) => LatLng(
            a.latitude > b.latitude ? a.latitude : b.latitude,
            a.longitude > b.longitude ? a.longitude : b.longitude,
          )),
    );

    final GoogleMapController controller = await _mapcontroller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }
}
