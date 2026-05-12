import 'dart:async';
import 'dart:convert'; // ✅ Added for JWT decoding
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core Screens
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/Object_Detection_Screen.dart';
import 'screens/chatbot_screen.dart';
import 'screens/corporate_dashboard.dart';

// GreenTrail
import 'screens/carbon_calculator_screen.dart';
import 'screens/donation_screen.dart';
import 'screens/user_activity_screen.dart';
import 'screens/leaderboard_screen.dart';

// Carpooling
import 'screens/dashboard_carpool_screen.dart';
import 'screens/find_ride_screen.dart';
import 'screens/offer_ride_screen.dart';
import 'screens/my_trips_screen.dart';
import 'screens/ride_request_screen.dart';
import 'screens/ev_stations_screen.dart';
import 'screens/ride_details_screen.dart';
import 'screens/chat_screen.dart';

// Food Waste Module
import 'screens/food_waste_home_screen.dart';
import 'screens/donate_food_dashboard.dart';
import 'screens/household_donation_form_screen.dart';
import 'screens/event_donation_form_screen.dart';
import 'screens/my_donations_screen.dart';
import 'screens/require_food_dashboard_screen.dart';
import 'screens/available_food_screen.dart';
import 'screens/my_received_food_screen.dart';
import 'screens/food_waste_ngo_map_screen.dart';
import 'screens/food_waste_profile_screen.dart';
import 'screens/food_chat_screen.dart';

// EcoLearn Module
import 'screens/ecolearn_feed_screen.dart';
import 'screens/ecolearn_explore_screen.dart';
import 'screens/ecolearn_upload_screen.dart';
import 'screens/creator_profile_screen.dart';

// EcoStore Module
import 'screens/eco_store_home_screen.dart';
import 'screens/eco_store_orders_screen.dart';

// Blogs Module
import 'screens/blog_list_screen.dart';
import 'screens/create_blog_screen.dart';
import 'screens/blog_detail_screen.dart';

// Global Navigator Key
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

// Route Observer to hide the chatbot on specific screens
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
final ValueNotifier<String> currentRouteNotifier = ValueNotifier<String>('/');

class MyRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    currentRouteNotifier.value = route.settings.name ?? '';
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    currentRouteNotifier.value = previousRoute?.settings.name ?? '';
  }
}

final myRouteObserver = MyRouteObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: "assets/config/.env");
  } catch (e) {
    debugPrint("Warning: .env file not found.");
  }

  runApp(const GreenverseApp());
}

class GreenverseApp extends StatelessWidget {
  const GreenverseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      navigatorObservers: [myRouteObserver, routeObserver], // Attach observer
      debugShowCheckedModeBanner: false,
      title: 'GreenVerse',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const AuthCheck(),

