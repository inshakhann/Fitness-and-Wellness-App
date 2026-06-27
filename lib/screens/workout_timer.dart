import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class WorkoutTimerScreen extends StatefulWidget {
  final String workoutName;
  final String totalDuration;
  final List<String> workoutSteps;
  final VoidCallback? onWorkoutComplete;
  final int? calories;
  final String? difficulty;

  WorkoutTimerScreen({
    required this.workoutName,
    required this.totalDuration,
    required this.workoutSteps,
    this.onWorkoutComplete,
    this.calories = 120,
    this.difficulty = 'Intermediate',
  });

  @override
  _WorkoutTimerScreenState createState() => _WorkoutTimerScreenState();
}

class _WorkoutTimerScreenState extends State<WorkoutTimerScreen>
    with SingleTickerProviderStateMixin {
  int _totalSeconds = 0;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  late Timer _timer;
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  List<int> _stepTimes = [];
  List<int> _stepStartTimes = [];

  // Get color based on workout type
  Color getWorkoutColor() {
    if (widget.workoutName.contains('Lower Body') ||
        widget.workoutName.contains('Squat')) {
      return Colors.purpleAccent;
    } else if (widget.workoutName.contains('Upper Body')) {
      return Colors.blueAccent;
    } else if (widget.workoutName.contains('Full Body')) {
      return Colors.green;
    } else if (widget.workoutName.contains('Glutes') ||
        widget.workoutName.contains('Abs')) {
      return Colors.pinkAccent;
    } else if (widget.workoutName.contains('Yoga')) {
      return Colors.tealAccent;
    } else if (widget.workoutName.contains('Cardio') ||
        widget.workoutName.contains('HIIT')) {
      return Colors.orangeAccent;
    } else if (widget.workoutName.contains('Challenge')) {
      return Colors.yellow;
    } else {
      return Colors.pinkAccent;
    }
  }

  @override
  void initState() {
    super.initState();

    // Parse total duration (e.g., "20" minutes)
    _totalSeconds = int.tryParse(widget.totalDuration) ?? 20;
    _totalSeconds *= 60; // Convert to seconds

    // Initialize step times (equal distribution for now)
    _calculateStepTimes();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _calculateStepTimes() {
    // Equal time for each step
    int stepDuration = _totalSeconds ~/ widget.workoutSteps.length;
    if (stepDuration < 30) stepDuration = 30; // Minimum 30 seconds per step

    _stepTimes = List.generate(widget.workoutSteps.length, (index) => stepDuration);
    _stepStartTimes = [0];

    for (int i = 1; i < widget.workoutSteps.length; i++) {
      _stepStartTimes.add(_stepStartTimes[i-1] + _stepTimes[i-1]);
    }
  }

  @override
  void dispose() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_elapsedSeconds < _totalSeconds) {
        setState(() {
          _elapsedSeconds++;

          // Update current step based on elapsed time
          for (int i = 0; i < _stepStartTimes.length; i++) {
            if (_elapsedSeconds >= _stepStartTimes[i] &&
                (i == _stepStartTimes.length - 1 ||
                    _elapsedSeconds < _stepStartTimes[i + 1])) {
              _currentStep = i;
              break;
            }
          }
        });
      } else {
        _timer.cancel();
        _animationController.stop();
        setState(() {
          _isRunning = false;
          _isCompleted = true;
        });
        _completeWorkout();
        _showCompletionDialog();
      }
    });
    _animationController.repeat(reverse: true);
  }

  void _pauseTimer() {
    if (_timer.isActive) {
      _timer.cancel();
      _animationController.stop();
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _resumeTimer() {
    if (!_timer.isActive && _elapsedSeconds < _totalSeconds) {
      _startTimer();
    }
  }

  void _resetTimer() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    setState(() {
      _elapsedSeconds = 0;
      _currentStep = 0;
      _isRunning = false;
      _isCompleted = false;
    });
    _animationController.stop();
  }

  Future<void> _saveWorkoutToProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return;
    }

    try {
      final durationMinutes = _elapsedSeconds ~/ 60;
      final calories = widget.calories ?? (durationMinutes * 8).clamp(50, 500);
      final now = DateTime.now();
      final date = DateFormat('yyyy-MM-dd').format(now);
      final difficulty = widget.difficulty ?? 'Intermediate';

      print('Saving workout: ${widget.workoutName}');

      // Convert steps to exercises format
      List<Map<String, dynamic>> exercisesList = widget.workoutSteps.asMap().entries.map((entry) {
        int index = entry.key;
        String step = entry.value;

        // Parse step string (e.g., "Warm Up: 05:00")
        String name = step.split(':').first.trim();
        String durationText = step.split(':').length > 1 ? step.split(':').last.trim() : '00:00';

        return {
          'name': name,
          'sets': 1, // Default sets
          'reps': 1, // Default reps
          'duration': durationText,
          'step': index + 1,
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
        'durationText': '${durationMinutes} minutes',
        'calories': calories,
        'date': date,
        'timestamp': Timestamp.now(),
        'completedAt': Timestamp.now(), // ADD THIS
        'type': 'workout',
        'difficulty': difficulty,
        'exercises': exercisesList, // ADD THIS - IMPORTANT!
        'exercisesCount': exercisesList.length,
        'completed': true,
      });

      // Also save to combined activities collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .add({
        'title': 'Completed: ${widget.workoutName}',
        'description': '$difficulty • $durationMinutes min',
        'calories': calories,
        'type': 'workout',
        'timestamp': Timestamp.now(),
        'date': date,
        'icon': 'fitness_center',
      });

      // Update user stats
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'totalWorkoutMinutes': FieldValue.increment(durationMinutes),
        'totalWorkouts': FieldValue.increment(1),
        'totalCaloriesBurned': FieldValue.increment(calories),
        'lastWorkout': Timestamp.now(),
      });

      print('✅ Workout saved to progress: ${widget.workoutName}');
      print('✅ Exercises saved: ${exercisesList.length} exercises');

      // Call callback if provided
      if (widget.onWorkoutComplete != null) {
        widget.onWorkoutComplete!();
      }
    } catch (e) {
      print('❌ Error saving workout to progress: $e');
    }
  }

  void _completeWorkout() async {
    // Ensure at least 1 minute is recorded
    if (_elapsedSeconds < 60) {
      _elapsedSeconds = 60;
    }

    await _saveWorkoutToProgress();
  }

  void _finishWorkoutEarly() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    _animationController.stop();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
    _completeWorkout();
    _showCompletionDialog();
  }

  // Simple animation based on workout type
  Widget _buildExerciseAnimation() {
    Color workoutColor = getWorkoutColor();

    if (widget.workoutName.contains('Lower Body') ||
        widget.workoutName.contains('Squat')) {
      // Squat animation
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value * 20),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [workoutColor, workoutColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: workoutColor.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_walk,
                size: 50,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    } else if (widget.workoutName.contains('Upper Body')) {
      // Arm animation
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _animation.value * 1.0,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [workoutColor, workoutColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.fitness_center,
                size: 50,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    } else if (widget.workoutName.contains('Cardio') ||
        widget.workoutName.contains('HIIT')) {
      // Cardio animation
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + _animation.value * 0.2,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [workoutColor, Colors.redAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.directions_run,
                size: 50,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    } else {
      // Default animation
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + _animation.value * 0.05,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [workoutColor, workoutColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.favorite,
                size: 50,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildStepProgress(int stepIndex) {
    if (_elapsedSeconds < _stepStartTimes[stepIndex]) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.3),
          border: Border.all(color: Colors.grey),
        ),
        child: Center(
          child: Text(
            '${stepIndex + 1}',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    } else if (_elapsedSeconds >= _stepStartTimes[stepIndex] &&
        _elapsedSeconds < _stepStartTimes[stepIndex] + _stepTimes[stepIndex]) {
      double progress = (_elapsedSeconds - _stepStartTimes[stepIndex]) / _stepTimes[stepIndex];
      return Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(getWorkoutColor()),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: getWorkoutColor().withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                '${stepIndex + 1}',
                style: TextStyle(color: getWorkoutColor(), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green,
        ),
        child: Center(
          child: Icon(Icons.check, color: Colors.white, size: 16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int remainingSeconds = _totalSeconds - _elapsedSeconds;
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    Color workoutColor = getWorkoutColor();
    double progress = _elapsedSeconds / _totalSeconds;
    int completedMinutes = _elapsedSeconds ~/ 60;
    int estimatedCalories = widget.calories ?? (completedMinutes * 8).clamp(50, 500);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1A32),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF2A2438),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      if (_timer.isActive) {
                        _pauseTimer();
                      }
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.workoutName,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '$estimatedCalories cal • ${widget.difficulty}',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 48), // For symmetry
                ],
              ),
            ),

            // Timer Display
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),

                    // Timer Circle
                    Container(
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress Circle
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(workoutColor),
                            ),
                          ),

                          // Inner Content
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _animation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _isRunning ? 1.0 + _animation.value * 0.02 : 1.0,
                                    child: Column(
                                      children: [
                                        Text(
                                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 56,
                                            fontWeight: FontWeight.bold,
                                            color: workoutColor,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 15,
                                                color: workoutColor.withOpacity(0.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '${(_elapsedSeconds / 60).toStringAsFixed(1)} min completed',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Exercise Animation
                    Container(
                      height: 100,
                      child: Center(
                        child: _buildExerciseAnimation(),
                      ),
                    ),

                    // Current Step
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: workoutColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: workoutColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'CURRENT STEP',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: workoutColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_currentStep + 1}/${widget.workoutSteps.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              widget.workoutSteps[_currentStep],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: _elapsedSeconds >= _stepStartTimes[_currentStep]
                                  ? (_elapsedSeconds - _stepStartTimes[_currentStep]) / _stepTimes[_currentStep]
                                  : 0,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(workoutColor),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(_elapsedSeconds - _stepStartTimes[_currentStep]),
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  _formatTime(_stepTimes[_currentStep]),
                                  style: TextStyle(color: workoutColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Steps Progress
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'WORKOUT STEPS',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Total: ${_formatTime(_totalSeconds)}',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(widget.workoutSteps.length, (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      _buildStepProgress(index),
                                      SizedBox(height: 8),
                                      Container(
                                        constraints: BoxConstraints(maxWidth: 60),
                                        child: Text(
                                          'Step ${index + 1}',
                                          style: TextStyle(
                                            color: index <= _currentStep ? Colors.white : Colors.white54,
                                            fontSize: 10,
                                            fontWeight: index == _currentStep ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Steps List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EXERCISE DETAILS',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 12),
                          ...widget.workoutSteps.asMap().entries.map((entry) {
                            int index = entry.key;
                            String step = entry.value;
                            bool isCurrent = index == _currentStep;
                            bool isCompleted = index < _currentStep;

                            return Container(
                              margin: EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isCurrent ? workoutColor.withOpacity(0.2) : Color(0xFF2A2438),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrent ? workoutColor : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCompleted
                                        ? Colors.green
                                        : isCurrent
                                        ? workoutColor
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                  child: Center(
                                    child: isCompleted
                                        ? Icon(Icons.check, color: Colors.white, size: 18)
                                        : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isCurrent ? Colors.white : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  step.split(':').first,
                                  style: TextStyle(
                                    color: isCompleted || isCurrent ? Colors.white : Colors.white70,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    fontSize: isCurrent ? 16 : 14,
                                  ),
                                ),
                                subtitle: Text(
                                  step.split(':').length > 1 ? step.split(':').last.trim() : '',
                                  style: TextStyle(
                                    color: (isCompleted || isCurrent) ? Colors.white60 : Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Text(
                                  _formatTime(_stepTimes[index]),
                                  style: TextStyle(
                                    color: workoutColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    SizedBox(height: 80), // Space for control buttons
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Control Buttons
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Color(0xFF1E1A32),
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Reset Button
            Expanded(
              child: ElevatedButton(
                onPressed: _resetTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.replay, size: 20),
                    SizedBox(width: 8),
                    Text('RESET'),
                  ],
                ),
              ),
            ),

            SizedBox(width: 12),

            // Start/Pause Button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (_isRunning) {
                    _pauseTimer();
                  } else {
                    if (_elapsedSeconds >= _totalSeconds) {
                      _resetTimer();
                    }
                    _startTimer();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.red : workoutColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: workoutColor.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRunning ? Icons.pause : Icons.play_arrow,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      _isRunning ? 'PAUSE' : _elapsedSeconds == 0 ? 'START' : 'RESUME',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(width: 12),

            // Finish Button
            Expanded(
              child: ElevatedButton(
                onPressed: _finishWorkoutEarly,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag, size: 20),
                    SizedBox(width: 8),
                    Text('FINISH'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    int completedMinutes = _elapsedSeconds ~/ 60;
    if (completedMinutes == 0) completedMinutes = 1;
    int calories = widget.calories ?? (completedMinutes * 8).clamp(50, 500);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2A2438),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.pinkAccent, size: 28),
            SizedBox(width: 12),
            Text(
              'Workout Complete!',
              style: TextStyle(
                color: Colors.pinkAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amazing job! Your workout has been saved.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer, color: Colors.greenAccent, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Duration',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      Text(
                        '$completedMinutes minutes',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Calories Burned',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      Text(
                        '$calories cal',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.fitness_center, color: getWorkoutColor(), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Exercises',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                      Text(
                        '${widget.workoutSteps.length}',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your progress has been automatically saved. Keep up the great work! 💪',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: Text('Go Home'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close timer screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
            child: Text('Done'),
          ),
        ],
      ),
    ).then((_) {
      // Ensure timer is stopped
      if (_timer.isActive) {
        _timer.cancel();
      }
      _animationController.stop();
    });
  }
}