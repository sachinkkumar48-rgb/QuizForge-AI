library;

import 'package:meta/meta.dart';

/// Immutable model representing a member or chairperson of a Committee/Commission.
@immutable
class CommitteeMember {
  final String name;
  final String designation;
  final String role; // e.g., Chairperson, Member, Member-Secretary
  final String profile;

  const CommitteeMember({
    required this.name,
    this.designation = '',
    this.role = 'Member',
    this.profile = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'designation': designation,
        'role': role,
        'profile': profile,
      };

  factory CommitteeMember.fromJson(Map<String, dynamic> json) => CommitteeMember(
        name: json['name'] as String? ?? '',
        designation: json['designation'] as String? ?? '',
        role: json['role'] as String? ?? 'Member',
        profile: json['profile'] as String? ?? '',
      );
}
