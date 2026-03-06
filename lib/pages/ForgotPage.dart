import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/LocalizationProvider.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final TextEditingController emailController = TextEditingController();
  bool isButtonEnabled = false;
  bool emailValid = true;
  bool isLoading = false;
  bool emailSent = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_validateEmailField);
  }

  void _validateEmailField() {
    final email = emailController.text;
    final isValid = _isValidEmail(email);
    setState(() {
      emailValid = isValid;
      isButtonEnabled = email.isNotEmpty && isValid;
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _sendResetEmail() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: emailController.text.trim());
      setState(() => emailSent = true);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.message}"),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Unexpected error: $e"),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      appBar: AppBar(
        title: Text(
          context.tr('forgot_password'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)]),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Icon header
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA8E6CF), Color(0xFF7DD3C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(45),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7DD3C0).withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_reset, color: Colors.white, size: 44),
              ),
            ),
            const SizedBox(height: 28),

            // Title & subtitle
            Center(
              child: Text(
                context.tr('forgot_password'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                context.tr('forgot_password_subtitle'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF999999), height: 1.5),
              ),
            ),
            const SizedBox(height: 36),

            if (!emailSent) ...[
              // Email field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                  decoration: InputDecoration(
                    labelText: context.tr('email'),
                    labelStyle: const TextStyle(color: Color(0xFF999999)),
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF7DD3C0)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF7DD3C0), width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              // Validation error
              if (!emailValid && emailController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        context.tr('email_invalid'),
                        style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),

              // Send button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isButtonEnabled && !isLoading ? _sendResetEmail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DD3C0),
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                      : Text(
                    context.tr('reset_link'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else ...[
              // Success state
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7DD3C0).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_outlined, color: Color(0xFF7DD3C0), size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('check_email'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      emailController.text.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF7DD3C0)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Back to login button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7DD3C0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    context.tr('back_to_login'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Back to login link (only shown before sending)
            if (!emailSent)
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.tr('back_to_login'),
                    style: const TextStyle(color: Color(0xFF7DD3C0), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}