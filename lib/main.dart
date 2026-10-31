import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for web
import 'web_url_strategy.dart' if (dart.library.io) 'web_url_strategy_stub.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/add_complaint_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_panel_screen.dart';
import 'screens/complaint_screen.dart';
import 'screens/complaint_detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/emergency_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/category_screen.dart';
import 'screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    configureUrl();
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (e) {
    print('Firebase initialization error: $e');
    runApp(ErrorScreen(errorMessage: e.toString()));
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
    GoRoute(path: '/complaint', builder: (context, state) => const ComplaintScreen()),
    GoRoute(path: '/add-complaint', builder: (context, state) => const AddComplaintScreen()),
    GoRoute(path: '/admin-panel', builder: (context, state) => const AdminPanelScreen()),
    GoRoute(path: '/admin-dashboard', builder: (context, state) => const AdminDashboardScreen()),
    GoRoute(path: '/emergency', builder: (context, state) => const EmergencyScreen()),
    GoRoute(
      path: '/tracking',
      builder: (context, state) {
        final docId = state.extra as String?;
        if (docId == null) {
          return const Scaffold(
            body: Center(child: Text('No complaint ID provided')),
          );
        }
        return ComplaintDetailScreen(docId: docId);
      },
    ),
    GoRoute(
      path: '/category/:category',
      builder: (context, state) => CategoryScreen(category: state.pathParameters['category']!),
    ),
  ],
  redirect: (context, state) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final bool isOnWelcomePage = state.uri.path == '/welcome';
    final bool isOnLoginPage = state.uri.path == '/login';
    final bool isOnRegisterPage = state.uri.path == '/register';
    final bool isOnHomePage = state.uri.path == '/home';

    print('Redirect check: isLoggedIn=$isLoggedIn, path=${state.uri.path}');

    if (!isLoggedIn && !isOnWelcomePage && !isOnLoginPage && !isOnRegisterPage) {
      print('Redirecting to /welcome due to not logged in');
      return '/welcome';
    }
    if (isLoggedIn && (isOnWelcomePage || isOnLoginPage || isOnRegisterPage)) {
      print('Redirecting to /home due to logged in user on auth pages');
      return '/home';
    }
    if (!isLoggedIn && state.uri.path.startsWith('/category/')) {
      print('Redirecting to /welcome from category page due to not logged in');
      return '/welcome';
    }
    if (isLoggedIn && !isOnHomePage && state.uri.path == '/') {
      print('Redirecting to /home from root due to logged in');
      return '/home';
    }
    return null;
  },
  errorBuilder: (context, state) => ErrorScreen(errorMessage: state.error.toString()),
);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: 'CivicEase',
      theme: ThemeData.dark().copyWith(
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: AppTheme.secondaryColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  const ErrorScreen({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Error: $errorMessage', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}