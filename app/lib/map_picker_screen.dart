import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPickerScreen extends StatefulWidget {
  final String title;
  const MapPickerScreen({super.key, required this.title});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _pickedLocation;
  String? _currentAddress; // NEW: Stores the human-readable name!
  bool _isLoadingAddress = false;

  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(26.4710, 73.1134); 

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // 1. FORWARD Geocoding (Text to Coordinates)
  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    FocusScope.of(context).unfocus(); 

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'CampusUtilityApp/1.0'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newLoc = LatLng(lat, lon);
          
          // Clean up the long address string
          final rawName = data[0]['display_name'] as String;
          final shortName = rawName.split(',').take(2).join(',');

          setState(() {
            _pickedLocation = newLoc;
            _currentAddress = shortName; // Save the name!
          });
          
          _mapController.move(newLoc, 15.0);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address not found.')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  // 2. REVERSE Geocoding (Coordinates to Text when they drop a pin)
  Future<void> _getAddressFromLatLng(LatLng point) async {
    setState(() => _isLoadingAddress = true);
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}');
      final response = await http.get(url, headers: {'User-Agent': 'CampusUtilityApp/1.0'});
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawName = data['display_name'] as String;
        // Take just the first 2-3 parts of the address so it fits nicely on the UI card
        final shortName = rawName.split(',').take(3).join(','); 

        setState(() {
          _currentAddress = shortName;
        });
      }
    } catch (e) {
      setState(() => _currentAddress = "Selected Location");
    } finally {
      setState(() => _isLoadingAddress = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select ${widget.title}'), elevation: 0),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 15.0,
              onTap: (tapPosition, point) async {
                setState(() => _pickedLocation = point);
                // When they tap, fetch the real address name!
                await _getAddressFromLatLng(point); 
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.campus_utility_application',
              ),
              if (_pickedLocation != null)
                MarkerLayer(
                  markers: [Marker(point: _pickedLocation!, width: 50, height: 50, child: const Icon(Icons.location_pin, color: Colors.red, size: 40))],
                ),
            ],
          ),

          Positioned(
            top: 16, left: 16, right: 16,
            child: Card(
              elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(hintText: 'Search for an address...', border: InputBorder.none),
                        onSubmitted: (_) => _searchAddress(),
                      ),
                    ),
                    _isSearching 
                      ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(icon: const Icon(Icons.search, color: Colors.blue), onPressed: _searchAddress)
                  ],
                ),
              ),
            ),
          ),
          
          // --- NEW: Display the found address beautifully on the map ---
          if (_currentAddress != null || _isLoadingAddress)
            Positioned(
              bottom: 80, left: 16, right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _isLoadingAddress 
                    ? const Text('Finding address name...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                    : Text(_currentAddress!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            )
        ],
      ),
      floatingActionButton: _pickedLocation == null || _isLoadingAddress
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // WE NOW RETURN A MAP WITH BOTH THE MATH COORDS AND THE TEXT NAME!
                Navigator.pop(context, {
                  'location': _pickedLocation,
                  'address': _currentAddress ?? 'Custom Location'
                });
              },
              icon: const Icon(Icons.check),
              label: const Text('Confirm Location'),
              backgroundColor: Colors.green,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}