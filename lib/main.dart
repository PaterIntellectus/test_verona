import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' hide PermissionStatus;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Location Tracker",
      home: Scaffold(
        appBar: AppBar(title: const Text("Location tracker")),
        body: const MapWidget(),
      ),
    );
  }
}

class MapWidget extends StatefulWidget {
  const MapWidget({
    super.key,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with WidgetsBindingObserver {
  final Location _location = Location();
  LocationData? _currentLocation;

  var _locationPermissionStatus = PermissionStatus.denied;
  var _locationServiceStatus = ServiceStatus.disabled;

  @override
  Widget build(BuildContext context) {
    if (_locationServiceStatus.isDisabled) {
      return const Center(
        child: Text("Необходимо включить сервис местоположения!"),
      );
    }

    if (!_locationPermissionStatus.isGranted) {
      return const Center(
        child: Text(
            "Приложению необходимо разрешение для использования местоположения!"),
      );
    }

    if (_currentLocation == null) {
      return const Center(child: Text("Загрузка..."));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
        ),
        zoom: 18,
      ),
      markers: {
        Marker(
          markerId: const MarkerId("currentLocation"),
          position: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
        ),
      },
    );
  }

  void checkServiceStatus(
    BuildContext context,
    PermissionWithService permission,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        (await permission.serviceStatus).toString(),
      ),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _listenCurrentLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _listenCurrentLocation();
  }

  void requestLocationPermission() async {
    var status = await Permission.location.request();

    setState(() {
      _locationPermissionStatus = status;
    });
  }

  void requestLocationService() async {
    var serviceStatus = await Permission.location.serviceStatus;

    setState(() {
      _locationServiceStatus = serviceStatus;
    });
  }

  void _listenCurrentLocation() async {
    requestLocationPermission();
    requestLocationService();

    if (_locationPermissionStatus.isGranted &&
        _locationServiceStatus.isEnabled) {
      _location.onLocationChanged.listen(
        (newCurrentLocation) {
          setState(() {
            _currentLocation = newCurrentLocation;
          });
        },
      );

      _location.enableBackgroundMode(
        enable: await Permission.locationAlways.isGranted,
      );
    }
  }
}
