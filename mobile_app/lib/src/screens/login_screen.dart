import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/api_service.dart';
import 'register_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToMain(Map<String, dynamic> result) {
    final userId = result['id'] as String? ?? result['_id'] as String?;
    final token = result['token'] as String?;
    if (userId == null || token == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(userId: userId, token: token),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // Demo login - bypass Firebase for testing
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      // Check for demo credentials
      if (email == 'demo@dealfinder.com' && password == 'demo123') {
        // Use demo credentials
        final demoResult = {
          'id': 'demo-user-123',
          'token': 'demo-token-xyz',
          'name': 'Demo User',
          'email': 'demo@dealfinder.com',
          'role': 'user',
        };
        await AuthService.saveSession(demoResult);
        if (mounted) _navigateToMain(demoResult);
        return;
      }
      
      // Check for demo merchant credentials
      if (email == 'merchant@dealfinder.com' && password == 'merchant123') {
        // Use demo merchant credentials
        final demoMerchantResult = {
          'id': 'demo-merchant-user-123',
          '_id': 'demo-merchant-user-123',
          'token': 'demo-merchant-token-xyz',
          'name': 'Demo Merchant',
          'email': 'merchant@dealfinder.com',
          'role': 'merchant',
          'businessName': 'Demo Store',
          'merchantId': 'demo-merchant-123',
        };
        await AuthService.saveSession(demoMerchantResult);
        if (mounted) _navigateToMain(demoMerchantResult);
        return;
      }
      
      // Try normal Firebase login first
      try {
        final result = await AuthService.loginWithEmail(email, password);
        if (mounted) _navigateToMain(result);
      } catch (firebaseError) {
        // Firebase failed - fallback to direct backend login
        if (mounted) {
          setState(() {
            _errorMessage = 'Trying direct backend login...';
          });
        }
        try {
          final directLoginResult = await ApiService().directLogin(
            email: email,
            password: password,
          );
          await AuthService.saveSession(directLoginResult);
          if (mounted) _navigateToMain(directLoginResult);
        } catch (directLoginError) {
          // Both methods failed
          if (mounted) {
            setState(() {
              _errorMessage = _friendlyError(directLoginError.toString());
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _friendlyError(e.toString());
        });
      }
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _googleSignIn() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final result = await GoogleAuthService.signInWithGoogle();
      if (result != null && mounted) _navigateToMain(result);
    } catch (e) {
      if (mounted) setState(() { _errorMessage = _friendlyError(e.toString()); });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() { _errorMessage = 'Enter your email above, then tap Forgot Password.'; });
      return;
    }
    try {
      await AuthService.sendPasswordReset(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent. Check your inbox.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _errorMessage = _friendlyError(e.toString()); });
    }
  }

  String _friendlyError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '');
    if (msg.contains('user-not-found') || msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    if (msg.contains('network-request-failed')) return 'No internet connection.';
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text('Welcome Back!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Login to continue your deal hunting.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
              const SizedBox(height: 40),

              // Demo credentials info box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Demo Login',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'User: demo@dealfinder.com / demo123',
                      style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                    ),
                    Text(
                      'Merchant: merchant@dealfinder.com / merchant123',
                      style: TextStyle(fontSize: 13, color: Colors.blue[900]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[\w.+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() { _obscurePassword = !_obscurePassword; }),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your password';
                  return null;
                },
              ),
              const SizedBox(height: 4),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _forgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 8),

              // Error message (above login button)
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Login Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 20),

              // OR divider
              Row(children: [
                Expanded(child: Divider(color: Colors.grey[400])),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey[600])),
                ),
                Expanded(child: Divider(color: Colors.grey[400])),
              ]),
              const SizedBox(height: 20),

              // Google Sign-In
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onPressed: _isLoading ? null : _googleSignIn,
                icon: Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  height: 20, width: 20,
                ),
                label: const Text('Continue with Google', style: TextStyle(color: Colors.black87)),
              ),
              const SizedBox(height: 20),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text('Register here'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
