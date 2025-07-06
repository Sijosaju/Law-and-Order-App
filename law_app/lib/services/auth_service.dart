import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://law-and-order-app.onrender.com';

  // Email validation helper
  bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  // Password strength validation
  Map<String, dynamic> validatePassword(String password) {
    if (password.length < 6) {
      return {'isValid': false, 'message': 'Password must be at least 6 characters'};
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return {'isValid': false, 'message': 'Password must contain at least one letter'};
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return {'isValid': false, 'message': 'Password must contain at least one number'};
    }
    return {'isValid': true, 'message': 'Password is strong'};
  }

  Future<Map<String, dynamic>> signUp(String name, String email, String password) async {
    try {
      // Client-side validation
      if (!isValidEmail(email)) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      final passwordCheck = validatePassword(password);
      if (!passwordCheck['isValid']) {
        return {'success': false, 'message': passwordCheck['message']};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 30));

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        // Don't save session yet - user needs to verify email first
        return {
          'success': true,
          'message': data['message'] ?? 'Account created! Please check your email for verification.',
          'uid': data['uid'],
          'email': data['email'],
          'name': data['name'],
          'requiresVerification': true
        };
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Signup failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      // Client-side validation
      if (!isValidEmail(email)) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(Duration(seconds: 30));

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        await _saveUserSession(data);
        return data;
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Login failed',
          'email_not_verified': data['email_not_verified'] ?? false
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      if (!isValidEmail(email)) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(Duration(seconds: 30));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    try {
      if (!isValidEmail(email)) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      ).timeout(Duration(seconds: 30));

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<void> _saveUserSession(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_token', userData['customToken'] ?? '');
    await prefs.setString('user_id', userData['uid'] ?? '');
    await prefs.setString('user_email', userData['email'] ?? '');
    await prefs.setString('user_name', userData['name'] ?? '');
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('email_verified', userData['email_verified'] ?? false);
  }

  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  Future<void> signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, String>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('user_name') ?? 'User',
      'email': prefs.getString('user_email') ?? '',
      'id': prefs.getString('user_id') ?? '',
    };
  }
}


