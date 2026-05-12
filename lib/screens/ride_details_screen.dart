import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../widgets/booking_bottom_sheet.dart';
import '../widgets/rating_dialog.dart';
import 'chat_screen.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;

  const RideDetailsScreen({super.key, required this.rideId});

  @override
  _RideDetailsScreenState createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  bool _isLoading = true;
  String _error = '';
  String? _userId;

  Map<String, dynamic>? _ride;
  List<dynamic> _bookings = [];
  String _activeSection = "details";

  @override
  void initState() {
    super.initState();
    _fetchRideDetails();
  }

  Future<void> _fetchRideDetails() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      String? token = prefs.getString('token');

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/rides/${widget.rideId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _ride = data;
        });

        // Fetch all bookings if user is the driver
        if (data['driverId'] == _userId) {
          final bookingsRes = await http.get(
            Uri.parse(
              '${ApiService.baseUrl}/api/rides/${widget.rideId}/bookings',
            ),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (bookingsRes.statusCode == 200) {
            setState(() {
              _bookings = jsonDecode(bookingsRes.body);
            });
          }
        }
      } else {
        setState(() => _error = "Ride not found or unavailable.");
      }
    } catch (e) {
      setState(() => _error = "Network error fetching ride details.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBookingAction(String bookingId, String status) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rides/book/$bookingId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"status": status}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking $status successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchRideDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to $status booking."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Network error."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    String reason = "User requested cancellation";
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rides/book/$bookingId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"reason": reason}),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Booking cancelled."),
            backgroundColor: Colors.orange,
          ),
        );
        _fetchRideDetails();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error cancelling booking."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper for UI colors
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(backgroundColor: Colors.teal[800], elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }
    if (_error.isNotEmpty || _ride == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F6),
        appBar: AppBar(backgroundColor: Colors.teal[800], elevation: 0),
        body: Center(
          child: Text(
            _error.isNotEmpty ? _error : "Ride not found",
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    bool isDriver = _ride!['driverId'] == _userId;
    bool hasUserBooking = _ride!['userBooking'] != null;
    bool canChat = isDriver || hasUserBooking;
    bool canRate = _ride!['status'] == 'completed' && canChat;
    String revieweeId =
        isDriver && hasUserBooking
            ? _ride!['userBooking']['passenger']['_id'] ??
                _ride!['driverId'] // Fallback to driver if something is weird
            : _ride!['driverId'];

    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text(
          "Ride Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (canChat)
            IconButton(
              icon: const Icon(Icons.chat),
              tooltip: "Open Ride Chat",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatScreen(
                          rideId: widget.rideId,
                          initialMessages: _ride!['messages'],
                        ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Hero Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal[800],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        "${_ride!['from']} → ${_ride!['to']}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (_ride!['status'] ?? 'upcoming')
                            .toString()
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${_ride!['date']?.split('T')[0] ?? 'N/A'} at ${_ride!['time'] ?? 'N/A'} • \$${_ride!['pricePerSeat'] ?? 0}/seat",
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),

          // Section Navigation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildNavButton("details", "📋 Details"),
                  if (isDriver) _buildNavButton("bookings", "🎫 Bookings"),
                  if (canRate)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed:
                            () => RatingDialog.show(
                              context,
                              widget.rideId,
                              revieweeId,
                              (rating) => _fetchRideDetails(),
                            ),
                        icon: const Icon(
                          Icons.star,
                          color: Colors.black87,
                          size: 18,
                        ),
                        label: const Text(
                          "Rate Trip",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child:
                  _activeSection == "details"
                      ? _buildDetailsSection(hasUserBooking)
                      : _buildBookingsSection(),
            ),
          ),
        ],
      ),
      floatingActionButton:
          (!isDriver && !hasUserBooking && _ride!['status'] == 'upcoming')
              ? FloatingActionButton.extended(
                onPressed:
                    _ride!['seatsAvailable'] == 0
                        ? null
                        : () {
                          BookingBottomSheet.show(
                            context,
                            _ride!,
                            (booking) => _fetchRideDetails(),
                          );
                        },
                backgroundColor:
                    _ride!['seatsAvailable'] == 0
                        ? Colors.grey
                        : Colors.teal[800],
                icon: Icon(
                  _ride!['seatsAvailable'] == 0
                      ? Icons.block
                      : Icons.event_seat,
                  color: Colors.white,
                ),
                label: Text(
                  _ride!['seatsAvailable'] == 0 ? "Ride Full" : "Book Ride",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildNavButton(String id, String label) {
    bool isActive = _activeSection == id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? Colors.teal[800] : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.teal[800],
          elevation: isActive ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.teal[800]!, width: 1.5),
          ),
        ),
        onPressed: () => setState(() => _activeSection = id),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDetailsSection(bool hasUserBooking) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ✅ NEW: If the user is a passenger, show their booking status here!
        if (hasUserBooking && _ride!['userBooking'] != null)
          _buildMyBookingCard(_ride!['userBooking']),

        _buildInfoCard("🚗 Vehicle & Driver", [
          "Driver: ${_ride!['driver']?['name'] ?? 'Unknown'}",
          "Car: ${_ride!['vehicle']?['make']} ${_ride!['vehicle']?['model']}",
          "License: ${_ride!['vehicle']?['licensePlate']}",
          "Type: ${_ride!['vehicle']?['carType']} (${_ride!['vehicle']?['fuelType']})",
          "Total Seats: ${_ride!['vehicle']?['totalSeats']}",
        ]),
        const SizedBox(height: 10),
        _buildInfoCard("⚙️ Preferences", [
          "Luggage Space: ${_ride!['luggageSpace'] ?? 'None'}",
          "Smoking: ${_ride!['smokingAllowed'] == true ? '✅ Allowed' : '❌ Not Allowed'}",
          "Pets: ${_ride!['petsAllowed'] == true ? '✅ Allowed' : '❌ Not Allowed'}",
          "Carbon Offset: ${_ride!['carbonOffset'] == true ? '🌱 Committed' : '❌ No'}",
          if (_ride!['additionalNotes'] != null &&
              _ride!['additionalNotes'].isNotEmpty)
            "Notes: ${_ride!['additionalNotes']}",
        ]),
        const SizedBox(height: 10),
        _buildInfoCard(
          "👥 Confirmed Passengers (${_ride!['passengers']?.length ?? 0})",
          (_ride!['passengers'] as List?)
                  ?.map((p) => "👤 ${p['name'] ?? 'Member'}")
                  .toList() ??
              ["No passengers yet."],
        ),
      ],
    );
  }

  // ✅ NEW WIDGET: Passenger's personal booking card
  Widget _buildMyBookingCard(Map<String, dynamic> booking) {
    final statusColor = _getStatusColor(booking['status']);
    num price = _ride!['pricePerSeat'] ?? 0;
    num seats = booking['seatsBooked'] ?? 1;
    num totalCost = price * seats;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "🎟️ My Booking",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (booking['status'] ?? 'Unknown').toString().toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Seats Booked: $seats",
                  style: const TextStyle(fontSize: 15),
                ),
                Text(
                  "Total Cost: \$${totalCost.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (booking['status'] == 'confirmed' ||
                booking['status'] == 'pending') ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _cancelBooking(booking['_id']),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text("Cancel My Booking"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> details) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
            ),
            const Divider(height: 20),
            ...details.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  d,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsSection() {
    if (_bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 60, color: Colors.grey[400]),
              const SizedBox(height: 10),
              Text(
                "No booking requests yet.",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children:
          _bookings.map((b) {
            final statusColor = _getStatusColor(b['status']);
            num price = _ride!['pricePerSeat'] ?? 0;
            num seats = b['seatsBooked'] ?? 1;
            num totalCost = price * seats;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.purple[100],
                              child: const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              b['passenger']?['name'] ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            b['status'].toString().toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Requested Seats: $seats",
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                        Text(
                          "Total: \$${totalCost.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (b['status'] == 'pending')
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed:
                                  () => _handleBookingAction(
                                    b['_id'],
                                    "rejected",
                                  ),
                              child: const Text("Reject"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              onPressed:
                                  () => _handleBookingAction(
                                    b['_id'],
                                    "confirmed",
                                  ),
                              child: const Text(
                                "Confirm",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (b['status'] == 'confirmed')
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _cancelBooking(b['_id']),
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                            size: 18,
                          ),
                          label: const Text(
                            "Cancel Booking",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }
}
