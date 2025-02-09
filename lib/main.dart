// ignore_for_file: avoid_print, non_constant_identifier_names, unused_field, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

enum AppState {
  choosingLocation,
  confirmFare,
  waitingForPickup,
  riding,
  postRide,
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppState _appState = AppState.choosingLocation;
  LatLng? _currentLocation;
  CameraPosition? _initialCameraPosition;
  late GoogleMapController _mapController;
  @override
  void initState() {
    requestLocationPermission();
    _checkLocationPermission();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez activer votre service de localisation'),
        ));
      }
    }
    var Permission = await Geolocator.checkPermission();
    if (Permission == LocationPermission.denied) {
      Permission = await Geolocator.requestPermission();
      if (Permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Veuillez activer votre service de localisation'),
          ));
          return;
        }
      }
    }
    if (Permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez activer votre service de localisation'),
        ));
        return;
      }
    }
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _initialCameraPosition = CameraPosition(
        target: _currentLocation!,
        zoom: 14,
      );
    });
    _mapController
        .animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition!));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: GoogleMap(
          myLocationEnabled: true,
          initialCameraPosition: CameraPosition(
              target: LatLng(37.42796133580664, -122.085749655962), zoom: 14),
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }
}

Future<void> requestLocationPermission() async {
  var status = await Permission.location.request();
  if (status.isGranted) {
    print("Permission accordée");
  } else {
    print("Permission refusée");
  }
}
