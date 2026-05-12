import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for text formatters
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';

class EcoStoreHomeScreen extends StatefulWidget {
  const EcoStoreHomeScreen({super.key});

  @override
  _EcoStoreHomeScreenState createState() => _EcoStoreHomeScreenState();
}

class _EcoStoreHomeScreenState extends State<EcoStoreHomeScreen> {
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _products = [];
  int _userCoins = 0;
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  Future<void> _fetchStoreData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');

      // Seed store (as per your React logic)
      await http.post(Uri.parse('${ApiService.baseUrl}/api/store/seed'));

      // Fetch products
      final prodRes = await http.get(
        Uri.parse('${ApiService.baseUrl}/api/store/products'),
      );

      if (prodRes.statusCode == 200) {
        _products = jsonDecode(prodRes.body);
      }

      // Fetch wallet if logged in
      if (_token != null) {
        final coinRes = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/profile/wallet'),
          headers: {'Authorization': 'Bearer $_token'},
        );
        if (coinRes.statusCode == 200) {
          _userCoins = jsonDecode(coinRes.body)['greenCoins'] ?? 0;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = "Error loading store data";
        _isLoading = false;
      });
    }
  }

  void _openCheckout(Map<String, dynamic> product) {
    if (_token == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => CheckoutBottomSheet(
            product: product,
            userCoins: _userCoins,
            onOrderSuccess: (remainingCoins) {
              setState(() {
                _userCoins = remainingCoins;
                // Optimistically update stock
                final index = _products.indexWhere(
                  (p) => p['_id'] == product['_id'],
                );
                if (index != -1) _products[index]['stock'] -= 1;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Order placed successfully! 🌿"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          "EcoStore",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_token != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Text("🪙", style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 5),
                      Text(
                        "$_userCoins",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_token != null)
            IconButton(
              icon: const Icon(Icons.local_shipping),
              tooltip: "My Orders",
              onPressed: () => Navigator.pushNamed(context, '/store/orders'),
            ),
        ],
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
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[800],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            "Convert sustainable choices into real-world rewards.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 15),
                          Text(
                            "🚀 Interactive Prototype: Dummy cards accepted.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15,
                              mainAxisSpacing: 15,
                              childAspectRatio: 0.62,
                            ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          bool isOutOfStock = product['stock'] < 1;

                          return Card(
                            elevation: 2,
                            shadowColor: Colors.grey.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                        child: Image.network(
                                          product['image'] ??
                                              "https://via.placeholder.com/800x600.png",
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (c, e, s) => Container(
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            product['category'] ?? "Item",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "₹${product['price']}",
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w900,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 36,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                isOutOfStock
                                                    ? Colors.grey[400]
                                                    : Colors.green[700],
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed:
                                              isOutOfStock
                                                  ? null
                                                  : () =>
                                                      _openCheckout(product),
                                          child: Text(
                                            isOutOfStock
                                                ? "Out of Stock"
                                                : "Buy Now",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}

// ==========================================
// BOTTOM SHEET FOR CHECKOUT (TWO-STEP)
// ==========================================
class CheckoutBottomSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final int userCoins;
  final Function(int remainingCoins) onOrderSuccess;

  const CheckoutBottomSheet({
    super.key,
    required this.product,
    required this.userCoins,
    required this.onOrderSuccess,
  });

  @override
  _CheckoutBottomSheetState createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  int _step = 1; // Step 1: Summary, Step 2: Payment Mock
  int _coinsToUse = 0;
  final TextEditingController _addressCtrl = TextEditingController();

  // Mock Card Controllers
  final TextEditingController _cardNumberCtrl = TextEditingController();
  final TextEditingController _expiryCtrl = TextEditingController();
  final TextEditingController _cvvCtrl = TextEditingController();

  bool _isProcessing = false;
  String _error = '';

  void _handleSliderChange(double value) {
    setState(() {
      _coinsToUse = value.toInt();
    });
  }

  void _proceedToStep2(num finalAmount) {
    if (_addressCtrl.text.trim().isEmpty) {
      setState(() => _error = "Please provide a shipping address.");
      return;
    }
    setState(() {
      _error = '';
      if (finalAmount == 0) {
        // Skip card details if fully paid with coins
        _initiatePayment(skipCardCheck: true);
      } else {
        _step = 2; // Go to card input screen
      }
    });
  }

  Future<void> _initiatePayment({bool skipCardCheck = false}) async {
    if (!skipCardCheck) {
      if (_cardNumberCtrl.text.length < 16 ||
          _expiryCtrl.text.isEmpty ||
          _cvvCtrl.text.isEmpty) {
        setState(() => _error = "Please enter valid mock card details.");
        return;
      }
    }

    setState(() {
      _isProcessing = true;
      _error = '';
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      // 1. Create Payment Intent
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/store/create-payment-intent'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "productId": widget.product['_id'],
          "coinsToUse": _coinsToUse,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        if (data['isFree'] == true) {
          _finalizeOrder();
        } else {
          // NATIVE STRIPE SIMULATION:
          // Pretend we are opening the Stripe UI and processing the card.
          await Future.delayed(const Duration(seconds: 2));
          _finalizeOrder();
        }
      } else {
        setState(() {
          _error = data['error'] ?? "Payment initialization failed.";
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Network error during payment init.";
        _isProcessing = false;
      });
    }
  }

  Future<void> _finalizeOrder() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/store/checkout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "productId": widget.product['_id'],
          "coinsToUse": _coinsToUse,
          "shippingAddress": _addressCtrl.text.trim(),
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        widget.onOrderSuccess(data['remainingCoins'] ?? 0);
      } else {
        setState(
          () =>
              _error =
                  jsonDecode(res.body)['error'] ?? "Order finalization failed.",
        );
      }
    } catch (e) {
      setState(() => _error = "Network error finalizing order.");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    num price = widget.product['price'] ?? 0;
    num finalAmount = price - _coinsToUse;
    if (finalAmount < 0) finalAmount = 0;

    int maxCoinsUsable =
        widget.userCoins < price ? widget.userCoins : price.toInt();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: SingleChildScrollView(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child:
              _step == 1
                  ? _buildStep1Summary(price, finalAmount, maxCoinsUsable)
                  : _buildStep2Payment(finalAmount),
        ),
      ),
    );
  }

  // --- STEP 1: ORDER SUMMARY ---
  Widget _buildStep1Summary(num price, num finalAmount, int maxCoinsUsable) {
    return Column(
      key: const ValueKey(1),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Checkout",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey[600]),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.product['image'] ?? "",
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder:
                    (c, e, s) => Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                    ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Original Price: ₹$price",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Coin Slider
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.eco, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Apply GreenCoins (1 Coin = ₹1)",
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                "You have ${widget.userCoins} coins. Using: $_coinsToUse",
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
              Slider(
                value: _coinsToUse.toDouble(),
                min: 0,
                max: maxCoinsUsable.toDouble(),
                activeColor: Colors.green[700],
                inactiveColor: Colors.green[200],
                onChanged: _handleSliderChange,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Price Breakdown
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Subtotal:", style: TextStyle(color: Colors.grey)),
                  Text(
                    "₹$price",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Coin Discount:",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "- ₹$_coinsToUse",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total to Pay:",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                  Text(
                    "₹$finalAmount",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Shipping
        TextField(
          controller: _addressCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: "Shipping Address",
            alignLabelWithHint: true,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (_error.isNotEmpty)
          Text(_error, style: const TextStyle(color: Colors.red)),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            onPressed: () => _proceedToStep2(finalAmount),
            child: Text(
              finalAmount > 0 ? "Proceed to Payment" : "Complete Free Order",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- STEP 2: MOCK STRIPE PAYMENT FORM ---
  Widget _buildStep2Payment(num finalAmount) {
    return Column(
      key: const ValueKey(2),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed:
                  () => setState(() {
                    _step = 1;
                    _error = '';
                  }),
            ),
            const Text(
              "Payment Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Demo Mode: Use '4242' repeatedly for the card number.",
                  style: TextStyle(color: Colors.blue, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Card Input Form
        TextField(
          controller: _cardNumberCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
          ],
          decoration: InputDecoration(
            labelText: "Card Number",
            hintText: "4242 4242 4242 4242",
            prefixIcon: const Icon(Icons.credit_card),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _expiryCtrl,
                keyboardType: TextInputType.datetime,
                inputFormatters: [LengthLimitingTextInputFormatter(5)],
                decoration: InputDecoration(
                  labelText: "MM/YY",
                  hintText: "12/26",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: _cvvCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "CVC",
                  hintText: "123",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        TextField(
          decoration: InputDecoration(
            labelText: "Cardholder Name",
            hintText: "John Doe",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 10),

        if (_error.isNotEmpty)
          Text(_error, style: const TextStyle(color: Colors.red)),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, // Stripe-like sleek black button
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            onPressed: _isProcessing ? null : () => _initiatePayment(),
            child:
                _isProcessing
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      "Pay ₹$finalAmount",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
