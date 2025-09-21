import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'HomePage.dart';
import '../Images.dart';
import 'ForgotPage.dart';
import 'RegistrationPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();

  bool isButtonEnabled = false;
  bool emailValid = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);

    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        _validateEmail();
      }
    });

    // Auto-login if already signed in (safe, after initialization)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // Already signed in -> go to HomePage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        debugPrint('initState: Firebase check currentUser failed: $e');
      }
    });
  }

  void _validateForm() {
    final emailText = emailController.text;
    final passwordText = passwordController.text;
    final isValidEmail = _isValidEmail(emailText);

    if (mounted) {
      setState(() {
        isButtonEnabled =
            emailText.isNotEmpty && passwordText.isNotEmpty && isValidEmail;
      });
    }
  }

  void _validateEmail() {
    if (mounted) {
      setState(() {
        emailValid = _isValidEmail(emailController.text);
      });
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex =
    RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _login() async {
    // Defensive: ensure UI shows loading immediately on platform thread
    if (!mounted) return;
    setState(() => isLoading = true);
    FocusScope.of(context).unfocus();

    debugPrint('login: start for email=${emailController.text.trim()}');

    try {
      // Attempt sign in
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      debugPrint('login: success uid=${cred.user?.uid}');

      // All UI changes must be scheduled on the main frame to avoid platform-thread warnings
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      });
    } on FirebaseAuthException catch (e, st) {
      debugPrint('login: FirebaseAuthException ${e.code} ${e.message}\n$st');

      final message = (e.code == 'user-not-found')
          ? 'No user found for that email.'
          : (e.code == 'wrong-password')
          ? 'Wrong password provided.'
          : (e.message ?? 'Login failed');

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        });
      }
    } catch (e, st) {
      debugPrint('login: unexpected error $e\n$st');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unexpected error: $e')),
          );
        });
      }
    } finally {
      // Ensure setState runs on UI frame
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => isLoading = false);
      });
    }
  }

  @override
  void dispose() {
    // _authSub?.cancel();
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen wallpaper
          SizedBox.expand(
            child: Images.getWallpaper("images/login_wallpaper.png"),
          ),

          // Login form
          Align(
            alignment: const Alignment(0, -0.6), // negative Y lifts it up
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3), // semi-transparent
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Logo
                    Images.getImage("images/tooth_icon.png", 120.0, 120.0),
                    const Text(
                      "Log in to Asnani",
                      style: TextStyle(color: Colors.white, fontSize: 26.0),
                    ),
                    const SizedBox(height: 8),
                    // Email field
                    TextField(
                      controller: emailController,
                      focusNode: emailFocus,
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    // Email validation message
                    if (!emailValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Email is invalid",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Password field
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                    ),
                    const SizedBox(height: 24),
                    // Login button
                    ElevatedButton(
                      onPressed: isButtonEnabled && !isLoading ? _login : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonEnabled ? Colors.blue : Colors.grey,
                      ),
                      child: isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text("Login"),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPage()),
                        );
                      },
                      child: const Text(
                        "Forgot password?",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Register link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegistrationPage()),
                        );
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         // Fullscreen wallpaper
  //         SizedBox.expand(
  //           child: Images.getWallpaper("images/login_wallpaper.png"),
  //         ),
  //
  //         // Login form
  //         Align(
  //           alignment: const Alignment(0, -0.6), // negative Y lifts it up
  //           child: SingleChildScrollView(
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  //               margin: const EdgeInsets.symmetric(horizontal: 20),
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.3), // semi-transparent
  //                 borderRadius: BorderRadius.circular(20),
  //               ),
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: <Widget>[
  //                   // Logo
  //                   Images.getImage("images/tooth_icon.png", 120.0, 120.0),
  //                   const Text(
  //                     "Log in to Asnani",
  //                     style: TextStyle(color: Colors.white, fontSize: 26.0),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   // Email field
  //                   TextField(
  //                     controller: emailController,
  //                     focusNode: emailFocus,
  //                     decoration: const InputDecoration(labelText: "Email"),
  //                     keyboardType: TextInputType.emailAddress,
  //                   ),
  //                   const SizedBox(height: 8),
  //                   // Password field
  //                   TextField(
  //                     controller: passwordController,
  //                     decoration: const InputDecoration(labelText: "Password"),
  //                     obscureText: true,
  //                   ),
  //                   const SizedBox(height: 24),
  //                   // Login button
  //                   ElevatedButton(
  //                     onPressed: () {
  //                       Navigator.pushReplacement(
  //                         context,
  //                         MaterialPageRoute(builder: (context) => const HomePage()),
  //                       );
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: isButtonEnabled ? Colors.blue : Colors.grey,
  //                     ),
  //                     child: isLoading
  //                         ? const SizedBox(
  //                       width: 20,
  //                       height: 20,
  //                       child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
  //                     )
  //                         : const Text("Login"),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   GestureDetector(
  //                     onTap: () {
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(builder: (context) => const ForgotPage()),
  //                       );
  //                     },
  //                     child: const Text(
  //                       "Forgot password?",
  //                       style: TextStyle(
  //                         color: Colors.blue,
  //                         decoration: TextDecoration.underline,
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   // Register link
  //                   GestureDetector(
  //                     onTap: () {
  //                       Navigator.push(
  //                         context,
  //                         MaterialPageRoute(builder: (context) => const RegistrationPage()),
  //                       );
  //                     },
  //                     child: const Text(
  //                       "Register",
  //                       style: TextStyle(
  //                         color: Colors.blue,
  //                         decoration: TextDecoration.underline,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
