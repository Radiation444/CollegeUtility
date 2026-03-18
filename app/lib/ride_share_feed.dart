import 'profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'models/ride_post.dart';
import 'create_ride_screen.dart';

class RideShareFeed extends StatelessWidget {
  const RideShareFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Campus Ride Sharing'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ride_shares')
            .orderBy('departureTime', descending: false) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading rides.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_filled_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No rides available right now.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const Text('Be the first to offer or request one!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final rides = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final doc = rides[index];
              final ride = RidePost.fromMap(doc.data() as Map<String, dynamic>, doc.id);
              return _buildRideCard(context, ride);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRideScreen()),
          );
        },
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
                // THIS IS THE NEW CLICKABLE INKWELL
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      // If your ProfileScreen requires a userId to load the right data, 
                      // you would pass it like this: ProfileScreen(userId: ride.userId)
                      MaterialPageRoute(builder: (context) => ProfileScreen(userId: ride.userId)),
                    );
                  },
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
                        Text(
                          ride.posterName, 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            decoration: TextDecoration.underline, // Visual cue that it's clickable
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ride.status == 'Open' ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    ride.status,
                    style: TextStyle(
                      color: ride.status == 'Open' ? Colors.green[800] : Colors.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
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
                    Chip(
                      avatar: Icon(transportIcon, size: 16),
                      label: Text(ride.transportMode),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.event_seat, size: 16),
                      label: Text('${ride.availableSeats}'),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                    ),
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