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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
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
                      decoration: const InputDecoration(labelText: "Email"),
                      keyboardType: TextInputType.emailAddress,
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
                      onPressed: () {
                        String email = emailController.text;
                        String password = passwordController.text;
                        print("Email: $email, Password: $password");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                      },
                      child: const Text("Login"),
                    ),
                    const SizedBox(height: 8),
                    // Forgot password link
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

}
