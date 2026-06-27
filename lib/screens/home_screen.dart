import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in_screen.dart';
import 'workout_detail.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  String userName = 'FitFriend';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          userEmail = user.email ?? '';
          userName = user.displayName ?? user.email?.split('@')[0] ?? 'FitFriend';
        });

        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data()?['name'] != null) {
          setState(() {
            userName = userDoc.data()?['name'] ?? userName;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void signOut() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/signin');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/workout');
        break;
      case 2:
        Navigator.pushNamed(context, '/progress');
        break;
      case 3:
        Navigator.pushNamed(context, '/nutrition');
        break;
      case 4:
        Navigator.pushNamed(context, '/map');
        break;
    }
  }

  void _showArticleDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2438),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.article, color: Colors.pinkAccent),
            SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.pinkAccent),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
            ),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A32),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1A32),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $userName',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (userEmail.isNotEmpty)
              Text(
                userEmail,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.fitness_center, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/home');
          },
        ),
        centerTitle: false,
        actions: [
          // Notification icon has been removed
          PopupMenuButton<String>(
            icon: Icon(Icons.person, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                signOut();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Logout'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "It's time to challenge your limits.",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Top Menu
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMenuItem(Icons.fitness_center, 'Workout', '/workout'),
                    const SizedBox(width: 16),
                    _buildMenuItem(Icons.bar_chart, 'Progress', '/progress'),
                    const SizedBox(width: 16),
                    _buildMenuItem(Icons.fastfood, 'Nutrition', '/nutrition'),
                    const SizedBox(width: 16),
                    _buildMenuItem(Icons.map, 'Map', '/map'),
                    const SizedBox(width: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Welcome Card (Replacing Today's Progress)
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/workout');
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.pinkAccent.withOpacity(0.3),
                        Colors.purpleAccent.withOpacity(0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ready for a workout?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start your fitness journey today with personalized workouts designed just for you!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/workout');
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.pinkAccent,
                          child: Icon(Icons.arrow_forward, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recommendations Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Workout Recommendations',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/workout');
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(color: Colors.pinkAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildRecommendationCard(
                      'Squat Exercise',
                      '12 Minutes',
                      '120 Kcal',
                      'images/squat-exercise.png',
                    ),
                    const SizedBox(width: 16),
                    _buildRecommendationCard(
                      'Full Body Stretching',
                      '12 Minutes',
                      '120 Kcal',
                      'images/full-body-stretching.png',
                    ),
                    const SizedBox(width: 16),
                    _buildRecommendationCard(
                      'Glute Activation',
                      '15 Minutes',
                      '150 Kcal',
                      'images/abs.png',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Weekly Challenge Section
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(
                        workoutName: 'Plank With Hip Twist',
                        duration: '15 Minutes',
                        difficulty: 'Intermediate',
                        imagePath: 'images/plank-twist.png',
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.purpleAccent,
                        Colors.pinkAccent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Weekly Challenge',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Plank With Hip Twist',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Strengthen your core with this effective exercise',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'images/plank-twist.png',
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Fitness Articles Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Fitness Articles',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'View All',
                      style: TextStyle(color: Colors.pinkAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Supplement Guide Article
                    GestureDetector(
                      onTap: () {
                        _showArticleDialog(
                            'Essential Supplements Guide for Women',
                            '''🌟 *Essential Supplements for Women's Fitness:*

1. *Protein Powder* - Helps muscle recovery and growth
   - Whey protein or plant-based options
   - Best taken after workouts

2. *Multivitamin* - Fills nutritional gaps
   - Look for iron, calcium, and B vitamins
   - Especially important for active women

3. *Omega-3 Fatty Acids* - Reduces inflammation
   - Supports joint health
   - Improves recovery time

4. *Vitamin D* - Bone health and immunity
   - Many women are deficient
   - Supports muscle function

5. *Probiotics* - Gut health and digestion
   - Improves nutrient absorption
   - Boosts immunity

*Tip:* Always consult with a healthcare provider before starting any supplement regimen.'''
                        );
                      },
                      child: Container(
                        width: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2438),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.tealAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.asset(
                                'images/supplement.png',
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Supplement Guide',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Essential supplements for women\'s fitness',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 12, color: Colors.tealAccent),
                                      SizedBox(width: 4),
                                      Text(
                                        '5 min read',
                                        style: TextStyle(
                                          color: Colors.tealAccent,
                                          fontSize: 10,
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
                    ),

                    const SizedBox(width: 16),

                    // Daily Routine Article
                    GestureDetector(
                      onTap: () {
                        _showArticleDialog(
                            'Effective Daily Fitness Routine',
                            '''📅 *Daily Fitness Routine for Busy Women:*

*Morning (7 AM):*
• 5-min morning stretch
• 10-min HIIT workout
• Protein-rich breakfast

*Mid-day (1 PM):*
• 15-min lunch break walk
• Desk stretches
• Stay hydrated

*Evening (6 PM):*
• 30-min focused workout:
  - Mon: Lower body
  - Tue: Upper body
  - Wed: Cardio
  - Thu: Yoga/stretching
  - Fri: Full body
  - Sat: Active rest (walking)
  - Sun: Rest day

*Night (9 PM):*
• 10-min bedtime stretching
• Prepare gym clothes for tomorrow
• Plan next day\'s meals

*Weekly Tips:*
1. Schedule workouts like appointments
2. Find an accountability partner
3. Mix up routines to prevent boredom
4. Listen to your body - rest when needed
5. Track progress weekly

*Remember:* Consistency beats intensity!'''
                        );
                      },
                      child: Container(
                        width: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2438),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orangeAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.asset(
                                'images/daily-routine.png',
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Daily Routines',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Structured fitness routines',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 12, color: Colors.orangeAccent),
                                      SizedBox(width: 4),
                                      Text(
                                        '7 min read',
                                        style: TextStyle(
                                          color: Colors.orangeAccent,
                                          fontSize: 10,
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
                    ),

                    const SizedBox(width: 16),

                    // Nutrition Tips Article
                    GestureDetector(
                      onTap: () {
                        _showArticleDialog(
                            'Nutrition Tips for Women',
                            '''🍎 *Nutrition Tips for Active Women:*

*Pre-Workout (1-2 hours before):*
• Complex carbs + protein
• Banana with peanut butter
• Oatmeal with berries

*Post-Workout (within 30 min):*
• Protein + simple carbs
• Protein shake
• Greek yogurt with fruit

*Daily Nutrition Goals:*
• 1.2-1.6g protein per kg body weight
• 5+ servings of fruits/vegetables
• Stay hydrated (2-3L water daily)

*Meal Timing:*
• Eat every 3-4 hours
• Don\'t skip breakfast
• Evening meal should be light

*Healthy Snacks:*
• Nuts and seeds
• Fruit with nut butter
• Vegetable sticks with hummus
• Hard-boiled eggs

*Listen to your body* and adjust portions based on activity level!'''
                        );
                      },
                      child: Container(
                        width: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2438),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.asset(
                                'images/full-body-stretching.png',
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nutrition Tips',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Fuel your workouts right',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 12, color: Colors.greenAccent),
                                      SizedBox(width: 4),
                                      Text(
                                        '4 min read',
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 10,
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1A32),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pinkAccent,
                  Colors.purpleAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
      String title, String duration, String calories, String imageUrl) {

    // Function to get color based on workout type
    Color getCardColor(String workoutTitle) {
      if (workoutTitle.contains('Squat')) {
        return Colors.purpleAccent;
      } else if (workoutTitle.contains('Stretching')) {
        return Colors.tealAccent;
      } else {
        return Colors.pinkAccent;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutDetailScreen(
              workoutName: title,
              duration: duration,
              difficulty: 'Beginner',
              imagePath: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2438),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: getCardColor(title).withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Image.asset(
                imageUrl,
                height: 80,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$duration | $calories',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}