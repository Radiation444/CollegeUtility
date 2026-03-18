import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  // --- SIGN UP LOGIC ---
  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!email.endsWith('@iitj.ac.in')) {
      setState(() => _errorMessage = 'Access restricted: Please use your @iitj.ac.in email.');
      return; 
    }

    try {
      // 1. Create the Auth Account (Firebase auto-logs them in here)
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Send Verification Email
      await userCredential.user?.sendEmailVerification();

      // 3. FORCE SIGN OUT (The StreamBuilder in main.dart is blocking the flash while this runs)
      await FirebaseAuth.instance.signOut();

      // 4. Update UI with the exact requested message
      setState(() {
        _errorMessage = 'Check your email for verification.';
      });
      
      _passwordController.clear(); // Clear password for security

    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Sign up failed');
    }
  }

  // --- LOGIN LOGIC ---
  Future<void> _login() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 1. Check if they are actually verified
      if (!userCredential.user!.emailVerified) {
        await FirebaseAuth.instance.signOut(); // Kick them right back out
        setState(() => _errorMessage = 'Not verified yet.');
        return;
      }

      // 2. If verified, the StreamBuilder in main.dart automatically routes them!
      
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Login failed');
    }
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
      appBar: AppBar(
        title: const Text('Campus App Access'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'College Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _errorMessage.contains('Check your email') ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _login, child: const Text('Login')),
                OutlinedButton(onPressed: _signUp, child: const Text('Sign Up')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}