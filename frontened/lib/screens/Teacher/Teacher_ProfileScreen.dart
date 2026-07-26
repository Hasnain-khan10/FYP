import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:frontened/Provider/auth_provider.dart';

class TeacherProfileScreen extends StatefulWidget {
  static const String profileRoute = '/teacher-profile';

  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _deptController = TextEditingController();
  final TextEditingController _qualController = TextEditingController();
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _specController = TextEditingController();

  File? _selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _fatherNameController.text = user.fatherName ?? "";
      _cnicController.text = user.cnic ?? "";
      _deptController.text = user.department ?? "";
      _qualController.text = user.qualification ?? "";
      _expController.text = user.experience ?? "";
      _specController.text = user.speciality ?? "";
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _emailController.dispose();
    _cnicController.dispose();
    _deptController.dispose();
    _qualController.dispose();
    _expController.dispose();
    _specController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final provider = context.read<AuthProvider>();

    final Map<String, dynamic> teacherProfileMap = {
      "name": _nameController.text.trim(),
      "fatherName": _fatherNameController.text.trim(),
      "cnic": _cnicController.text.trim(),
      "department": _deptController.text.trim(),
      "qualification": _qualController.text.trim(),
      "experience": _expController.text.trim(),
      "speciality": _specController.text.trim(),
    };

    try {
      final success = await provider.updateProfile(
        teacherProfileMap,
        imageFile: _selectedImage,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? "Failed to update profile"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _logout() async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final currentImageUrl = user?.profileImage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF4F46E5),
          onRefresh: () async {
            await context.read<AuthProvider>().loadProfile();
            _loadCurrentData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF4F46E5), width: 3),
                          color: Colors.grey.shade200,
                          image: _selectedImage != null
                              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                              : (currentImageUrl != null && currentImageUrl.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(currentImageUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: (_selectedImage == null && (currentImageUrl == null || currentImageUrl.isEmpty))
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF7C3AED), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                const Text("Personal Information", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 16),
                _buildInputField("Full Name", _nameController, Icons.person_outline),
                const SizedBox(height: 14),
                _buildInputField("Father's Name", _fatherNameController, Icons.family_restroom),
                const SizedBox(height: 14),
                _buildInputField("Email Address", _emailController, Icons.email_outlined, isReadOnly: true),
                const SizedBox(height: 14),
                _buildInputField("CNIC Number", _cnicController, Icons.credit_card),

                const SizedBox(height: 30),

                const Text("Professional Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E1B4B))),
                const SizedBox(height: 16),
                _buildInputField("Department", _deptController, Icons.business),
                const SizedBox(height: 14),
                _buildInputField("Highest Qualification", _qualController, Icons.school_outlined),
                const SizedBox(height: 14),
                _buildInputField("Experience (Years)", _expController, Icons.work_history_outlined, isNumber: true),
                const SizedBox(height: 14),
                _buildInputField("Speciality / Major", _specController, Icons.star_outline),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity, height: 55,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("Log Out", style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isReadOnly = false, bool isNumber = false}) {
    return TextField(
      controller: controller,
      readOnly: isReadOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isReadOnly ? Colors.grey.shade700 : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: isReadOnly ? Colors.grey.shade200 : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
      ),
    );
  }
}