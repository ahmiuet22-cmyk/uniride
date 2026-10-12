class StudentModel {
  final String id;
  final String name;
  final String studentId;
  final String username;
  final String department;
  final String university;
  final String email;
  final String avatarUrl;
  final String? password;

  const StudentModel({
    required this.id,
    required this.name,
    required this.studentId,
    this.username = '',
    required this.department,
    required this.university,
    required this.email,
    this.avatarUrl = '',
    this.password,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'studentId': studentId,
        'username': username,
        'department': department,
        'university': university,
        'email': email,
        'avatarUrl': avatarUrl,
        if (password != null) 'password': password,
      };

  factory StudentModel.fromJson(Map<String, dynamic> json) => StudentModel(
        id: json['id'] as String? ?? 'usr_guest',
        name: json['name'] as String? ?? 'Student',
        studentId: json['studentId'] as String? ?? (json['roll_number'] as String? ?? '2022-CS-123'),
        username: json['username'] as String? ?? '',
        department: json['department'] as String? ?? 'Computer Science',
        university: json['university'] as String? ?? 'UET Gujranwala (RCET)',
        email: json['email'] as String? ?? 'student@student.uet.edu.pk',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        password: json['password'] as String?,
      );

  // Dynamic helper to resolve student information from official university LMS email
  factory StudentModel.fromLmsEmail(String email, {String? customName}) {
    final cleanEmail = email.trim().toLowerCase();
    final username = cleanEmail.split('@').first;

    String rollNumber = '2022-CS-123';
    String resolvedDept = 'Computer Science & IT';
    String resolvedName = customName ?? 'UET Student';

    // Check for roll number pattern e.g. 2022-cs-123 or 2022cs123
    final rollRegex = RegExp(r'(\d{4})[-_]?([a-zA-Z]{2,4})[-_]?(\d{1,4})');
    final match = rollRegex.firstMatch(username);

    if (match != null) {
      final session = match.group(1);
      final deptCode = match.group(2)!.toUpperCase();
      final num = match.group(3);
      rollNumber = '$session-$deptCode-$num';

      switch (deptCode) {
        case 'CS':
          resolvedDept = 'Computer Science';
          break;
        case 'SE':
          resolvedDept = 'Software Engineering';
          break;
        case 'EE':
          resolvedDept = 'Electrical Engineering';
          break;
        case 'ME':
          resolvedDept = 'Mechanical Engineering';
          break;
        case 'CE':
          resolvedDept = 'Civil Engineering';
          break;
        case 'CH':
        case 'CHE':
          resolvedDept = 'Chemical Engineering';
          break;
        case 'BBA':
          resolvedDept = 'Business Administration';
          break;
        default:
          resolvedDept = '$deptCode Engineering';
      }

      if (customName == null || customName.isEmpty) {
        resolvedName = 'Student $rollNumber';
      }
    } else {
      // Generic email e.g. ali@gmail.com, khadija@gmail.com, ahmed.cs123
      final parts = username.split('.');
      if (parts.isNotEmpty && parts.first.isNotEmpty) {
        resolvedName = parts.first[0].toUpperCase() + parts.first.substring(1);
        if (parts.length > 1) {
          final deptPart = parts[1].toUpperCase();
          if (deptPart.contains('CS')) resolvedDept = 'Computer Science';
          if (deptPart.contains('EE')) resolvedDept = 'Electrical Engineering';
          if (deptPart.contains('ME')) resolvedDept = 'Mechanical Engineering';
          rollNumber = '2022-${deptPart.replaceAll(RegExp(r'[^A-Z0-9]'), '')}';
        }
      }
    }

    if (customName != null && customName.trim().isNotEmpty) {
      resolvedName = customName.trim();
    }

    return StudentModel(
      id: 'usr_${rollNumber.replaceAll('-', '_').toLowerCase()}',
      name: resolvedName,
      studentId: rollNumber,
      department: resolvedDept,
      university: 'UET Gujranwala (RCET)',
      email: cleanEmail,
    );
  }

  static StudentModel defaultStudent() {
    return const StudentModel(
      id: 'usr_001',
      name: 'Ahmed Arshad',
      studentId: '2022-CS-123',
      department: 'Computer Science',
      university: 'UET Gujranwala (RCET)',
      email: 'ahmed.cs123@student.uet.edu.pk',
    );
  }
}
