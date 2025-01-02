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

  static const LatLng _pGooglePlex = LatLng(5.3732, -3.99863);
  static const LatLng basiliqueLatLng = LatLng(5.304291, -4.023063);
  LatLng? _currentP = null;

  Map<PolylineId, Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then(
      (_) => {
        getPolylinePoints().then((coordinates) => {
              generatePolylinesFromPoints(coordinates),
            }),
      },
    );
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

      _locationController.onLocationChanged
          .listen((LocationData currentLocation) {
        if (currentLocation.latitude != null &&
            currentLocation.longitude != null) {
          setState(() {
            _currentP =
                LatLng(currentLocation.latitude!, currentLocation.longitude!);
            _cameraToPosition(_currentP!);
            print("Current Position: $_currentP");
          });
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
      googleApiKey: 'google_maps_api_key',
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
        print("Points obtenus: ${result.points.length}");
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print("Erreur dans PolylineResult: ${result.errorMessage}");
    }
    return polylineCoordinates;
  }

  void generatePolylinesFromPoints(List<LatLng> polylineCoordinates) async {
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.red,
        points: polylineCoordinates,
        width: 8);

    setState(() {
      polylines[id] = polyline;
    });
    print("Polyline ajoutée avec ${polylineCoordinates.length} points.");
  }
}
