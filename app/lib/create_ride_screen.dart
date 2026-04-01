import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'map_picker_screen.dart';
import 'package:latlong2/latlong.dart'; 
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart'; // THE NEW GEO PACKAGE

class CreateRideScreen extends StatefulWidget {
  const CreateRideScreen({super.key});

  @override
  State<CreateRideScreen> createState() => _CreateRideScreenState();
}

class _CreateRideScreenState extends State<CreateRideScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _originController = TextEditingController();
  final _destController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _transportMode = 'Cab';
  int _seats = 1;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  // NEW: Variables to hold the raw math data for the database!
  LatLng? _originLatLng;
  LatLng? _destLatLng;

  final List<String> _transportOptions = ['Cab', 'Auto', 'Bike'];

  Future<void> _openMapPicker(TextEditingController controller, String locationType) async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(title: locationType),
      ),
    );

    if (pickedLocation != null) {
      setState(() {
        controller.text = "${pickedLocation.latitude.toStringAsFixed(4)}, ${pickedLocation.longitude.toStringAsFixed(4)}";
        
        // NEW: Save the actual raw coordinates in the background!
        if (locationType == 'Pickup Location') _originLatLng = pickedLocation;
        if (locationType == 'Drop Location') _destLatLng = pickedLocation;
      });
    }
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _selectedDate = date;
      _selectedTime = time;
    });
  }

  Future<void> _submitRide() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select travel date and time.')));
      return;
    }

    // NEW: Ensure they actually used the map to pick locations
    if (_originLatLng == null || _destLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please use the map icons to select your locations.')));
      return;
    }

    setState(() => _isLoading = true);
    
    final departureDateTime = DateTime(
      _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
      _selectedTime!.hour, _selectedTime!.minute,
    );

    final user = FirebaseAuth.instance.currentUser;

    try {
      // --- THE BULLETPROOF NAME FIX ---
      String finalPosterName = 'Student';
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data()!.containsKey('name')) {
          finalPosterName = userDoc.get('name'); 
        } else {
          finalPosterName = user.displayName ?? 'Student'; 
        }
      }

      // --- NEW GEOFIRE MATH ---
      // This converts your coordinates into searchable hashes
      final originGeo = GeoFirePoint(GeoPoint(_originLatLng!.latitude, _originLatLng!.longitude));
      final destGeo = GeoFirePoint(GeoPoint(_destLatLng!.latitude, _destLatLng!.longitude));
      // -------------------------

      await FirebaseFirestore.instance.collection('ride_shares').add({
        'userId': user?.uid,
        'posterName': finalPosterName, 
        'origin': _originController.text.trim(),
        'destination': _destController.text.trim(),
        
        // NEW: Save the geohashes to the database so the Feed can find them!
        'originGeo': originGeo.data, 
        'destGeo': destGeo.data,     

        'departureTime': departureDateTime,
        'transportMode': _transportMode,
        'availableSeats': _seats,
        'notes': _notesController.text.trim(),
        'status': 'Open',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride posted successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offer a Ride'), elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  TextFormField(
                    controller: _originController,
                    readOnly: true, // Force them to use the map
                    decoration: InputDecoration(
                      labelText: 'Pickup Location',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.map, color: Colors.blue),
                        onPressed: () => _openMapPicker(_originController,'Pickup Location'),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _destController,
                    readOnly: true, // Force them to use the map
                    decoration: InputDecoration(
                      labelText: 'Drop Location',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.map, color: Colors.red),
                        onPressed: () => _openMapPicker(_destController,'Drop Location'),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade400)),
                    leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                    title: Text(
                      _selectedDate == null 
                        ? 'Select Date & Time *' 
                        : DateFormat('MMM dd, yyyy • hh:mm a').format(
                            DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute)
                          ),
                    ),
                    onTap: _pickDateTime,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _transportMode,
                          decoration: InputDecoration(labelText: 'Transport', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: _transportOptions.map((mode) => DropdownMenuItem(value: mode, child: Text(mode))).toList(),
                          onChanged: (val) => setState(() => _transportMode = val!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _seats,
                          decoration: InputDecoration(labelText: 'Seats', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: [1, 2, 3, 4, 5].map((s) => DropdownMenuItem(value: s, child: Text('$s available'))).toList(),
                          onChanged: (val) => setState(() => _seats = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Additional Notes (Optional)',
                      hintText: 'e.g., Splitting fare, carrying luggage...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitRide,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Post Ride', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}