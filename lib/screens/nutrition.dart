import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_detail.dart';

class NutritionScreen extends StatefulWidget {
  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  int _selectedIndex = 3;

  final Map<String, Map<String, dynamic>> recipes = {
    'Proteins Salad': {
      'image': 'images/salad.png',
      'calories': 300,
      'protein': 25,
      'carbs': 15,
      'fat': 8,
      'prepTime': 15,
      'ingredients': [
        '200g grilled chicken breast',
        '100g cherry tomatoes',
        '1 cucumber',
        '50g mixed greens',
        '30g feta cheese',
        '2 tbsp olive oil',
        'Salt & pepper',
      ],
      'instructions': [
        'Grill chicken until cooked',
        'Chop vegetables',
        'Mix all ingredients',
        'Add olive oil and seasoning',
      ],
    },
    'Baked Salmon': {
      'image': 'images/salmon.png',
      'calories': 350,
      'protein': 35,
      'carbs': 5,
      'fat': 20,
      'prepTime': 25,
      'ingredients': [
        '2 salmon fillets',
        '2 tbsp olive oil',
        'Garlic',
        'Lemon slices',
        'Salt & pepper',
      ],
      'instructions': [
        'Preheat oven to 200°C',
        'Season salmon',
        'Bake for 12–15 minutes',
        'Serve hot',
      ],
    },
  };

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) Navigator.pushNamed(context, '/home');
    if (index == 1) Navigator.pushNamed(context, '/workout');
    if (index == 2) Navigator.pushNamed(context, '/progress');
    if (index == 4) Navigator.pushNamed(context, '/map');
  }

  void _openRecipe(String key) {
    final recipe = recipes[key];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipeName: key,
          imagePath: recipe!['image'],
          recipeData: recipe,
        ),
      ),
    );
  }

  void _showMenuDialog(BuildContext context, String day) async {
    final snap = await FirebaseFirestore.instance
        .collection(day.toLowerCase())
        .doc('menu')
        .get();

    if (!snap.exists) return;

    final data = snap.data()!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2438),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$day Menu', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🍳 Breakfast: ${data['breakfast']}',
                style: const TextStyle(color: Colors.orange)),
            const SizedBox(height: 6),
            Text('🍱 Lunch: ${data['lunch']}',
                style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 6),
            Text('🌙 Dinner: ${data['dinner']}',
                style: const TextStyle(color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            const Text('Close', style: TextStyle(color: Color(0xFFDBF352))),
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
        title: const Text('Nutrition'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Healthy Recipes',
                  style: TextStyle(color: Color(0xFFDBF352))),
              const SizedBox(height: 16),

              /// FIXED HEIGHT → NO OVERFLOW
              SizedBox(
                height: 230,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _recipeCard(
                      'images/salad.png',
                      'Proteins Salad',
                      'Eat greens daily',
                      '300 Kcal',
                          () => _openRecipe('Proteins Salad'),
                    ),
                    const SizedBox(width: 16),
                    _recipeCard(
                      'images/salmon.png',
                      'Baked Salmon',
                      'High protein meal',
                      '350 Kcal',
                          () => _openRecipe('Baked Salmon'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text('Nutrition Tips',
                  style: TextStyle(color: Color(0xFFDBF352))),
              const SizedBox(height: 16),

              ...[
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday'
              ].map(
                    (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _showMenuDialog(context, d),
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2438),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Image.asset('images/$d.png',
                              width: 80, height: 80, fit: BoxFit.cover),
                          const SizedBox(width: 16),
                          Text(d,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF1E1A32),
        selectedItemColor: const Color(0xFFDBF352),
        unselectedItemColor: const Color(0xFF896CFE),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fastfood), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }

  Widget _recipeCard(String img, String title, String sub, String kcal,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2438),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(img,
                  height: 110, width: 160, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 6),
                  Text(kcal,
                      style: const TextStyle(color: Color(0xFFDBF352))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
