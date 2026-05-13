import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_colors.dart';
import 'main_navigation.dart';
import 'widgets/trailmate_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool isLogin = true;
  bool isLoading = false;

  Future<void> _submitAuth() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw Exception("Passwords do not match!");
        }
        await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const TrailMateLogo(size: 80),
              const SizedBox(height: 40),
              _buildTextField("Email", Icons.email_outlined, _emailController),
              const SizedBox(height: 16),
              _buildTextField("Password", Icons.lock_outline, _passwordController, obscure: true),
              if (!isLogin) ...[
                const SizedBox(height: 16),
                _buildTextField("Confirm Password", Icons.lock_outline, _confirmPasswordController, obscure: true),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isLoading ? null : _submitAuth,
                  child: isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : Text(isLogin ? "LOGIN" : "SIGN UP", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(
                  isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                  style: const TextStyle(color: AppColors.primary),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }
}