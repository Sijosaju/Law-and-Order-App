import 'package:flutter/material.dart';
import 'package:law_app/services/auth_service.dart';
import 'package:law_app/services/google_sign_in_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'main_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainScreen()),
        (Route route) => false,
      );
    } else {
      // Handle email not verified error
      if (result['email_not_verified'] == true) {
        _showEmailNotVerifiedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showEmailNotVerifiedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Email Not Verified'),
        content: Text(
          'Please verify your email address before logging in. Check your inbox for the verification link.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resendVerification();
            },
            child: Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendVerification() async {
    final result = await _authService.resendVerification(_emailController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _saveGoogleUserSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', userData['uid'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_name', userData['name'] ?? '');
      await prefs.setBool('user_email_verified', userData['email_verified'] ?? false);
      await prefs.setBool('is_logged_in', true);
      print('Google user session saved successfully');
    } catch (e) {
      print('Error saving Google user session: $e');
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    try {
      final UserCredential? credential = await GoogleSignInService.signInWithGoogle();
      
      if (credential != null && credential.user != null) {
        // Get the Firebase ID token
        final String? idToken = await credential.user!.getIdToken();
        
        if (idToken != null) {
          // Send token to your backend for verification
          final response = await http.post(
            Uri.parse('${AuthService.baseUrl}/auth/verify-token'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'idToken': idToken}),
          );
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['success']) {
              // Save user session
              await _saveGoogleUserSession({
                'uid': data['uid'],
                'email': credential.user!.email ?? '',
                'name': credential.user!.displayName ?? '',
                'email_verified': true,
              });
              
              // Navigate to main screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => MainScreen()),
                (route) => false,
              );
            } else {
              _showError('Authentication failed: ${data['message']}');
            }
          } else {
            _showError('Server error. Please try again.');
          }
        } else {
          _showError('Failed to get authentication token');
        }
      } else {
        _showError('Google sign-in was cancelled');
      }
    } catch (e) {
      _showError('Google Sign-In failed: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF1A1D3A),
              Color(0xFF0A0E27),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 32),
                  Hero(
                    tag: 'logo',
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00D4FF).withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Icon(Icons.balance, size: 50, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Login to your LexAid account',
                    style: TextStyle(color: Colors.white60, fontSize: 16),
                  ),
                  SizedBox(height: 40),
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white60),
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.white60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Color(0xFF00D4FF)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter email';
                      if (!_authService.isValidEmail(v)) return 'Enter valid email';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white60),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.white60),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white60,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.white30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Color(0xFF00D4FF)),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                  ),
                  SizedBox(height: 8),
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ForgotPasswordScreen()),
                      ),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Color(0xFF00D4FF)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: Color(0xFF00D4FF),
                        disabledBackgroundColor: Color(0xFF00D4FF).withOpacity(0.6),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16),
                  // OR Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white30)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white30)),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Google Sign-In Button
              SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: Image.asset(
      'assets/google_logo.png',        // path must match pubspec.yaml
      height: 24, width: 24,           // keep it square and small
      fit: BoxFit.contain,
    ),
    label: const Text(
      'Sign in with Google',
      style: TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      disabledBackgroundColor: Colors.white54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      elevation: 0,
    ),
    onPressed: _isLoading ? null : _handleGoogleSignIn,
  ),
)
,
                  SizedBox(height: 24),
                  // Signup Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white60),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SignUpScreen()),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF00D4FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



