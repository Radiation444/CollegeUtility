import 'profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'models/ride_post.dart';
import 'create_ride_screen.dart';
import 'map_picker_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideShareFeed extends StatefulWidget {
  const RideShareFeed({super.key});

  @override
  State<RideShareFeed> createState() => _RideShareFeedState();
}

class _RideShareFeedState extends State<RideShareFeed> {
  LatLng? _searchLocation;
  
  // 1. We removed 'final' so this can change, and set the default to a reasonable 2km!
  double _searchRadiusKm = 2.0; 
  
  DateTime? _searchDate;
  TimeOfDay? _searchTime;
  double _timeFlexibilityHours = 2.0;

  Stream<List<DocumentSnapshot>> _getRideStream() {
    final collection =
        FirebaseFirestore.instance.collection('ride_shares');

    if (_searchLocation == null) {
      return collection
          .orderBy('departureTime', descending: false)
          .snapshots()
          .map((snap) => snap.docs);
    } else {
      final center = GeoFirePoint(GeoPoint(
          _searchLocation!.latitude,
          _searchLocation!.longitude));

      return GeoCollectionReference(collection).subscribeWithin(
        center: center,
        // The query now dynamically uses whatever radius the user clicked!
        radiusInKm: _searchRadiusKm, 
        field: 'originGeo',
        geopointFrom: (data) =>
            (data['originGeo']['geopoint'] as GeoPoint),
        strictMode: true,
      );
    }
  }

