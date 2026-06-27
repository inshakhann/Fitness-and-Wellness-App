import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _gender;
  String? _fitnessLevel;
  bool _isLoading = false;
  bool _showAdditionalFields = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _emailVerified = false; // Track if email is verified
  bool _showVerificationMessage = false; // Show verification success message

  final List<String> _genders = ['Female', 'Male', 'Other'];
  final List<String> _fitnessLevels = ['Beginner', 'Intermediate', 'Advanced'];

  // Email validation regex
  final RegExp _emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
  );

  // Function to validate email format
  bool _isValidEmail(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  Future<void> _signUp() async {
    // Clear previous messages
    setState(() {
      _showVerificationMessage = false;
    });

    // Validation
    if (_usernameController.text.isEmpty) {
      _showError('Please enter a username');
      return;
    }

    if (_emailController.text.isEmpty) {
      _showError('Please enter an email');
      return;
    }

    // Validate email format
    if (!_isValidEmail(_emailController.text)) {
      _showError('Please enter a valid email address (e.g., name@example.com)');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError('Please enter a password');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user in Firebase Auth
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Update user display name
      await userCredential.user!.updateDisplayName(_usernameController.text.trim());

      // Store user data in Firestore (but mark as unverified)
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'userId': userCredential.user!.uid,
        'name': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _gender ?? 'Female',
        'age': int.tryParse(_ageController.text) ?? 25,
        'weight': double.tryParse(_weightController.text) ?? 55.0,
        'height': double.tryParse(_heightController.text) ?? 165.0,
        'fitnessLevel': _fitnessLevel ?? 'Beginner',
        'createdAt': FieldValue.serverTimestamp(),
        'totalWorkouts': 0,
        'totalMinutes': 0,
        'lastLogin': FieldValue.serverTimestamp(),
        'emailVerified': false, // Track verification status
        'accountStatus': 'pending_verification', // Account status
      });

      // Show verification success message
      setState(() {
        _showVerificationMessage = true;
      });

      // Show verification dialog
      _showVerificationDialog(userCredential.user!);

    } on FirebaseAuthException catch (e) {
      String errorMessage = "Sign Up Failed";
      if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak. Use at least 6 characters with mix of letters and numbers.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered. Please sign in instead.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address format. Please check and try again.';
      } else if (e.code == 'operation-not-allowed') {
        errorMessage = 'Email/password accounts are not enabled. Please contact support.';
      }
      _showError(errorMessage);
    } catch (e) {
      _showError("Registration failed. Please try again.");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show verification dialog
  void _showVerificationDialog(User user) {
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
            Icon(Icons.verified_user, color: Colors.pinkAccent),
            SizedBox(width: 10),
            Text(
              'Verify Your Email',
              style: TextStyle(
                color: Colors.pinkAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We\'ve sent a verification email to:',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                _emailController.text.trim(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Please check your inbox and click the verification link to activate your account.',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 8),
              Text(
                'You\'ll need to verify your email before you can access all features.',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Button to check verification
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _checkEmailVerification();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
            ),
            child: Text('I\'ve Verified My Email'),
          ),
          // Button to resend verification
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resendVerificationEmail();
            },
            child: Text(
              'Resend Email',
              style: TextStyle(color: Colors.pinkAccent),
            ),
          ),
        ],
      ),
    );
  }

  // Check if email is verified
  Future<void> _checkEmailVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Reload user to get latest verification status
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        // Update Firestore with verified status
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
          'accountStatus': 'active',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Email verified successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to home screen after verification
        Future.delayed(Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(context, '/home');
        });
      } else {
        _showError('Email not verified yet. Please check your inbox.');
      }
    } catch (e) {
      _showError('Error checking verification status');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Resend verification email
  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("📧 Verification email sent again!"),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to resend verification email');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1A32),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),

              // App Logo/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pinkAccent, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 40,
                ),
              ),

              SizedBox(height: 20),

              // Title
              Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              // Subtitle
              Text(
                "Join our fitness community and start your journey",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              // Show verification success message
              if (_showVerificationMessage)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Verification email sent! Please check your inbox.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 20),

              // Form Container
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFF2A2438),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Username
                    _buildTextField(
                      controller: _usernameController,
                      label: "Username",
                      icon: Icons.person_outline,
                      hint: "Enter your username",
                    ),

                    SizedBox(height: 15),

                    // Email with validation
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
                        ),
                        labelText: "Email",
                        labelStyle: TextStyle(color: Colors.black54),
                        hintText: "example@email.com",
                        hintStyle: TextStyle(color: Colors.black38),
                        prefixIcon: Icon(Icons.email_outlined, color: Colors.black54),
                        suffixIcon: _emailController.text.isNotEmpty && _isValidEmail(_emailController.text)
                            ? Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                      ),
                    ),

                    SizedBox(height: 15),

                    // Password
                    _buildPasswordField(
                      controller: _passwordController,
                      label: "Password",
                      obscure: _obscurePassword,
                      onToggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),

                    SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.white54),
                          SizedBox(width: 5),
                          Text(
                            "Must be at least 6 characters",
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 15),

                    // Confirm Password
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      obscure: _obscureConfirmPassword,
                      onToggle: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),

                    SizedBox(height: 20),

                    // Show Additional Fields Button
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showAdditionalFields = !_showAdditionalFields;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.pinkAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showAdditionalFields ? Icons.expand_less : Icons.expand_more,
                            color: Colors.pinkAccent,
                          ),
                          SizedBox(width: 10),
                          Text(
                            _showAdditionalFields ? "Hide Details" : "Add Personal Details",
                            style: TextStyle(color: Colors.pinkAccent),
                          ),
                        ],
                      ),
                    ),

                    // Additional Fields
                    if (_showAdditionalFields) ...[
                      SizedBox(height: 20),

                      // Gender Dropdown
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _gender,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: "Gender",
                            labelStyle: TextStyle(color: Colors.black54),
                            prefixIcon: Icon(Icons.person, color: Colors.black54),
                          ),
                          items: _genders.map((String gender) {
                            return DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _gender = newValue;
                            });
                          },
                          hint: Text("Select Gender"),
                        ),
                      ),

                      SizedBox(height: 15),

                      // Age
                      _buildTextField(
                        controller: _ageController,
                        label: "Age",
                        icon: Icons.cake_outlined,
                        hint: "Enter your age",
                        keyboardType: TextInputType.number,
                      ),

                      SizedBox(height: 15),

                      // Weight
                      _buildTextField(
                        controller: _weightController,
                        label: "Weight (kg)",
                        icon: Icons.monitor_weight_outlined,
                        hint: "Enter weight in kg",
                        keyboardType: TextInputType.number,
                      ),

                      SizedBox(height: 15),

                      // Height
                      _buildTextField(
                        controller: _heightController,
                        label: "Height (cm)",
                        icon: Icons.height_outlined,
                        hint: "Enter height in cm",
                        keyboardType: TextInputType.number,
                      ),

                      SizedBox(height: 15),

                      // Fitness Level Dropdown
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _fitnessLevel,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: "Fitness Level",
                            labelStyle: TextStyle(color: Colors.black54),
                            prefixIcon: Icon(Icons.fitness_center, color: Colors.black54),
                          ),
                          items: _fitnessLevels.map((String level) {
                            return DropdownMenuItem<String>(
                              value: level,
                              child: Text(level),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _fitnessLevel = newValue;
                            });
                          },
                          hint: Text("Select Fitness Level"),
                        ),
                      ),
                    ],

                    SizedBox(height: 30),

                    // Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
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
                            : Text(
                          "CREATE ACCOUNT",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signin');
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Terms and Privacy
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "By signing up, you agree to our Terms of Service and Privacy Policy",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
        ),
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black38),
        prefixIcon: Icon(icon, color: Colors.black54),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
        ),
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54),
        hintText: "Enter your password",
        hintStyle: TextStyle(color: Colors.black38),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.black54),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.black54,
          ),
          onPressed: onToggle,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }
}