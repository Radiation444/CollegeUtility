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
  LatLng? _searchLocation;
  final double _searchRadiusKm = 10.0;
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

  @override
  Widget build(BuildContext context) {
    bool isFilterActive =
        _searchLocation != null ||
            _searchDate != null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Campus Ride Sharing'),
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

  Widget _buildRideCard(
      BuildContext context,
      RidePost ride) {
    final formattedTime =
        DateFormat('MMM dd • hh:mm a')
            .format(
                ride.departureTime);

    return Card(
      margin: const EdgeInsets.only(
          bottom: 16),
      elevation: 2,
      shape:
          RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(
                      16)),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
              children: [
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ProfileScreen(
                                  userId:
                                      ride.userId))),
                  child: Row(
                    children: [

                      /// PROFILE IMAGE
                      FutureBuilder<
                          DocumentSnapshot>(
                        future:
                            FirebaseFirestore
                                .instance
                                .collection(
                                    'users')
                                .doc(ride
                                    .userId)
                                .get(),
                        builder: (context,
                            snapshot) {

                          String? imageUrl;

                          if (snapshot
                                  .hasData &&
                              snapshot
                                  .data!
                                  .exists) {
                            final data =
                                snapshot
                                        .data!
                                        .data()
                                    as Map<
                                        String,
                                        dynamic>;

                            imageUrl = data[
                                'profileImage'];
                          }

                          return CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                imageUrl !=
                                        null
                                    ? NetworkImage(
                                        imageUrl)
                                    : null,
                            child: imageUrl ==
                                    null
                                ? const Icon(
                                    Icons
                                        .person,
                                    size:
                                        16)
                                : null,
                          );
                        },
                      ),

                      const SizedBox(
                          width: 8),

                      Text(
                        ride.posterName,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  ride.status,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(
                height: 12),

            Text(
              "${ride.origin} → ${ride.destination}",
              style: const TextStyle(
                  fontSize: 16),
            ),

            const SizedBox(
                height: 8),

            Text(
              formattedTime,
              style: const TextStyle(
                  color:
                      Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}