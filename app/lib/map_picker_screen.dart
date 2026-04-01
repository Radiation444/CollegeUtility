import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPickerScreen extends StatefulWidget {
  final String title;
  const MapPickerScreen({super.key, required this.title});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Pre-centered on the campus for convenience
  LatLng? _pickedLocation;
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(26.4710, 73.1134); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select ${widget.title}'),
        elevation: 0,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _initialCenter,
          initialZoom: 15.0,
          onTap: (tapPosition, point) {
            setState(() {
              _pickedLocation = point;
            });
          },
        ),
        children: [
          // The totally free OpenStreetMap tile layer!
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.campus_utility_application',
          ),
          if (_pickedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _pickedLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: _pickedLocation == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // Return the coordinates when they confirm
                Navigator.pop(context, _pickedLocation);
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm Location'),
              backgroundColor: Colors.green,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}