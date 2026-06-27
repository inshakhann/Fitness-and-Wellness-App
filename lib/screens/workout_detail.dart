import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'workout_timer.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final String workoutName;
  final String duration;
  final String difficulty;
  final String imagePath;
  final int? calories;
  final String? description;
  final int? exercises;
  final VoidCallback? onWorkoutComplete;

  WorkoutDetailScreen({
    required this.workoutName,
    required this.duration,
    required this.difficulty,
    required this.imagePath,
    this.calories = 120,
    this.description,
    this.exercises = 6,
    this.onWorkoutComplete,
  });

  @override
  _WorkoutDetailScreenState createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  bool _isLoading = false;
  bool _isCompleted = false;

  // Get workout description based on type
  String get _workoutDescription {
    if (widget.description != null) return widget.description!;

    if (widget.workoutName.contains('Lower Body') || widget.workoutName.contains('Squat')) {
      return 'Focus on strengthening your legs, glutes, and core. Perfect for building lower body strength and toning muscles.';
    } else if (widget.workoutName.contains('Upper Body')) {
      return 'Target your arms, shoulders, chest, and back. Build upper body strength and improve posture.';
    } else if (widget.workoutName.contains('Full Body')) {
      return 'A complete workout that engages all major muscle groups. Great for overall fitness and calorie burn.';
    } else if (widget.workoutName.contains('Glutes') || widget.workoutName.contains('Abs')) {
      return 'Focus on core strength and glute activation. Perfect for toning and shaping your midsection and lower body.';
    } else if (widget.workoutName.contains('Stretching')) {
      return 'Improve flexibility, reduce muscle tension, and enhance recovery with these gentle stretches.';
    } else if (widget.workoutName.contains('Cardio') || widget.workoutName.contains('HIIT')) {
      return 'Boost your cardiovascular health and burn calories with this energizing cardio session.';
    } else if (widget.workoutName.contains('Yoga')) {
      return 'Combine physical postures, breathing exercises, and meditation for mind-body wellness.';
    } else if (widget.workoutName.contains('Challenge')) {
      return 'Daily challenge to push your limits and build consistency in your fitness journey.';
    } else {
      return 'Complete this workout to achieve your fitness goals and improve overall health.';
    }
  }

  // Get color based on difficulty
  Color get _difficultyColor {
    switch (widget.difficulty) {
      case 'Beginner':
        return Colors.green;
      case 'Intermediate':
        return Colors.orange;
      case 'Advanced':
        return Colors.red;
      default:
        return Colors.pinkAccent;
    }
  }

  // Get exercises based on workout name
  List<Map<String, dynamic>> get _workoutExercises {
    if (widget.workoutName.contains('Lower Body') || widget.workoutName.contains('Squat')) {
      return [
        {'name': 'Warm Up', 'duration': '05:00', 'icon': Icons.directions_run, 'details': 'Dynamic leg movements'},
        {'name': 'Bodyweight Squats', 'duration': '03:00', 'icon': Icons.directions_walk, 'details': '3 sets x 15 reps'},
        {'name': 'Lunges', 'duration': '03:00', 'icon': Icons.trending_up, 'details': '3 sets x 12 each leg'},
        {'name': 'Glute Bridges', 'duration': '02:30', 'icon': Icons.arrow_upward, 'details': '3 sets x 15 reps'},
        {'name': 'Calf Raises', 'duration': '02:30', 'icon': Icons.arrow_upward, 'details': '3 sets x 20 reps'},
        {'name': 'Cool Down', 'duration': '04:00', 'icon': Icons.spa, 'details': 'Stretching and recovery'},
      ];
    } else if (widget.workoutName.contains('Upper Body')) {
      return [
        {'name': 'Warm Up', 'duration': '05:00', 'icon': Icons.directions_run, 'details': 'Arm circles and mobility'},
        {'name': 'Push-ups', 'duration': '04:00', 'icon': Icons.touch_app, 'details': '3 sets x 10-12 reps'},
        {'name': 'Tricep Dips', 'duration': '03:00', 'icon': Icons.arrow_downward, 'details': '3 sets x 12 reps'},
        {'name': 'Shoulder Press', 'duration': '03:00', 'icon': Icons.arrow_upward, 'details': '3 sets x 12 reps'},
        {'name': 'Bicep Curls', 'duration': '03:00', 'icon': Icons.fitness_center, 'details': '3 sets x 15 reps'},
        {'name': 'Cool Down', 'duration': '04:00', 'icon': Icons.spa, 'details': 'Upper body stretches'},
      ];
    } else if (widget.workoutName.contains('Full Body')) {
      return [
        {'name': 'Warm Up', 'duration': '05:00', 'icon': Icons.directions_run, 'details': 'Full body mobility'},
        {'name': 'Burpees', 'duration': '04:00', 'icon': Icons.flash_on, 'details': '3 sets x 10 reps'},
        {'name': 'Mountain Climbers', 'duration': '03:00', 'icon': Icons.directions_run, 'details': '3 sets x 30 sec'},
        {'name': 'Plank', 'duration': '03:00', 'icon': Icons.straighten, 'details': '3 sets x 30 sec'},
        {'name': 'Jumping Jacks', 'duration': '03:00', 'icon': Icons.emoji_people, 'details': '3 sets x 30 reps'},
        {'name': 'Cool Down', 'duration': '04:00', 'icon': Icons.spa, 'details': 'Full body stretching'},
      ];
    } else if (widget.workoutName.contains('Glutes') || widget.workoutName.contains('Abs')) {
      return [
        {'name': 'Warm Up', 'duration': '05:00', 'icon': Icons.directions_run, 'details': 'Hip mobility'},
        {'name': 'Hip Thrusts', 'duration': '04:00', 'icon': Icons.arrow_upward, 'details': '4 sets x 15 reps'},
        {'name': 'Glute Bridges', 'duration': '03:00', 'icon': Icons.arrow_upward, 'details': '3 sets x 15 reps'},
        {'name': 'Russian Twists', 'duration': '03:00', 'icon': Icons.rotate_right, 'details': '3 sets x 20 reps'},
        {'name': 'Leg Raises', 'duration': '03:00', 'icon': Icons.arrow_upward, 'details': '3 sets x 15 reps'},
        {'name': 'Cool Down', 'duration': '04:00', 'icon': Icons.spa, 'details': 'Hip and core stretches'},
      ];
    } else if (widget.workoutName.contains('Cardio') || widget.workoutName.contains('HIIT')) {
      return [
        {'name': 'Warm Up', 'duration': '05:00', 'icon': Icons.directions_run, 'details': 'Light cardio'},
        {'name': 'Jump Rope', 'duration': '03:00', 'icon': Icons.flash_on, 'details': 'High intensity'},
        {'name': 'High Knees', 'duration': '03:00', 'icon': Icons.directions_run, 'details': 'Fast pace'},
        {'name': 'Burpees', 'duration': '04:00', 'icon': Icons.fitness_center, 'details': 'Full body'},
        {'name': 'Mountain Climbers', 'duration': '03:00', 'icon': Icons.speed, 'details': 'Core engaged'},
        {'name': 'Cool Down', 'duration': '04:00', 'icon': Icons.spa, 'details': 'Light stretching'},
      ];
    } else {
      return [
        {'name': 'Warm Up', 'duration': '05:00', 'icon': Icons.directions_run, 'details': 'Prepare your body'},
        {'name': 'Main Exercise 1', 'duration': '04:00', 'icon': Icons.fitness_center, 'details': 'Focus on form'},
        {'name': 'Main Exercise 2', 'duration': '04:00', 'icon': Icons.fitness_center, 'details': 'Control movement'},
        {'name': 'Main Exercise 3', 'duration': '04:00', 'icon': Icons.fitness_center, 'details': 'Full range of motion'},
        {'name': 'Main Exercise 4', 'duration': '04:00', 'icon': Icons.fitness_center, 'details': 'Challenge yourself'},
        {'name': 'Cool Down', 'duration': '04:00', 'icon': Icons.spa, 'details': 'Stretching and recovery'},
      ];
    }
  }

  Future<void> _saveWorkoutToHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please sign in to track workouts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final durationMinutes = int.tryParse(widget.duration.split(' ')[0]) ?? 20;
      final calories = widget.calories ?? 120;
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);

      // Convert exercises list to proper format
      List<Map<String, dynamic>> exercisesList = _workoutExercises.map((exercise) {
        return {
          'name': exercise['name'] as String,
          'sets': exercise['name'].contains('sets') ? 3 : 3, // Default sets
          'reps': exercise['name'].contains('reps') ? 12 : 12, // Default reps
          'duration': exercise['duration'] as String,
          'details': exercise['details'] as String,
        };
      }).toList();

      // Save to workouts completed collection WITH EXERCISES
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('workouts_completed')
          .add({
        'workoutName': widget.workoutName,
        'title': widget.workoutName,
        'duration': durationMinutes,
        'durationText': widget.duration,
        'calories': calories,
        'date': date,
        'timestamp': Timestamp.now(),
        'completedAt': Timestamp.now(), // ADD THIS
        'type': 'workout',
        'difficulty': widget.difficulty,
        'exercises': exercisesList, // ADD THIS - IMPORTANT!
        'exercisesCount': exercisesList.length,
        'completed': true,
      });

      // Also save to combined activities collection for progress screen
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .add({
        'title': 'Completed: ${widget.workoutName}',
        'description': '${widget.difficulty} • ${durationMinutes} min',
        'calories': calories,
        'type': 'workout',
        'timestamp': Timestamp.now(),
        'date': date,
        'icon': 'fitness_center',
      });

      // Mark as completed
      setState(() {
        _isCompleted = true;
      });

      // Call the callback if provided
      if (widget.onWorkoutComplete != null) {
        widget.onWorkoutComplete!();
      }

      print('✅ Workout logged: ${widget.workoutName} ($calories calories)');
      print('✅ Exercises saved: ${exercisesList.length} exercises');
    } catch (e) {
      print('❌ Error saving workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _startWorkout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Extract just the minutes number
      String minutes = widget.duration.split(' ')[0];

      // Convert exercises to string list for timer screen
      List<String> exerciseSteps = _workoutExercises.map((exercise) {
        return '${exercise['name']}: ${exercise['duration']}';
      }).toList();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutTimerScreen(
            workoutName: widget.workoutName,
            totalDuration: minutes,
            workoutSteps: exerciseSteps,
            onWorkoutComplete: _saveWorkoutToHistory,
          ),
        ),
      );
    } catch (e) {
      print('Error starting workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start workout'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Quick complete button for skipping timer
  Future<void> _quickCompleteWorkout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _saveWorkoutToHistory();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Workout marked as complete! (${widget.calories} cal burned)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a moment then go back
      await Future.delayed(Duration(milliseconds: 1500));
      Navigator.pop(context);
    } catch (e) {
      print('Error completing workout: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A32),
      body: CustomScrollView(
        slivers: [
          // App Bar with back button
          SliverAppBar(
            backgroundColor: const Color(0xFF1E1A32),
            expandedHeight: 250,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isCompleted)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Image.asset(
                    widget.imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.workoutName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Workout Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Workout Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF2A2438),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.timer, widget.duration, 'Duration'),
                        _buildStatItem(Icons.local_fire_department, '${widget.calories ?? 120} Kcal', 'Calories'),
                        _buildStatItem(Icons.fitness_center, widget.difficulty, 'Level'),
                        _buildStatItem(Icons.format_list_numbered, '${widget.exercises ?? _workoutExercises.length}', 'Exercises'),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Description
                  Text(
                    'About This Workout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _workoutDescription,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Difficulty Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _difficultyColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _difficultyColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: _difficultyColor, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${widget.difficulty} Level',
                          style: TextStyle(
                            color: _difficultyColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isCompleted) ...[
                          SizedBox(width: 8),
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Exercises List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Workout Plan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_workoutExercises.length} steps',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  ..._workoutExercises.asMap().entries.map((entry) {
                    final index = entry.key;
                    final exercise = entry.value;
                    return _buildExerciseItem(
                      exercise['icon'] as IconData,
                      exercise['name'] as String,
                      exercise['duration'] as String,
                      exercise['details'] as String,
                      index + 1,
                    );
                  }).toList(),

                  SizedBox(height: 40),

                  // Action Buttons
                  Column(
                    children: [
                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading || _isCompleted ? null : _startWorkout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCompleted ? Colors.green : Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            shadowColor: (_isCompleted ? Colors.green : Colors.pinkAccent).withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isCompleted ? Icons.check : Icons.play_arrow,
                                size: 24,
                              ),
                              SizedBox(width: 10),
                              Text(
                                _isCompleted ? 'WORKOUT COMPLETED' : 'START WORKOUT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      // Quick Complete Button (for skipping timer)
                      if (!_isCompleted)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _quickCompleteWorkout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: BorderSide(color: Colors.white54),
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.done_all, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'MARK AS COMPLETE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Tips
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Tips for Success',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          '• Stay hydrated throughout the workout\n• Focus on proper form over speed\n• Breathe steadily during exercises\n• Take breaks when needed\n• Listen to your body',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.pinkAccent, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseItem(IconData icon, String name, String duration, String details, int number) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2A2438),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Number
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 16),

          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pinkAccent.withOpacity(0.8),
                  Colors.purpleAccent.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),

          SizedBox(width: 16),

          // Exercise Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Duration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pinkAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              duration,
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}