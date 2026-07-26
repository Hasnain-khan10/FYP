class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? profileImage;

  // 🔹 Common Fields
  final String? fatherName;
  final String? cnic;
  final String? department;

  // 👨‍🎓 Student Specific
  final String? rollNumber;
  final String? semester;
  final String? section;

  // 👨‍🏫 Teacher Specific
  final String? qualification;
  final String? experience;
  final String? speciality;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImage,
    this.fatherName,
    this.cnic,
    this.department,
    this.rollNumber,
    this.semester,
    this.section,
    this.qualification,
    this.experience,
    this.speciality,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // 🔥 FIX: id aur baaki fields ko .toString() se safe kiya gaya hai
      id: json['id']?.toString() ?? json['_id']?.toString() ?? "",
      name: json['name']?.toString() ?? "",
      email: json['email']?.toString() ?? "",
      role: json['role']?.toString() ?? "student",
      profileImage: json["profileImage"]?.toString(),
      fatherName: json['fatherName']?.toString(),
      cnic: json['cnic']?.toString(),
      department: json['department']?.toString(),
      rollNumber: json['rollNumber']?.toString(),
      semester: json['semester']?.toString(),
      section: json['section']?.toString(),
      qualification: json['qualification']?.toString(),
      experience: json['experience']?.toString(), 
      speciality: json['speciality']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "email": email,
      "role": role,
      "profileImage": profileImage,
      "fatherName": fatherName,
      "cnic": cnic,
      "department": department,
      "rollNumber": rollNumber,
      "semester": semester,
      "section": section,
      "qualification": qualification,
      "experience": experience,
      "speciality": speciality,
    };
  }
}