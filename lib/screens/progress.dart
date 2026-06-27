import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class ProgressTrackingScreen extends StatefulWidget {
  @override
  _ProgressTrackingScreenState createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  int _selectedIndex = 2;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.popAndPushNamed(context, '/home');
        break;
      case 1:
        Navigator.popAndPushNamed(context, '/workout');
        break;
      case 2:
      // Already on progress screen
        break;
      case 3:
        Navigator.popAndPushNamed(context, '/nutrition');
        break;
      case 4:
        Navigator.popAndPushNamed(context, '/map');
        break;
    }
  }

  // Get recent workouts completed with exercises
  Stream<QuerySnapshot> _getRecentWorkoutsStream() {
    if (_currentUser == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('workouts_completed')
        .orderBy('completedAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1A32),
      appBar: AppBar(
        backgroundColor: Color(0xFF1E1A32),
        title: Text(
          'Workout History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.popAndPushNamed(context, '/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Workout History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'All exercises you\'ve completed',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),

            // Info card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2A2438),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.yellow, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exercises Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Shows all exercises from completed workouts',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Recent workouts list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _getRecentWorkoutsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Colors.yellow));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            size: 60,
                            color: Colors.white54,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No exercises completed yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Complete your first workout to see exercises here!',
                            style: TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.popAndPushNamed(context, '/workout'),
                            icon: Icon(Icons.play_arrow),
                            label: Text('Start Workout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final workouts = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      final data = workout.data() as Map<String, dynamic>;

                      final workoutName = data['workoutName'] ?? data['title'] ?? 'Workout';
                      final duration = data['duration'] ?? 0; // Could be int or string
                      final calories = data['calories'] ?? 0;
                      final completedAt = data['completedAt'] ?? data['timestamp'];
                      final difficulty = data['difficulty'] ?? 'Beginner';

                      // Parse exercises - handle both string and list formats
                      List<dynamic> exercises = _parseExercises(data['exercises']);

                      return _buildWorkoutCard(
                        workoutName: workoutName,
                        duration: duration,
                        calories: calories,
                        completedAt: completedAt,
                        difficulty: difficulty,
                        exercises: exercises,
                        index: index,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF1E1A32),
        selectedItemColor: Colors.yellow,
        unselectedItemColor: Colors.white54,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }

  // Helper method to parse exercises from different formats
  List<dynamic> _parseExercises(dynamic exercisesData) {
    if (exercisesData == null) return [];

    try {
      if (exercisesData is List) {
        return exercisesData;
      } else if (exercisesData is String) {
        // Try to parse JSON string
        final decoded = jsonDecode(exercisesData);
        if (decoded is List) {
          return decoded;
        }
      }
    } catch (e) {
      print('Error parsing exercises: $e');
    }

    return [];
  }

  Widget _buildWorkoutCard({
    required String workoutName,
    required dynamic duration,
    required int calories,
    required dynamic completedAt,
    required String difficulty,
    required List<dynamic> exercises,
    required int index,
  }) {
    // Different colors for alternating cards
    final colors = [
      Colors.purpleAccent,
      Colors.pinkAccent,
      Colors.tealAccent,
      Colors.orangeAccent,
      Colors.blueAccent,
    ];
    final color = colors[index % colors.length];

    // Handle duration - could be int or string
    String durationText;
    if (duration is int) {
      durationText = '$duration min';
    } else if (duration is String) {
      durationText = duration;
    } else {
      durationText = '0 min';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2438),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Workout header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        workoutName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(difficulty).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        difficulty,
                        style: TextStyle(
                          color: _getDifficultyColor(difficulty),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                Row(
                  children: [
                    _buildDetailItem(
                      icon: Icons.timer,
                      value: durationText,
                      color: Colors.yellow,
                    ),
                    SizedBox(width: 16),
                    _buildDetailItem(
                      icon: Icons.local_fire_department,
                      value: '$calories cal',
                      color: Colors.orange,
                    ),
                    Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(completedAt),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDate(completedAt),
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exercises section
          if (exercises.isNotEmpty) ...[
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list, color: color, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Exercises Completed:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${exercises.length}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Exercises list
                  Column(
                    children: exercises.asMap().entries.map((entry) {
                      final exerciseIndex = entry.key;
                      final exercise = entry.value;

                      String exerciseName = '';
                      String setsReps = '';

                      if (exercise is Map) {
                        exerciseName = exercise['name'] ?? exercise['title'] ?? 'Exercise';
                        final sets = exercise['sets'] ?? exercise['setsCount'] ?? '0';
                        final reps = exercise['reps'] ?? exercise['repsCount'] ?? '0';
                        setsReps = '$sets sets × $reps reps';
                      } else if (exercise is String) {
                        exerciseName = exercise;
                        setsReps = 'Completed';
                      } else {
                        exerciseName = 'Exercise ${exerciseIndex + 1}';
                        setsReps = 'Completed';
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${exerciseIndex + 1}',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exerciseName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    setsReps,
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ] else ...[
            // If no exercises data available
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white54, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'No exercise details available for this workout',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.yellow;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Recently';

    try {
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        return DateFormat('h:mm a').format(date);
      }
    } catch (e) {
      print('Error formatting time: $e');
    }

    return 'Recently';
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Today';

    try {
      if (timestamp is Timestamp) {
        DateTime date = timestamp.toDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final workoutDay = DateTime(date.year, date.month, date.day);

        if (workoutDay.isAtSameMomentAs(today)) {
          return 'Today';
        } else if (workoutDay.isAtSameMomentAs(today.subtract(Duration(days: 1)))) {
          return 'Yesterday';
        } else {
          return DateFormat('MMM d').format(date);
        }
      }
    } catch (e) {
      print('Error formatting date: $e');
    }

    return 'Recently';
  }
}