      // Custom Stack overlay for the Collapsible Chatbot
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            ValueListenableBuilder<String>(
              valueListenable: currentRouteNotifier,
              builder: (context, currentRoute, _) {
                // Hide on Login, Register, Object Detection, and the Chatbot itself
                final hiddenRoutes = [
                  '/login',
                  '/register',
                  '/scan',
                  '/chatbot',
                ];
                if (hiddenRoutes.contains(currentRoute)) {
                  return const SizedBox.shrink();
                }
                return const CollapsibleChatbot();
              },
            ),
          ],
        );
      },

      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/scan': (context) => ObjectDetectionScreen(),
        '/chatbot': (context) => const ChatbotScreen(),

        // GreenTrail
        '/track': (context) => const CarbonCalculatorScreen(),
        '/donation': (context) => const DonationScreen(),
        '/user-activity': (context) => const UserActivityScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/corporate-dashboard': (context) => const CorporateDashboard(),
        // Carpooling
        '/carpool': (context) => const DashboardCarpoolScreen(),
        '/ride/find': (context) => const FindRideScreen(),
        '/my-trips': (context) => const MyTripsScreen(),
        '/ride-request': (context) => const RideRequestScreen(),
        '/ev-stations': (context) => const EVStationsScreen(),

        // Food Waste
        '/food-waste': (context) => const FoodWasteHomeScreen(),
        '/food-waste/donate': (context) => const DonateFoodDashboardScreen(),
        '/food-waste/donate/household':
            (context) => const HouseholdDonationFormScreen(),
        '/food-waste/donate/event':
            (context) => const EventDonationFormScreen(),
        '/food-waste/my-donations': (context) => const MyDonationsScreen(),
        '/food-waste/require': (context) => const RequireFoodDashboardScreen(),
        '/food-waste/available': (context) => const AvailableFoodScreen(),
        '/food-waste/received': (context) => const MyReceivedFoodScreen(),
        '/food-waste/ngos': (context) => const FoodWasteNgoMapScreen(),
        '/food-waste/profile': (context) => const FoodWasteProfileScreen(),

        // EcoLearn
        '/ecolearn/feed': (context) => const EcoLearnFeedScreen(),
        '/ecolearn/explore': (context) => const EcoLearnExploreScreen(),
        '/ecolearn/upload': (context) => const EcoLearnUploadScreen(),

        // EcoStore
        '/store': (context) => const EcoStoreHomeScreen(),
        '/store/orders': (context) => const EcoStoreOrdersScreen(),

        // Blogs
        '/blogs': (context) => const BlogListScreen(),
        '/blogs/create': (context) => const CreateBlogScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/blogs/detail') {
          final blogId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => BlogDetailScreen(blogId: blogId ?? ''),
          );
        }
        if (settings.name == '/ride/offer') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => OfferRideScreen(requestData: args),
          );
        }
        if (settings.name == '/ecolearn/creator') {
          final userId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => CreatorProfileScreen(userId: userId ?? ''),
          );
        }
        if (settings.name == '/dashboard') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder:
                (context) => DashboardScreen(userId: args?['userId'] ?? ''),
          );
        }
        if (settings.name == '/ride/details') {
          final rideId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => RideDetailsScreen(rideId: rideId ?? ''),
          );
        }
        if (settings.name == '/ride/chat') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  rideId: args?['rideId'] ?? '',
                  initialMessages: args?['messages'],
                ),
          );
        }
        if (settings.name == '/food-waste/chat') {
          final donationId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => FoodChatScreen(donationId: donationId ?? ''),
          );
        }
        return null;
      },
    );
  }
}

// Sleek, draggable, auto-collapsing Chatbot Tab
class CollapsibleChatbot extends StatefulWidget {
  const CollapsibleChatbot({super.key});

  @override
  State<CollapsibleChatbot> createState() => _CollapsibleChatbotState();
}

class _CollapsibleChatbotState extends State<CollapsibleChatbot> {
  bool _isExpanded = false;
  Timer? _collapseTimer;

  void _expand() {
    setState(() => _isExpanded = true);
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _isExpanded = false);
    });
  }

  void _collapse() {
    setState(() => _isExpanded = false);
    _collapseTimer?.cancel();
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      bottom: 120, // Placed safely above bottom nav bars
      right: _isExpanded ? 20 : -25, // Hides off-screen when not expanded
      child: GestureDetector(
        onPanUpdate: (details) {
          if (details.delta.dx < -2) {
            _expand(); // Swipe Left to reveal
          } else if (details.delta.dx > 2) {
            _collapse(); // Swipe Right to hide
          }
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!_isExpanded) {
                _expand();
              } else {
                _collapse();
                globalNavigatorKey.currentState?.pushNamed('/chatbot');
              }
            },
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              width: _isExpanded ? 60 : 40,
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(-2, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.support_agent,
                  color: Colors.white,
                  size: _isExpanded ? 30 : 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  // ✅ NEW: Helper function to manually decode and check JWT expiration
  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true; // Invalid token format

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = jsonDecode(resp);

      if (payloadMap is! Map<String, dynamic> ||
          !payloadMap.containsKey('exp')) {
        return false; // No expiration claim, assume valid
      }

      final exp = payloadMap['exp'] as int;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiresAt);
    } catch (e) {
      return true; // If anything goes wrong parsing, assume expired for safety
    }
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      if (_isTokenExpired(token)) {
        // ✅ FIX: Token is expired. Wipe storage and force login.
        await prefs.clear();
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Token is valid and fresh. Go to Home.
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 20),
            Text(
              "GreenVerse",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
