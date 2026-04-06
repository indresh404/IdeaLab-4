import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/intro_page.dart';
import 'screens/login_page.dart';
import 'features/auth/presentation/signup_stepper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/user_page.dart';
import 'features/alerts/presentation/alert_detail_screen.dart';
import 'features/admin/presentation/admin_dashboard.dart';
import 'features/admin/presentation/create_alert_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'core/services/notification_service.dart';

final notificationServiceProvider = Provider((ref) => NotificationService());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable offline persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    const ProviderScope(
      child: CrisisClarityApp(),
    ),
  );
}

// Custom Listenable to trigger router redirects without recreating the router
class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}

final _routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = RouterRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = ref.watch(authStateProvider);
          final profileState = ref.watch(userProfileProvider);
          
          return authState.when(
            data: (user) {
              if (user == null) return const IntroPage();
              
              return profileState.when(
                data: (profile) {
                  if (profile != null) {
                    return profile.role == 'admin' ? const AdminDashboard() : const UserPage();
                  }
                  return const SignupStepper();
                },
                loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SignupStepper(),
              );
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (_, __) => const IntroPage(),
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupStepper(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const UserPage(),
      ),
      GoRoute(
        path: '/alert/:id',
        builder: (context, state) => AlertDetailScreen(
          alertId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/create-alert',
        builder: (context, state) => const CreateAlertScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final profileState = ref.read(userProfileProvider);
      
      final user = authState.value;
      final profile = profileState.value;
      final currentPath = state.matchedLocation;
      
      // 1. Loading state
      if (authState.isLoading || (user != null && profileState.isLoading)) {
        return null; 
      }
      
      debugPrint('Router Redirect - Path: $currentPath, User: ${user?.uid}, Profile: ${profile?.name}');

      // 2. Unauthenticated
      if (user == null) {
        if (currentPath == '/' || currentPath == '/login' || currentPath == '/signup') {
          return null;
        }
        return '/';
      }
      
      // 3. Authenticated but NO profile
      if (profile == null) {
        if (currentPath == '/signup') return null;
        return '/signup';
      }
      
      // 4. Authenticated WITH profile
      // Allow them to STAY on /signup until they manually leave
      if (currentPath == '/signup') {
        return null;
      }
      
      // Prevent access to login/intro if profile exists
      if (currentPath == '/' || currentPath == '/login') {
        return profile.role == 'admin' ? '/admin' : '/home';
      }
      
      // 5. Admin vs Regular routing
      if (profile.role == 'admin') {
        if (currentPath == '/home') return '/admin';
      } else {
        if (currentPath.startsWith('/admin')) return '/home';
      }
      
      return null;
    },
  );
});

class CrisisClarityApp extends ConsumerWidget {
  const CrisisClarityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    
    // Initialize Notification Service
    ref.listen(userProfileProvider, (previous, next) {
      if (next.value != null) {
        ref.read(notificationServiceProvider).init();
        ref.read(notificationServiceProvider).subscribeToWard(next.value!.location);
      }
    });

    return MaterialApp.router(
      title: 'CrisisClarity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}