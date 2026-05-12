import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class RatingDialog extends StatefulWidget {
  final String rideId;
  final String revieweeId;
  final Function(Map<String, dynamic>) onSubmitSuccess;

  const RatingDialog({
    super.key,
    required this.rideId,
    required this.revieweeId,
    required this.onSubmitSuccess,
  });

  // Helper to easily show this dialog from any screen
  static void show(
    BuildContext context,
    String rideId,
    String revieweeId,
    Function(Map<String, dynamic>) onSuccess,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => RatingDialog(
            rideId: rideId,
            revieweeId: revieweeId,
            onSubmitSuccess: onSuccess,
          ),
    );
  }

  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _isLoading = false;
  String _error = "";

  Future<void> _handleSubmit() async {
    setState(() {
      _isLoading = true;
      _error = "";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rides/ratings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "rideId": widget.rideId,
          "revieweeId": widget.revieweeId,
          "rating": _rating,
          "review": _reviewController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rating submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        final data = jsonDecode(response.body);
        widget.onSubmitSuccess(data['rating'] ?? {});
        Navigator.pop(context); // Close the dialog
      } else {
        setState(
          () =>
              _error =
                  jsonDecode(response.body)['error'] ??
                  "Error submitting rating",
        );
      }
    } catch (e) {
      setState(() => _error = "Network error. Please try again.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text(
        "Rate the Ride",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How was your experience?",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 15),

          // Star Rating Dropdown (Can be swapped for interactive star icons later)
          DropdownButtonFormField<int>(
            value: _rating,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            items:
                [1, 2, 3, 4, 5].map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text("$r Stars ${'⭐' * r}"),
                  );
                }).toList(),
            onChanged: (val) => setState(() => _rating = val!),
          ),
          const SizedBox(height: 15),

          // Review Text Field
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Write your review...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
          onPressed: _isLoading ? null : _handleSubmit,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text("Submit", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
