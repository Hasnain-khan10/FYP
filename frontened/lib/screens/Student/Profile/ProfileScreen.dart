import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontened/Provider/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

const Color kPrimary = Color(0xFF4F46E5);
const Color kAccent = Color(0xFF7C3AED);
const Color kBg = Colors.white;
const Color kCard = Colors.white;
const Color kTextPrimary = Color(0xFF1E1B4B);
const Color kTextSecondary = Color(0xFF6B7280);

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});
  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;

  final nameController = TextEditingController();
  final fatherController = TextEditingController();
  final cnicController = TextEditingController();
  final departmentController = TextEditingController();
  final semesterController = TextEditingController();
  final sectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AuthProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = context.watch<AuthProvider>();
    final user = provider.user;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : user == null
            ? const Center(child: Text("No user data"))
            : SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("Profile", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kTextPrimary)),
              const SizedBox(height: 6),
              const Text("Manage your account & information", style: TextStyle(color: kTextSecondary)),
              const SizedBox(height: 25),
              _profileHeader(user),
              const SizedBox(height: 30),

              _sectionTitle("Personal Information"),
              const SizedBox(height: 14),
              _infoTile(Icons.person, "Name", user.name),
              const SizedBox(height: 12),
              _infoTile(Icons.mail_outline, "Email", user.email),
              const SizedBox(height: 12),
              _infoTile(Icons.badge_outlined, "Roll Number", user.rollNumber ?? ""),
              const SizedBox(height: 12),
              _infoTile(Icons.person_outline, "Father Name", user.fatherName ?? ""),
              const SizedBox(height: 12),
              _infoTile(Icons.credit_card, "CNIC", user.cnic ?? ""),
              const SizedBox(height: 30),

              _sectionTitle("Academic Information"),
              const SizedBox(height: 14),
              _infoTile(Icons.school_outlined, "Department", user.department ?? ""),
              const SizedBox(height: 12),
              _infoTile(Icons.calendar_month_outlined, "Semester", user.semester ?? ""),
              const SizedBox(height: 12),
              _infoTile(Icons.group, "Section", user.section ?? ""),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: () => _openEditSheet(user),
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 3),
                  child: const Text("Update Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              _logoutButton(context),
              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  void _openEditSheet(user) {
    nameController.text = user.name ?? "";
    fatherController.text = user.fatherName ?? "";
    cnicController.text = user.cnic ?? "";
    departmentController.text = user.department ?? "";
    semesterController.text = user.semester ?? "";
    sectionController.text = user.section ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final img = await _picker.pickImage(source: ImageSource.gallery);
                        if (img != null) {
                          setState(() => _image = File(img.path));
                          setStateSheet(() {});
                        }
                      },
                      child: CircleAvatar(
                        radius: 45,
                        backgroundImage: _image != null ? FileImage(_image!) : (user.profileImage != null && user.profileImage!.isNotEmpty ? NetworkImage(user.profileImage!) : null),
                        child: (_image == null && (user.profileImage == null || user.profileImage!.isEmpty)) ? const Icon(Icons.person, size: 40) : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _field("Name", nameController),
                    _field("Father Name", fatherController),
                    _field("CNIC", cnicController),
                    _field("Department", departmentController),
                    _field("Semester", semesterController),
                    _field("Section", sectionController),
                    const SizedBox(height: 20),

                    Consumer<AuthProvider>(
                      builder: (context, provider, child) {
                        return SizedBox(
                          width: double.infinity, height: 50,
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : () async {
                              final updatedData = {
                                "name": nameController.text.trim(),
                                "fatherName": fatherController.text.trim(),
                                "cnic": cnicController.text.trim(),
                                "department": departmentController.text.trim(),
                                "semester": semesterController.text.trim(),
                                "section": sectionController.text.trim(),
                              };

                              final success = await context.read<AuthProvider>().updateProfile(updatedData, imageFile: _image);

                              if (!mounted) return;

                              if (success) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully"), backgroundColor: Colors.green));
                                await context.read<AuthProvider>().loadProfile();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.error ?? "Update failed"), backgroundColor: Colors.red));
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: provider.isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _field(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(controller: c, decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
    );
  }

  Widget _profileHeader(user) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: [kPrimary, kAccent])),
      child: Column(
        children: [
          Container(
            width: 110, height: 110, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
            child: CircleAvatar(
              radius: 45, backgroundColor: Colors.white,
              backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty ? NetworkImage(user.profileImage!) : null,
              child: user.profileImage == null || user.profileImage!.isEmpty ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : "S", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimary)) : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text("${user.department ?? ""} • ${user.semester ?? ""}", style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextPrimary));
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: kPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: kPrimary)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 13, color: kTextSecondary)), const SizedBox(height: 4), Text(value.isEmpty ? "-" : value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary))])),
        ],
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        width: double.infinity, height: 55, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.red.withValues(alpha: 0.1)),
        alignment: Alignment.center,
        child: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Log out of your account?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(context); // Bottom sheet band karega
                  // 🔥 FIX: Ab yeh Provider ko call karega jo Google Cache bhi saaf karega aur Navigation bhi khud karega
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
                  }                },
                child: Container(width: double.infinity, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: const Text("Log Out", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: double.infinity, alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 14), child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold))),
              ),
            ],
          ),
        );
      },
    );
  }
}