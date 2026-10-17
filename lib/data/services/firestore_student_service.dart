import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/student_model.dart';

/// Service to synchronize and manage Student records in Google Cloud Firestore
class FirestoreStudentService {
  static final FirestoreStudentService _instance = FirestoreStudentService._internal();
  factory FirestoreStudentService() => _instance;
  FirestoreStudentService._internal();

  static const String projectId = 'uniride-app-79177';
  static const String _baseUrl = 'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  /// Saves or updates a student profile in Cloud Firestore collection 'students'
  Future<bool> saveStudentToFirestore(StudentModel student) async {
    try {
      final docId = student.username.isNotEmpty
          ? student.username.toLowerCase()
          : student.studentId.replaceAll('-', '_').toLowerCase();

      final url = Uri.parse('$_baseUrl/students/$docId');

      final Map<String, dynamic> firestorePayload = {
        'fields': {
          'id': {'stringValue': student.id},
          'name': {'stringValue': student.name},
          'rollNo': {'stringValue': student.studentId},
          'username': {'stringValue': student.username},
          'email': {'stringValue': student.email},
          'department': {'stringValue': student.department},
          'university': {'stringValue': student.university},
          'passwordHash': {'stringValue': student.password ?? ''},
          'status': {'stringValue': 'active'},
          'role': {'stringValue': 'student'},
          'registeredAt': {'stringValue': DateTime.now().toIso8601String()},
          'lastActive': {'stringValue': DateTime.now().toIso8601String()},
        }
      };

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(firestorePayload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('🔥 Student ${student.name} (${student.studentId}) successfully synced to Cloud Firestore');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ Firestore sync response: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Firestore sync error: $e');
      }
      return false;
    }
  }

  /// Retrieves a student document from Cloud Firestore by username or docId
  Future<StudentModel?> getStudentFromFirestore(String username) async {
    try {
      final cleanUsername = username.trim().toLowerCase();
      final url = Uri.parse('$_baseUrl/students/$cleanUsername');

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('fields')) {
          final fields = data['fields'] as Map<String, dynamic>;
          return StudentModel(
            id: fields['id']?['stringValue'] ?? 'usr_$cleanUsername',
            name: fields['name']?['stringValue'] ?? 'Student',
            studentId: fields['rollNo']?['stringValue'] ?? '2022-CS-123',
            username: fields['username']?['stringValue'] ?? cleanUsername,
            email: fields['email']?['stringValue'] ?? '$cleanUsername@student.uet.edu.pk',
            password: fields['passwordHash']?['stringValue'] ?? '',
            department: fields['department']?['stringValue'] ?? 'Computer Science',
            university: fields['university']?['stringValue'] ?? 'UET Gujranwala (RCET)',
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Saves or updates a faculty/staff profile in Cloud Firestore dedicated 'faculty' collection
  Future<bool> saveFacultyToFirestore(StudentModel faculty) async {
    try {
      final docId = faculty.username.isNotEmpty
          ? faculty.username.toLowerCase()
          : faculty.email.split('@').first.replaceAll('.', '_').toLowerCase();

      final url = Uri.parse('$_baseUrl/faculty/$docId');

      final Map<String, dynamic> firestorePayload = {
        'fields': {
          'id': {'stringValue': faculty.id},
          'name': {'stringValue': faculty.name},
          'employeeId': {'stringValue': faculty.studentId},
          'username': {'stringValue': faculty.username},
          'email': {'stringValue': faculty.email},
          'department': {'stringValue': faculty.department},
          'university': {'stringValue': faculty.university},
          'passwordHash': {'stringValue': faculty.password ?? ''},
          'status': {'stringValue': 'active'},
          'role': {'stringValue': 'faculty'},
          'registeredAt': {'stringValue': DateTime.now().toIso8601String()},
          'lastActive': {'stringValue': DateTime.now().toIso8601String()},
        }
      };

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(firestorePayload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (kDebugMode) {
          print('🔥 Faculty ${faculty.name} (${faculty.email}) successfully synced to Cloud Firestore /faculty collection');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('⚠️ Firestore faculty sync response: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Firestore faculty sync error: $e');
      }
      return false;
    }
  }

  /// Retrieves a faculty document from Cloud Firestore by username or docId
  Future<StudentModel?> getFacultyFromFirestore(String username) async {
    try {
      final cleanUsername = username.trim().toLowerCase();
      final url = Uri.parse('$_baseUrl/faculty/$cleanUsername');

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('fields')) {
          final fields = data['fields'] as Map<String, dynamic>;
          return StudentModel(
            id: fields['id']?['stringValue'] ?? 'staff_$cleanUsername',
            name: fields['name']?['stringValue'] ?? 'Faculty Member',
            studentId: fields['employeeId']?['stringValue'] ?? fields['rollNo']?['stringValue'] ?? 'STAFF',
            username: fields['username']?['stringValue'] ?? cleanUsername,
            email: fields['email']?['stringValue'] ?? '$cleanUsername@uet.edu.pk',
            password: fields['passwordHash']?['stringValue'] ?? '',
            department: fields['department']?['stringValue'] ?? 'Faculty & University Staff',
            university: fields['university']?['stringValue'] ?? 'UET Gujranwala (RCET)',
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