  List<DocumentSnapshot> _applyTimeFilter(
      List<DocumentSnapshot> rawRides) {
    if (_searchDate == null) return rawRides;

    return rawRides.where((doc) {
      final data =
          doc.data() as Map<String, dynamic>;
      final rideTime =
          (data['departureTime'] as Timestamp).toDate();

      if (_searchTime == null) {
        return rideTime.year ==
                _searchDate!.year &&
            rideTime.month ==
                _searchDate!.month &&
            rideTime.day ==
                _searchDate!.day;
      }

      final targetDateTime = DateTime(
        _searchDate!.year,
        _searchDate!.month,
        _searchDate!.day,
        _searchTime!.hour,
        _searchTime!.minute,
      );

      final diff = rideTime
          .difference(targetDateTime)
          .inMinutes
          .abs();

      return diff <= (_timeFlexibilityHours * 60);
    }).toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            
            // Format the display text for the radius (e.g. "500m" vs "2km")
            String radiusText = _searchRadiusKm < 1.0 
                ? '${(_searchRadiusKm * 1000).toInt()}m' 
                : '${_searchRadiusKm.toInt()}km';

            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 24, right: 24, top: 24,
              ),
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
                          setState(() {
                            _searchLocation = null;
                            _searchDate = null;
                            _searchTime = null;
                            _searchRadiusKm = 2.0; // Reset to default
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                  const Divider(height: 16),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(_searchLocation == null ? 'Anywhere on Campus' : 'Within $radiusText of Pin'),
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
                  
                  // --- NEW: DYNAMIC RADIUS SELECTOR ---
                  // This only shows up if they actually picked a location!
                  if (_searchLocation != null) ...[
                    const SizedBox(height: 16),
                    const Text('Search Radius', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: [0.5, 1.0, 2.0, 5.0, 10.0].map((radius) {
                        return ChoiceChip(
                          label: Text(radius < 1.0 ? '${(radius * 1000).toInt()}m' : '${radius.toInt()}km'),
                          selected: _searchRadiusKm == radius,
                          selectedColor: Colors.green[200],
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => _searchRadiusKm = radius);
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  // -------------------------------------

                  const SizedBox(height: 16),
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
                      setState(() {}); 
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Apply Filters'),
                  ),
                  const SizedBox(height: 24),
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
    bool isFilterActive =
        _searchLocation != null ||
            _searchDate != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Campus Ride Sharing'),
        actions: [
          IconButton(
            icon: Icon(isFilterActive ? Icons.filter_alt : Icons.filter_alt_outlined, 
                       color: isFilterActive ? Colors.green : Colors.black54),
            onPressed: _showFilterSheet, 
          )
        ],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getRideStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child:
                    CircularProgressIndicator());
          }

          final rawRides =
              snapshot.data ?? [];

          final filteredRides =
              _applyTimeFilter(rawRides);

          if (filteredRides.isEmpty) {
            return const Center(
                child:
                    Text("No rides available"));
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount:
                filteredRides.length,
            itemBuilder:
                (context, index) {
              final doc =
                  filteredRides[index];

              final ride =
                  RidePost.fromMap(
                      doc.data()
                          as Map<String,
                              dynamic>,
                      doc.id);

              return _buildRideCard(
                  context, ride);
            },
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    const CreateRideScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add Ride'),
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, RidePost ride) {
    final formattedTime = DateFormat('MMM dd • hh:mm a').format(ride.departureTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP ROW: PROFILE & STATUS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: ride.userId))),
                  child: Row(
                    children: [
                      FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance.collection('users').doc(ride.userId).get(),
                        builder: (context, snapshot) {
                          String? imageUrl;
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            imageUrl = data['profileImage'];
                          }
                          return CircleAvatar(
                            radius: 16,
                            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                            child: imageUrl == null ? const Icon(Icons.person, size: 16) : null,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ride.posterName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                // --- THE SMART ACTION BUTTON ---
                Builder(
                  builder: (context) {
                    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                    final isMyRide = currentUserId == ride.userId;
                    final isOpen = ride.status == 'Open';

                    if (!isOpen) {
                      // If the ride is closed, just show a grey badge
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(12)),
                        child: const Text('Closed', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12)),
                      );
                    }

                    return ActionChip(
                      backgroundColor: isMyRide ? Colors.orange[100] : Colors.green[100],
                      side: BorderSide.none,
                      label: Text(
                        isMyRide ? 'Mark Full' : 'Request Seat',
                        style: TextStyle(
                          color: isMyRide ? Colors.orange[900] : Colors.green[900], 
                          fontWeight: FontWeight.bold, fontSize: 12
                        ),
                      ),
                      onPressed: () async {
                        if (isMyRide) {
                          // ACTION 1: CLOSE YOUR OWN RIDE
                          await FirebaseFirestore.instance.collection('ride_shares').doc(ride.id).update({
                            'status': 'Closed',
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ride marked as Full!')));
                          }
                        } else {
                          // ACTION 2: CONTACT THE DRIVER (DM SYSTEM)
                          final userDoc = await FirebaseFirestore.instance.collection('users').doc(ride.userId).get();
                          final phone = userDoc.data()?['phone'] ?? 'No phone number provided';
                          
                          // A controller to grab what the passenger types
                          final TextEditingController messageController = TextEditingController();

                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Request a Seat'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Driver: ${ride.posterName}\nPhone: $phone', style: const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: messageController,
                                      decoration: InputDecoration(
                                        labelText: 'Send a message',
                                        hintText: 'e.g., Hey, I am at the main gate!',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context), 
                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey))
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      final passengerId = FirebaseAuth.instance.currentUser?.uid;
                                      final driverId = ride.userId;
                                      if (passengerId == null) return;

                                      // 1. Create a unique Chat ID (Alphabetical order so it's always the same for these two users)
                                      List<String> users = [passengerId, driverId];
                                      users.sort(); 
                                      String chatId = "${users[0]}_${users[1]}";

                                      // 2. The Message Payload
                                      String messageText = messageController.text.trim();
                                      if (messageText.isEmpty) messageText = "I would like to request a seat on your ride!";

                                      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
                                      
                                      // 3. Update the Main Chat Document (for the Inbox list and Badges)
                                      await chatRef.set({
                                        'participants': [passengerId, driverId],
                                        'lastMessage': messageText,
                                        'lastTimestamp': FieldValue.serverTimestamp(),
                                        // Increment the driver's unread count!
                                        'unreadCount_$driverId': FieldValue.increment(1), 
                                        // Ensure the passenger's count exists
                                        'unreadCount_$passengerId': FieldValue.increment(0), 
                                      }, SetOptions(merge: true));

                                      // 4. Save the actual message inside the chat's subcollection
                                      await chatRef.collection('messages').add({
                                        'senderId': passengerId,
                                        'text': messageText,
                                        'timestamp': FieldValue.serverTimestamp(),
                                        // We tag this message so the UI knows to render "Accept/Decline" buttons!
                                        'type': 'ride_request', 
                                        'rideId': ride.id,
                                        'requestStatus': 'pending', 
                                      });

                                      if (context.mounted) {
                                        Navigator.pop(context); // Close the dialog
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Message sent! Check your inbox.'))
                                        );
                                      }
                                    },
                                    child: const Text('Send Request'),
                                  ),
                                ],
                              ),
                            );
                          }
                        }
                      },
                    );
                  }
                ),
              ],
            ),
            
            const Divider(height: 24),

            // --- MIDDLE: THE HIGHLIGHTED TIMELINE (SOURCE & DESTINATION) ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50, // Gives a nice subtle background to highlight it
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade100)
              ),
              child: Row(
                children: [
                  Column(
                    children: [
                      const Icon(Icons.radio_button_checked, size: 18, color: Colors.blue),
                      Container(height: 24, width: 2, color: Colors.grey.shade400),
                      const Icon(Icons.location_on, size: 18, color: Colors.red),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ride.origin, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 20),
                        Text(ride.destination, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- BOTTOM ROW: TIME & DETAILS ---
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
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.directions_car, size: 14),
                      label: Text(ride.transportMode),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.event_seat, size: 14),
                      label: Text('${ride.availableSeats}'),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}