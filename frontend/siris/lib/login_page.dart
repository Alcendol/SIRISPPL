import 'dart:convert'; // Untuk decoding JSON
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final loggerLogin = Logger('_LoginScreenState');

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();
final FocusNode _focusNode = FocusNode();
String? errorMessage;

Future<void> _login() async {
  const url = 'http://localhost:8080/login';

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
        'email': _emailController.text,
        'password': _passwordController.text,
  }),
);

  if (response.statusCode == 200) {
    // Jika berhasil login
    final data = json.decode(response.body);
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('email', _emailController.text);
    prefs.setString('role', data['role']);
    prefs.setString('currentLoginAs', data['role']);


    // Pengecekan role
    if(mounted){
      data['currentLoginAs'] = data['role'];
        Navigator.pushNamed(context, '/dashboard', arguments: data);
    }
  
  } else {
    // Jika gagal login, tampilkan pesan error
    setState(() {
      errorMessage = json.decode(response.body)['message'] ?? 'Login gagal';
    });
  }
}

  void _handleKeyPress(KeyEvent event) {
    if (event.runtimeType == KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter) {
      _login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyPress,
        child: Stack (
        children: [
          // Background image with cover effect
          Container(
            decoration: const BoxDecoration(
                image: DecorationImage(
                image: AssetImage('images/Gedung-WP.jpg'),
                fit: BoxFit.cover,
                ),
            ),
          ),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          // Login form
          Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        Text(
                          'SIRIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'SISTEM INFORMASI RENCANA ISIAN STUDI',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Login Card
                  Container(
                    width: 400,
                    height: 500,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.login, color: Colors.indigo, size: 30),
                                SizedBox(width: 10),
                                Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (errorMessage != null)
                              Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // Password reset logic here
                                },
                                child: const Text(
                                  'Lupa Password?',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _login,
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
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
    );
  }
}
