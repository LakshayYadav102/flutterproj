import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class BookingBottomSheet extends StatefulWidget {
  final Map<String, dynamic> ride;
  final Function(Map<String, dynamic>) onBookingSuccess;

  const BookingBottomSheet({
    super.key,
    required this.ride,
    required this.onBookingSuccess,
  });

  // Helper method to show this sheet easily from any screen
  static void show(
    BuildContext context,
    Map<String, dynamic> ride,
    Function(Map<String, dynamic>) onSuccess,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: BookingBottomSheet(ride: ride, onBookingSuccess: onSuccess),
          ),
    );
  }

  @override
  _BookingBottomSheetState createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _seats = 1;
  String _paymentMethod = "cash";
  bool _isLoading = false;
  String _error = "";

  Future<void> _handleBook() async {
    int available = widget.ride['seatsAvailable'] ?? 0;
    if (_seats < 1 || _seats > available) {
      setState(() => _error = "Invalid number of seats");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rides/book/${widget.ride['_id']}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "seatsBooked": _seats,
          "paymentMethod": _paymentMethod,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (_paymentMethod == "online") {
          _showSnack(
            "Payment processed (dummy). Booking pending confirmation.",
            Colors.blue,
          );
        } else {
          _showSnack(
            "Booking request sent! Awaiting driver confirmation.",
            Colors.green,
          );
        }

        widget.onBookingSuccess(data['booking'] ?? {});
        Navigator.pop(context); // Close the bottom sheet
      } else {
        setState(
          () =>
              _error =
                  jsonDecode(response.body)['error'] ?? "Error booking ride",
        );
      }
    } catch (e) {
      setState(() => _error = "Network error. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    int maxSeats = widget.ride['seatsAvailable'] ?? 0;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Book Ride",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "Seats Available: $maxSeats",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Seats Input
          const Text(
            "Number of Seats",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
              ),
              Text(
                "$_seats",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed:
                    _seats < maxSeats ? () => setState(() => _seats++) : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Method
          const Text(
            "Payment Method",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(
                value: "cash",
                child: Text("Cash on Travel Day"),
              ),
              DropdownMenuItem(
                value: "online",
                child: Text("Pay Now (UPI/Card)"),
              ),
            ],
            onChanged: (val) => setState(() => _paymentMethod = val!),
          ),

          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error, style: const TextStyle(color: Colors.red)),
            ),

          const SizedBox(height: 30),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                ),
                onPressed: _isLoading ? null : _handleBook,
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          "Send Booking Request",
                          style: TextStyle(color: Colors.white),
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
