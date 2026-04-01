import 'profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'models/ride_post.dart';
import 'create_ride_screen.dart';
import 'map_picker_screen.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart'; 

class RideShareFeed extends StatefulWidget {
  const RideShareFeed({super.key});

  @override
  State<RideShareFeed> createState() => _RideShareFeedState();
}

class _RideShareFeedState extends State<RideShareFeed> {
  // FILTER STATE VARIABLES
  LatLng? _searchLocation;
  final double _searchRadiusKm = 10.0; 
  DateTime? _searchDate;
  TimeOfDay? _searchTime;
  double _timeFlexibilityHours = 2.0; // Default +/- 2 hours

  // 1. THE FIREBASE FETCH (Gets the Location Matches)
  Stream<List<DocumentSnapshot>> _getRideStream() {
    final collection = FirebaseFirestore.instance.collection('ride_shares');

    if (_searchLocation == null) {
      return collection.orderBy('departureTime', descending: false).snapshots().map((snap) => snap.docs);
    } else {
      final center = GeoFirePoint(GeoPoint(_searchLocation!.latitude, _searchLocation!.longitude));
      return GeoCollectionReference(collection).subscribeWithin(
        center: center, radiusInKm: _searchRadiusKm, field: 'originGeo',
        geopointFrom: (data) => (data['originGeo']['geopoint'] as GeoPoint), strictMode: true,
      );
    }
  }

  // 2. THE LOCAL FILTER (Filters the Time Window)
  List<DocumentSnapshot> _applyTimeFilter(List<DocumentSnapshot> rawRides) {
    if (_searchDate == null) return rawRides; // Skip if no date selected

    return rawRides.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final rideTime = (data['departureTime'] as Timestamp).toDate();

      // If they only picked a date, just match the day
      if (_searchTime == null) {
        return rideTime.year == _searchDate!.year && 
               rideTime.month == _searchDate!.month && 
               rideTime.day == _searchDate!.day;
      }

      // If they picked a date AND time, apply the flexibility window!
      final targetDateTime = DateTime(
        _searchDate!.year, _searchDate!.month, _searchDate!.day,
        _searchTime!.hour, _searchTime!.minute,
      );
      
      final differenceInMinutes = rideTime.difference(targetDateTime).inMinutes.abs();
      return differenceInMinutes <= (_timeFlexibilityHours * 60);
    }).toList();
  }

  // 3. THE UI: SMART FILTER SHEET
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder( // StatefulBuilder allows the bottom sheet to update its own UI
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Find a Match', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          // CLEAR FILTERS
                          setState(() {
                            _searchLocation = null;
                            _searchDate = null;
                            _searchTime = null;
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                  const Divider(height: 32),

                  // LOCATION PICKER
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(_searchLocation == null ? 'Anywhere on Campus' : 'Within ${_searchRadiusKm.toInt()}km of Pin'),
                    trailing: const Icon(Icons.map),
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      final LatLng? picked = await Navigator.push(
                        context, MaterialPageRoute(builder: (context) => const MapPickerScreen(title: 'Search Center'))
                      );
                      if (picked != null) setSheetState(() => _searchLocation = picked);
                    },
                  ),
                  const SizedBox(height: 16),

                  // DATE PICKER
                  ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blue),
                    title: Text(_searchDate == null ? 'Any Date' : DateFormat('MMM dd, yyyy').format(_searchDate!)),
                    trailing: const Icon(Icons.edit_calendar),
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onTap: () async {
                      final DateTime? date = await showDatePicker(
                        context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30))
                      );
                      if (date != null) setSheetState(() => _searchDate = date);
                    },
                  ),
                  const SizedBox(height: 16),

                  // TIME & WINDOW PICKER (Only shows if Date is selected)
                  if (_searchDate != null) ...[
                    ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.orange),
                      title: Text(_searchTime == null ? 'Any Time' : _searchTime!.format(context)),
                      trailing: const Icon(Icons.schedule),
                      tileColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onTap: () async {
                        final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) setSheetState(() => _searchTime = time);
                      },
                    ),
                    if (_searchTime != null) ...[
                      const SizedBox(height: 16),
                      Text('Flexibility: +/- ${_timeFlexibilityHours.toInt()} hours', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Slider(
                        value: _timeFlexibilityHours,
                        min: 1, max: 12, divisions: 11,
                        activeColor: Colors.green,
                        label: '${_timeFlexibilityHours.toInt()} hr',
                        onChanged: (val) => setSheetState(() => _timeFlexibilityHours = val),
                      ),
                    ]
                  ],
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Triggers the main screen to rebuild with new filters
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Apply Filters'),
                  )
                ],
              ),
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFilterActive = _searchLocation != null || _searchDate != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Campus Ride Sharing'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined, 
                       color: isFilterActive ? Colors.green : Colors.black54),
            onPressed: _showFilterSheet, // OPENS OUR NEW SMART MENU
          )
        ],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getRideStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('Error loading rides.'));

          // INTERCEPT AND APPLY OUR TIME FILTER!
          final rawRides = snapshot.data ?? [];
          final filteredRides = _applyTimeFilter(rawRides);

          if (filteredRides.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(isFilterActive ? 'No rides match your exact filters.' : 'No rides available right now.', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  if (isFilterActive)
                    TextButton(onPressed: () => setState((){ _searchLocation=null; _searchDate=null; _searchTime=null; }), child: const Text('Clear Filters'))
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRides.length,
            itemBuilder: (context, index) {
              final doc = filteredRides[index];
              if (doc.data() == null) return const SizedBox.shrink();
              final ride = RidePost.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              return _buildRideCard(context, ride);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateRideScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add Ride'),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, RidePost ride) {
    final formattedTime = DateFormat('MMM dd • hh:mm a').format(ride.departureTime);
    
    IconData transportIcon = Icons.directions_car;
    if (ride.transportMode == 'Bike') transportIcon = Icons.two_wheeler;
    if (ride.transportMode == 'Auto') transportIcon = Icons.electric_rickshaw;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: ride.userId))),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.person, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(ride.posterName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: ride.status == 'Open' ? Colors.green[100] : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                  child: Text(ride.status, style: TextStyle(color: ride.status == 'Open' ? Colors.green[800] : Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.radio_button_checked, size: 16, color: Colors.blue),
                    const SizedBox(height: 4),
                    Container(height: 20, width: 2, color: Colors.grey),
                    const SizedBox(height: 4),
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.origin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 16),
                      Text(ride.destination, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(formattedTime, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  children: [
                    Chip(avatar: Icon(transportIcon, size: 16), label: Text(ride.transportMode), backgroundColor: Colors.grey[100], side: BorderSide.none),
                    const SizedBox(width: 8),
                    Chip(avatar: const Icon(Icons.event_seat, size: 16), label: Text('${ride.availableSeats}'), backgroundColor: Colors.grey[100], side: BorderSide.none),
                  ],
                )
              ],
            ),
            if (ride.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(ride.notes, style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic)),
            ]
          ],
        ),
      ),
    );
  }
}