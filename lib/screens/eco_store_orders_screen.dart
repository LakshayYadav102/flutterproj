import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class EcoStoreOrdersScreen extends StatefulWidget {
  const EcoStoreOrdersScreen({super.key});

  @override
  _EcoStoreOrdersScreenState createState() => _EcoStoreOrdersScreenState();
}

class _EcoStoreOrdersScreenState extends State<EcoStoreOrdersScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        setState(() {
          _error = "Please log in to view orders.";
          _isLoading = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/store/orders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        setState(() {
          _orders = jsonDecode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load orders.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network error fetching orders.";
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("My Order History"),
        backgroundColor: Colors.green[800],
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : _error.isNotEmpty
              ? Center(
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              )
              : _orders.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("🛒", style: TextStyle(fontSize: 60)),
                    const SizedBox(height: 20),
                    const Text(
                      "You haven't placed any orders yet!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "Head over to the EcoStore and use your GreenCoins to grab some sustainable gear.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                      ),
                      onPressed:
                          () => Navigator.pop(
                            context,
                          ), // Assuming they navigated from the Store
                      child: const Text(
                        "Shop Now",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final order = _orders[index];
                  final product = order['product'] ?? {};

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  product['image'] ??
                                      "https://via.placeholder.com/800x600.png?text=No+Image",
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (c, e, s) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey[300],
                                      ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name'] ?? "Product Unavailable",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Ordered on: ${DateTime.parse(order['createdAt']).toLocal().toString().split(' ')[0]}",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          order['status'],
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _getStatusColor(
                                            order['status'],
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        order['status']
                                            .toString()
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(
                                            order['status'],
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Divider(),
                          ),
                          Text(
                            "Shipped to: ${order['shippingAddress']}",
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Original Price:",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    Text("₹${order['originalPrice']}"),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Coins Used:",
                                      style: TextStyle(color: Colors.green),
                                    ),
                                    Text(
                                      "- ${order['coinsUsed']} 🪙",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Total Paid:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "₹${order['finalAmountPaid']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
