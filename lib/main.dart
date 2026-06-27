import 'package:fitness_app/screens/sign_in_screen.dart';
import 'package:fitness_app/screens/home_screen.dart';
import 'package:fitness_app/screens/sign_up_screen.dart';
import 'package:fitness_app/screens/workout.dart';
import 'package:fitness_app/screens/nutrition.dart';
import 'package:fitness_app/screens/progress.dart';
import 'package:fitness_app/screens/map.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Color(0xFF1E1A32),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1E1A32),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
              color: Colors.yellow
          ),
          displayMedium: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.white
          ),
          bodyLarge: TextStyle(
              fontSize: 18.0,
              color: Colors.white
          ),
          bodyMedium: TextStyle(
              fontSize: 16.0,
              color: Colors.white70
          ),
          bodySmall: TextStyle(
              fontSize: 14.0,
              color: Colors.white54
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
            textStyle: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: Colors.yellow.withOpacity(0.3),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2438),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purpleAccent.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.purpleAccent, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.white54),
          hintStyle: TextStyle(color: Colors.white38),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        cardTheme: CardThemeData(
          color: Color(0xFF2A2438),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1A32),
          selectedItemColor: Colors.yellow,
          unselectedItemColor: Colors.white54,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Use StreamBuilder to check authentication state
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show loading screen while checking auth state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          // If user is logged in, go to home screen
          if (snapshot.hasData && snapshot.data != null) {
            print("✅ User is logged in: ${snapshot.data!.email}");
            return HomeScreen();
          }

          // If no user is logged in, go to sign in screen
          print("ℹ️ No user logged in, showing sign in screen");
          return SignInScreen();
        },
      ),
      routes: {
        '/signin': (context) => SignInScreen(),
        '/home': (context) => HomeScreen(),
        '/signup': (context) => SignUpScreen(),
        '/workout': (context) => WorkoutScreen(),
        '/nutrition': (context) => NutritionScreen(),
        '/progress': (context) => ProgressTrackingScreen(),
        '/map': (context) => MapTilerCustomMap(),
      },
      // Error handling for undefined routes
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Color(0xFF1E1A32),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.yellow, size: 64),
                  SizedBox(height: 20),
                  Text(
                    'Page Not Found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'The requested page does not exist',
                    style: TextStyle(color: Colors.white54),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                    child: Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Loading screen widget
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Color(0xFF1E1A32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or loading animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 60,
                color: Colors.yellow,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              color: Colors.yellow,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Fitness App',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}