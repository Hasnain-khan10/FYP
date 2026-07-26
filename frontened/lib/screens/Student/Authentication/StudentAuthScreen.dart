import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:frontened/screens/Student/Main_Screen.dart';
import 'package:frontened/services/storage_service.dart';
import 'package:frontened/utils/Auth_Widgets/AppLogo.dart';
import 'package:frontened/utils/Auth_Widgets/AuthScaffold.dart';
import 'package:frontened/utils/Auth_Widgets/AuthTextField.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class StudentAuthScreen extends StatefulWidget {
  static const String routeName = '/student-auth';
  const StudentAuthScreen({super.key});

  @override
  State<StudentAuthScreen> createState() => _StudentAuthScreenState();
}

class _StudentAuthScreenState extends State<StudentAuthScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Common Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Signup Controllers
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _cnicController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? selectedSemester;
  String? selectedSection;
  final List<String> semesters = List.generate(8, (index) => "Semester ${index + 1}");
  final List<String> sections = ["A", "B", "C", "D"];

  // 🔥 FIX: Clean GoogleSignIn instance without problematic serverClientId
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _fatherNameController.dispose();
    _rollNumberController.dispose();
    _departmentController.dispose();
    _cnicController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _navigate() {
    Navigator.pushNamedAndRemoveUntil(context, MainScreen.routeName, (route) => false);
  }

  // ================= MAIN AUTHENTICATION =================
  Future<void> _handleAuth(AuthProvider authProvider) async {
    final role = await StorageService.getRole();
    if (role != "student") return _showError("Invalid role selected");

    setState(() => _isLoading = true);

    if (_isLogin) {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() => _isLoading = false);
        return _showError("Please enter email and password");
      }
      bool success = await authProvider.login(_emailController.text.trim(), _passwordController.text.trim(), role!);
      if (!success) {
        _showError(authProvider.error ?? "Login failed");
      } else {
        _navigate();
      }
    } else {
      if ([_nameController.text, _fatherNameController.text, _emailController.text, _rollNumberController.text, _departmentController.text, _cnicController.text, _passwordController.text].any((e) => e.isEmpty) || selectedSemester == null || selectedSection == null) {
        setState(() => _isLoading = false);
        return _showError("Please fill all fields");
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() => _isLoading = false);
        return _showError("Passwords do not match");
      }

      bool success = await authProvider.signup(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: role!,
        fatherName: _fatherNameController.text.trim(),
        cnic: _cnicController.text.trim(),
        department: _departmentController.text.trim(),
        rollNumber: _rollNumberController.text.trim(),
        semester: selectedSemester,
        section: selectedSection,
      );

      if (!success) {
        _showError(authProvider.error ?? "Signup failed");
      } else {
        _navigate();
      }
    }
    setState(() => _isLoading = false);
  }

  // ================= GOOGLE AUTH =================
  // 🔥 FIX: Updated Google Auth Handler with Email & Name passing
  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    try {
      setState(() => _isLoading = true);
      final role = await StorageService.getRole();
      if (role != "student") { setState(() => _isLoading = false); return _showError("Invalid role"); }

      try { await _googleSignIn.signOut(); } catch (e) {}

      final account = await _googleSignIn.signIn();
      if (account == null) { setState(() => _isLoading = false); return; }

      final auth = await account.authentication;

      bool success = await authProvider.googleLogin(
        auth.idToken ?? "google_token",
        role!,
        email: account.email,
        name: account.displayName ?? "",
      );

      if (!success) {
        _showError(authProvider.error ?? "Google login failed");
      } else {
        _navigate();
      }
    } catch (e) {
      _showError("Google Sign-In Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= FORGOT PASSWORD =================
  void _showForgotPasswordSheet() {
    final emailCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    int step = 1;
    bool isPassVisible = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Consumer<AuthProvider>(
          builder: (context, authProvider, child) => Container(
            padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text(step == 1 ? "Forgot Password" : step == 2 ? "Verify OTP" : "Reset Password", textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),

                  if (step == 1) AuthTextField(hintText: "Email Address", icon: Icons.email_outlined, controller: emailCtrl),
                  if (step == 2) AuthTextField(hintText: "Enter 6-Digit OTP", icon: Icons.pin_outlined, controller: otpCtrl),
                  if (step == 3) AuthTextField(hintText: "New Password", icon: Icons.lock_outline, controller: newPassCtrl, isPassword: true, obscureText: !isPassVisible, onToggle: () => setModalState(() => isPassVisible = !isPassVisible)),

                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: authProvider.isLoading ? null : () async {
                        if (step == 1) {
                          if (await authProvider.forgotPassword(emailCtrl.text.trim())) setModalState(() => step = 2);
                        } else if (step == 2) {
                          if (await authProvider.verifyOTP(emailCtrl.text.trim(), otpCtrl.text.trim())) setModalState(() => step = 3);
                        } else {
                          if (await authProvider.resetPassword(email: emailCtrl.text.trim(), newPassword: newPassCtrl.text.trim())) Navigator.pop(context);
                        }
                        if (!authProvider.isLoading && authProvider.error != null) _showError(authProvider.error!);
                      },
                      child: authProvider.isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                          : Text(step == 1 ? "Send OTP" : step == 2 ? "Verify OTP" : "Reset Password", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const AppLogo(width: 150),
              const SizedBox(height: 10),
              Text(
                _isLogin ? 'Student Login' : 'Student Registration',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
              ),
              const SizedBox(height: 24),

              if (!_isLogin) ...[
                AuthTextField(hintText: 'Full Name', icon: Icons.person_outline, controller: _nameController),
                const SizedBox(height: 12),
                AuthTextField(hintText: "Father's Name", icon: Icons.family_restroom, controller: _fatherNameController),
                const SizedBox(height: 12),
                AuthTextField(hintText: 'Roll Number', icon: Icons.badge_outlined, controller: _rollNumberController),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, width: 1.5)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSemester, hint: const Text("Semester"), isExpanded: true,
                            items: semesters.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => selectedSemester = val),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, width: 1.5)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedSection, hint: const Text("Section"), isExpanded: true,
                            items: sections.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (val) => setState(() => selectedSection = val),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                AuthTextField(hintText: 'Department', icon: Icons.business, controller: _departmentController),
                const SizedBox(height: 12),
                AuthTextField(hintText: 'CNIC', icon: Icons.credit_card, controller: _cnicController),
                const SizedBox(height: 12),
              ],

              AuthTextField(hintText: 'Email Address', icon: Icons.email_outlined, controller: _emailController),
              const SizedBox(height: 12),
              AuthTextField(
                  hintText: 'Password', icon: Icons.lock_outline, controller: _passwordController,
                  isPassword: true, obscureText: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)
              ),

              if (!_isLogin) ...[
                const SizedBox(height: 12),
                AuthTextField(
                    hintText: 'Confirm Password', icon: Icons.lock_outline, controller: _confirmPasswordController,
                    isPassword: true, obscureText: _obscureConfirmPassword, onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)
                ),
              ],

              if (_isLogin) ...[
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _showForgotPasswordSheet,
                    child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              const SizedBox(height: 25),

              // MAIN AUTH BUTTON
              GestureDetector(
                onTap: _isLoading || authProvider.isLoading ? null : () => _handleAuth(authProvider),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)]),
                  ),
                  child: Center(
                    child: _isLoading || authProvider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_isLogin ? "Login" : "Sign Up", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? "Don't have an account? " : "Already have an account? ", style: const TextStyle(fontSize: 16)),
                  GestureDetector(
                    onTap: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin ? 'Sign Up' : 'Login', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),

              if (_isLogin) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("OR")),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: _isLoading ? null : () => _handleGoogleSignIn(authProvider),
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300, width: 1.5)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/google.jpg', height: 24),
                        const SizedBox(width: 12),
                        const Text("Sign in with Google", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ]
            ],
          );
        },
      ),
    );
  }
}