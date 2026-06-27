import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeName;
  final String imagePath;
  final Map<String, dynamic> recipeData;

  const RecipeDetailScreen({
    Key? key,
    required this.recipeName,
    required this.imagePath,
    required this.recipeData,
  }) : super(key: key);

  @override
  _RecipeDetailScreenState createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isFavorite = false;
  bool _isAddedToToday = false;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _checkIfAddedToToday();
  }

  // Check if recipe is already in favorites
  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.recipeName)
          .get();

      if (mounted) {
        setState(() {
          _isFavorite = doc.exists;
        });
      }
    } catch (e) {
      print('Error checking favorite: $e');
    }
  }

  // Check if recipe is already added to today's meals
  Future<void> _checkIfAddedToToday() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyMeals')
          .doc(dateKey)
          .collection('meals')
          .doc(widget.recipeName)
          .get();

      if (mounted) {
        setState(() {
          _isAddedToToday = doc.exists;
        });
      }
    } catch (e) {
      print('Error checking today\'s meal: $e');
    }
  }

  // Add/Remove from favorites
  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showToast('Please sign in to save favorites');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final favoritesRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(widget.recipeName);

      if (_isFavorite) {
        // Remove from favorites
        await favoritesRef.delete();
        if (mounted) {
          setState(() {
            _isFavorite = false;
          });
        }
        _showToast('Removed from favorites');
      } else {
        // Add to favorites
        await favoritesRef.set({
          'name': widget.recipeName,
          'image': widget.imagePath,
          'calories': widget.recipeData['calories'],
          'protein': widget.recipeData['protein'],
          'carbs': widget.recipeData['carbs'],
          'fat': widget.recipeData['fat'],
          'prepTime': widget.recipeData['prepTime'],
          'addedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() {
            _isFavorite = true;
          });
        }
        _showToast('Added to favorites');
      }
    } catch (e) {
      _showToast('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add/Remove from today's meals
  Future<void> _toggleTodayMeal() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showToast('Please sign in to track meals');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final today = DateTime.now();
      final dateKey = '${today.year}-${today.month}-${today.day}';

      final mealRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dailyMeals')
          .doc(dateKey)
          .collection('meals')
          .doc(widget.recipeName);

      if (_isAddedToToday) {
        // Remove from today's meals
        await mealRef.delete();
        if (mounted) {
          setState(() {
            _isAddedToToday = false;
          });
        }
        _showToast('Removed from today\'s meals');
      } else {
        // Add to today's meals with meal type
        final mealType = await _showMealTypeDialog();
        if (mealType == null) return; // User cancelled

        await mealRef.set({
          'name': widget.recipeName,
          'image': widget.imagePath,
          'calories': widget.recipeData['calories'],
          'protein': widget.recipeData['protein'],
          'carbs': widget.recipeData['carbs'],
          'fat': widget.recipeData['fat'],
          'prepTime': widget.recipeData['prepTime'],
          'mealType': mealType,
          'addedAt': FieldValue.serverTimestamp(),
          'date': dateKey,
        });

        // Update daily totals
        await _updateDailyTotals(dateKey, mealType);

        if (mounted) {
          setState(() {
            _isAddedToToday = true;
          });
        }
        _showToast('Added to $mealType');
      }
    } catch (e) {
      _showToast('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Update daily nutrition totals
  Future<void> _updateDailyTotals(String dateKey, String mealType) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final totalsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dailyMeals')
        .doc(dateKey);

    final totalsDoc = await totalsRef.get();
    final currentCalories = totalsDoc.exists ? totalsDoc.data()!['totalCalories'] ?? 0 : 0;
    final currentProtein = totalsDoc.exists ? totalsDoc.data()!['totalProtein'] ?? 0 : 0;

    await totalsRef.set({
      'totalCalories': currentCalories + widget.recipeData['calories'],
      'totalProtein': currentProtein + widget.recipeData['protein'],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Show dialog to select meal type
  Future<String?> _showMealTypeDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2438),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Select Meal Type',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMealTypeOption('Breakfast', '🍳'),
              _buildMealTypeOption('Lunch', '🍱'),
              _buildMealTypeOption('Dinner', '🌙'),
              _buildMealTypeOption('Snack', '🍎'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealTypeOption(String type, String emoji) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 24)),
      title: Text(
        type,
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () {
        Navigator.pop(context, type);
      },
      tileColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF2A2438),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1A32),
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E1A32),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: widget.recipeName,
                child: Image.asset(
                  widget.imagePath,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: Colors.black.withOpacity(0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
              title: Text(
                widget.recipeName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: _isLoading ? null : _toggleFavorite,
              ),
            ],
          ),

          // Recipe Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nutrition Stats
                  _buildNutritionStats(),
                  const SizedBox(height: 30),

                  // Prep Time
                  _buildPrepTime(),
                  const SizedBox(height: 30),

                  // Ingredients
                  _buildSectionTitle('🥗 Ingredients'),
                  const SizedBox(height: 12),
                  _buildIngredientsList(),
                  const SizedBox(height: 30),

                  // Instructions
                  _buildSectionTitle('👩‍🍳 Cooking Instructions'),
                  const SizedBox(height: 12),
                  _buildInstructionsList(),
                  const SizedBox(height: 30),

                  // Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2438),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Nutritional Information',
            style: TextStyle(
              color: Color(0xFFDBF352),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem(
                icon: FontAwesomeIcons.fire,
                value: '${widget.recipeData['calories']}',
                label: 'Calories',
                color: const Color(0xFFFF6B6B),
              ),
              _buildNutritionItem(
                icon: FontAwesomeIcons.dumbbell,
                value: '${widget.recipeData['protein']}g',
                label: 'Protein',
                color: const Color(0xFF4ECDC4),
              ),
              _buildNutritionItem(
                icon: FontAwesomeIcons.breadSlice,
                value: '${widget.recipeData['carbs']}g',
                label: 'Carbs',
                color: const Color(0xFFFFD166),
              ),
              _buildNutritionItem(
                icon: FontAwesomeIcons.oilWell,
                value: '${widget.recipeData['fat']}g',
                label: 'Fat',
                color: const Color(0xFF06D6A0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPrepTime() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDBF352).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const FaIcon(
            FontAwesomeIcons.clock,
            color: Color(0xFFDBF352),
          ),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preparation Time',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.recipeData['prepTime']} minutes',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildIngredientsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2438),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: (widget.recipeData['ingredients'] as List<String>)
            .map((ingredient) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBF352),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ingredient,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildInstructionsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2438),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: (widget.recipeData['instructions'] as List<String>)
            .asMap()
            .entries
            .map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBF352),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: CircularProgressIndicator(
              color: Color(0xFFDBF352),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _toggleFavorite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFavorite
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF2A2438),
                  foregroundColor: _isFavorite ? Colors.red : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _isFavorite ? Colors.red : const Color(0xFFDBF352),
                      width: _isFavorite ? 0 : 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFavorite ? 'In Favorites' : 'Add to Favorites',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _isFavorite ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _toggleTodayMeal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAddedToToday
                      ? const Color(0xFF06D6A0)
                      : const Color(0xFFDBF352),
                  foregroundColor: _isAddedToToday ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFDBF352).withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isAddedToToday ? Icons.check : Icons.add,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isAddedToToday ? 'Added!' : "Today's Meal",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
