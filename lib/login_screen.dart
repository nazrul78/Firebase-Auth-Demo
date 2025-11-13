import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  bool _isPhoneAuth = false;
  String _countryCode = "+91";

  void toggleAuthMode() {
    setState(() => _isPhoneAuth = !_isPhoneAuth);
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, "/home");
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithPhone() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid phone number")));
      return;
    }

    setState(() => _isLoading = true);

    final phone = '$_countryCode${_phoneController.text.trim()}';
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
        setState(() => _isLoading = false);
      },
      codeSent: (String verificationId, int? resendToken) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("OTP sent to $phone")));
        setState(() => _isLoading = false);
        Navigator.pushNamed(
          context,
          '/otp',
          arguments: {'verificationId': verificationId},
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        setState(() => _isLoading = false);
      },
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final userDoc = await userRef.get();

        if (!userDoc.exists) {
          await userRef.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
          });
        }

        return userCredential;
      }
      return null;
    } catch (e) {
      print("Google Sign-In Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong. Try again.")),
      );
      return null;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isPhoneAuth ? "Use Email" : "Use Phone"),
                    Switch(
                      value: _isPhoneAuth,
                      onChanged: (_) => toggleAuthMode(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_isPhoneAuth)
                  Column(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixText: "$_countryCode ",
                          prefixIcon: const Icon(Icons.phone_android),
                          labelText: "Phone Number",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value != null && value.contains('@')
                            ? null
                            : 'Enter valid email',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) => value != null && value.length >= 6
                            ? null
                            : 'Min 6 characters',
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/forgot'),
                          child: const Text("Forgot password?"),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _isPhoneAuth
                              ? _signInWithPhone()
                              : _signInWithEmail(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(_isPhoneAuth ? "Send OTP" : "Log In"),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Or"),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: SignInButton(
                    Buttons.Google,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onPressed: () async {
                      setState(() => _isLoading = true);

                      final user = await signInWithGoogle();

                      if (mounted) setState(() => _isLoading = false);

                      if (user != null) {
                        Navigator.pushReplacementNamed(context, "/home");
                      } else {
                        // Optional: show error
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Google sign-in failed")),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don’t have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: const Text(
                        "Sign up",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
