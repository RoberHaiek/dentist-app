import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'patient/PatientHomePage.dart';
import 'clinic/ClinicHomePage.dart';
import 'ForgotPage.dart';
import 'RegistrationPage.dart';
import '../services/LocalizationProvider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  static const bool isDebug = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();

  bool isButtonEnabled = false;
  bool emailValid = true;
  bool isLoading = false;
  bool isSocialLoading = false;
  bool rememberMe = true;
  bool _passwordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    emailController.addListener(_validateForm);
    passwordController.addListener(_validateForm);

    emailFocus.addListener(() {
      if (!emailFocus.hasFocus) {
        _validateEmail();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoLogin();
    });
  }

  Future<void> _checkAutoLogin() async {
    try {
      if (isDebug) {
        debugPrint('Debug mode enabled - skipping login');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PatientHomePage()),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        final shouldRemember = prefs.getBool('rememberMe') ?? false;

        if (shouldRemember) {
          debugPrint('Remember me enabled - auto-logging in');
          await _navigateToCorrectHome(user.uid);
        } else {
          await FirebaseAuth.instance.signOut();
          debugPrint('User logged out - remember me was not enabled');
        }
      }
    } catch (e) {
      debugPrint('initState: Firebase check currentUser failed: $e');
    }
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

  Future<void> _navigateToCorrectHome(String uid) async {
    try {
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(uid)
          .get();

      if (clinicDoc.exists) {
        debugPrint('User is a clinic, navigating to ClinicHomePage');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ClinicHomePage()),
          );
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        debugPrint('User is a patient, navigating to HomePage');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const PatientHomePage()),
          );
        }
        return;
      }

      debugPrint(
          'Warning: User authenticated but not found in clinics or users collection');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('account_setup_incomplete')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to home: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Creates a minimal Firestore user document for social sign-in users
  /// who don't have one yet (first-time social login).
  Future<void> _ensureUserDocument(User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      debugPrint('First social login - creating user document');
      final nameParts = (user.displayName ?? '').split(' ');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'firstName': nameParts.isNotEmpty ? nameParts.first : '',
        'lastName': nameParts.length > 1 ? nameParts.last : '',
        'email': user.email ?? '',
        'dateOfBirth': '',
        'address': '',
        'phoneNumber': '',
        'photoUrl': user.photoURL ?? '',
        'createdVia': 'google',
      });
    }
  }

  // ──────────────────────────────────────────────
  // EMAIL / PASSWORD LOGIN
  // ──────────────────────────────────────────────

  Future<void> _login() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Block login if email not verified
      if (!cred.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('email_not_verified_yet')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', rememberMe);

      if (!mounted) return;
      await _navigateToCorrectHome(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      debugPrint('login: FirebaseAuthException ${e.code} ${e.message}');
      final message = (e.code == 'user-not-found')
          ? context.tr('user_not_found')
          : (e.code == 'wrong-password')
          ? context.tr('wrong_password')
          : (e.message ?? context.tr('login_failed'));

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('${context.tr('error')}: $e'),
                backgroundColor: Colors.red),
          );
        });
      }
    } finally {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => isLoading = false);
      });
    }
  }

  // ──────────────────────────────────────────────
  // GOOGLE SIGN-IN
  // ──────────────────────────────────────────────

  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() => isSocialLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => isSocialLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', true);

      await _ensureUserDocument(userCred.user!);

      if (!mounted) return;
      await _navigateToCorrectHome(userCred.user!.uid);
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in FirebaseAuthException: ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message ?? context.tr('login_failed')),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${context.tr('error')}: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSocialLoading = false);
    }
  }

  // ──────────────────────────────────────────────
  // FACEBOOK SIGN-IN
  // ──────────────────────────────────────────────

  Future<void> _signInWithFacebook() async {
    if (!mounted) return;
    setState(() => isSocialLoading = true);

    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        debugPrint('Facebook login cancelled or failed: ${result.status}');
        setState(() => isSocialLoading = false);
        return;
      }

      final OAuthCredential credential =
      FacebookAuthProvider.credential(result.accessToken!.tokenString);

      final userCred =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', true);

      // Create Firestore document if first-time Facebook login
      await _ensureUserDocument(userCred.user!);

      if (!mounted) return;
      await _navigateToCorrectHome(userCred.user!.uid);
    } on FirebaseAuthException catch (e) {
      debugPrint('Facebook sign-in FirebaseAuthException: ${e.code}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message ?? context.tr('login_failed')),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Facebook sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${context.tr('error')}: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSocialLoading = false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF7DD3C0).withOpacity(0.1),
              const Color(0xFFF2EBE2),
              const Color(0xFF7DD3C0).withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.tr('app_name'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      context.tr('your_smile_matters'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF666666),
                      ),
                    ),

                    const SizedBox(height: 40),

                    _buildTextField(
                      controller: emailController,
                      focusNode: emailFocus,
                      label: context.tr('email'),
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    if (!emailValid)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            context.tr('invalid_email'),
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

                    _buildTextField(
                      controller: passwordController,
                      label: context.tr('password'),
                      icon: Icons.lock,
                      obscureText: !_passwordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF999999),
                          size: 20,
                        ),
                        onPressed: () {
                          setState(
                                  () => _passwordVisible = !_passwordVisible);
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: rememberMe,
                            onChanged: (value) {
                              setState(() {
                                rememberMe = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF7DD3C0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('remember_me'),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ForgotPage()),
                            );
                          },
                          child: Text(
                            context.tr('forgot_password'),
                            style: const TextStyle(
                              color: Color(0xFF7DD3C0),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Email/Password Login Button ──
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(27),
                        gradient: isButtonEnabled
                            ? const LinearGradient(
                          colors: [
                            Color(0xFF7DD3C0),
                            Color(0xFF5AB9A8)
                          ],
                        )
                            : null,
                        color: isButtonEnabled
                            ? null
                            : const Color(0xFFCCCCCC),
                        boxShadow: isButtonEnabled
                            ? [
                          BoxShadow(
                            color: const Color(0xFF7DD3C0)
                                .withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                            : null,
                      ),
                      child: ElevatedButton(
                        onPressed:
                        isButtonEnabled && !isLoading ? _login : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          context.tr('login'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Divider ──
                    Row(
                      children: [
                        const Expanded(
                            child: Divider(color: Color(0xFFCCCCCC))),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            context.tr('or_continue_with'),
                            style: const TextStyle(
                                color: Color(0xFF999999), fontSize: 12),
                          ),
                        ),
                        const Expanded(
                            child: Divider(color: Color(0xFFCCCCCC))),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Social Buttons ──
                    isSocialLoading
                        ? const SizedBox(
                      height: 54,
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF7DD3C0)),
                      ),
                    )
                        : Row(
                      children: [
                        // Google
                        Expanded(
                          child: _buildSocialButton(
                            label: 'Google',
                            icon: _googleIcon(),
                            onTap: _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Facebook
                        Expanded(
                          child: _buildSocialButton(
                            label: 'Facebook',
                            icon: const Icon(Icons.facebook,
                                color: Color(0xFF1877F2), size: 22),
                            onTap: _signInWithFacebook,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Register ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const RegistrationPage()),
                            );
                          },
                          child: Text(
                            context.tr('register'),
                            style: const TextStyle(
                              color: Color(0xFF7DD3C0),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Draws the Google 'G' logo using a simple colored text fallback.
  /// Replace with an SVG asset if you have one.
  Widget _googleIcon() {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4285F4),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF333333),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF7DD3C0), size: 20),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFF7DD3C0), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}