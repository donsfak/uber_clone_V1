// ignore_for_file: avoid_print, non_constant_identifier_names, unused_field, prefer_final_fields, unused_local_variable

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  Supabase.initialize(
      url: 'https://uirpnvdnghgbzgrahiqy.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVpcnBudmRuZ2hnYnpncmFoaXF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkwNDM3NjYsImV4cCI6MjA1NDYxOTc2Nn0.DRLg9vv_Q_pJy_-Qf0_sDIXllq5Tvin7hXxaapCyRnw');
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

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
  LatLng? _selectedDestination;
  CameraPosition? _initialCameraPosition;
  late GoogleMapController _mapController;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  BitmapDescriptor? _pinIcon;
  @override
  void initState() {
    requestLocationPermission();
    _checkLocationPermission();
    _loadPinIcon();
    super.initState();
  }

  Future<void> _loadPinIcon() async {
    _pinIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)), 'assets/images/pin.png');
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
    setState(
      () {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _initialCameraPosition = CameraPosition(
          target: _currentLocation!,
          zoom: 14,
        );
      },
    );
    _mapController
        .animateCamera(CameraUpdate.newCameraPosition(_initialCameraPosition!));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                  target: LatLng(37.42796133580664, -122.085749655962),
                  zoom: 14),
              onCameraMove: (position) {
                if (_appState == AppState.choosingLocation) {
                  setState(() {
                    _selectedDestination = position.target;
                  });
                }
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
            if (_appState == AppState.choosingLocation)
              Center(
                child: Image.asset('assets/images/center-pin.png',
                    height: 50, width: 50),
              )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final response = await supabase.rpc('routes', get: {
                'origin': {
                  'latitude': _currentLocation!.latitude,
                  'longitude': _currentLocation!.longitude
                },
                'destination': {
                  'latitude': _selectedDestination!.latitude,
                  'longitude': _selectedDestination!.longitude
                }
              });
              final data = response.data as Map<String, dynamic>;
              final coordinate = data['legs'][0]['polyline']
                  ['geoJsonLinestring']['coordinates'] as List<dynamic>;
              final Duration = data['duration'] as String;
              final PolylineCoordinates = coordinate.map((coordinate) {
                return LatLng(coordinate[1], coordinate[0]);
              }).toList();
              setState(() {
                _polylines.add(Polyline(
                    polylineId: const PolylineId('routes'),
                    color: Colors.black,
                    points: PolylineCoordinates,
                    width: 5));
              });
              _markers.add(Marker(
                  markerId: const MarkerId('destination'),
                  position: _selectedDestination!,
                  icon: _pinIcon!));
            },
            label: Text('confirme destination')),
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
