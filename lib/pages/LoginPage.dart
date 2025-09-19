import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    // Listen to email and password changes
    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);

    // Listen to focus changes to validate email
    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        _validateEmail();
      }
    });
  }

  void _validateForm() {
    final emailText = emailController.text;
    final passwordText = passwordController.text;
    final isValidEmail = _isValidEmail(emailText);

    setState(() {
      isButtonEnabled = emailText.isNotEmpty &&
          passwordText.isNotEmpty &&
          isValidEmail;
    });
  }

  void _validateEmail() {
    setState(() {
      emailValid = _isValidEmail(emailController.text);
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex =
    RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  @override
  void dispose() {
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
                      onPressed: isButtonEnabled
                          ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HomePage()),
                        );
                      }
                          : null, // disables the button if false
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isButtonEnabled
                            ? Colors.blue
                            : Colors.grey, // gray if disabled
                      ),
                      child: const Text("Login"),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ForgotPage()),
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
                          MaterialPageRoute(
                              builder: (context) => const RegistrationPage()),
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
}
