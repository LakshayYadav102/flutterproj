import 'package:flutter/material.dart';

class RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;

  const RideCard({super.key, required this.ride});

  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    try {
      DateTime date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "N/A";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ride['_id'] == null) {
      return const Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Invalid ride data"),
        ),
      );
    }

    final String driverName = ride['driver']?['name'] ?? "Unknown Driver";
    final String from = ride['from'] ?? "Unknown";
    final String to = ride['to'] ?? "Unknown";
    final String time = ride['time'] ?? "N/A";
    final int seats = ride['seatsAvailable'] ?? 0;
    final num price = ride['pricePerSeat'] ?? 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // ✅ FIXED NAVIGATION
          Navigator.pushNamed(context, '/ride/details', arguments: ride['_id']);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "🚗 $from → $to",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "₹$price",
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "Driver: $driverName",
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${_formatDate(ride['date'])} | $time",
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.event_seat,
                        size: 16,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$seats left",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
