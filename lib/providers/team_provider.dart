import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../models/team_member.dart';
import '../services/visitor_identity_service.dart';

class TeamProvider with ChangeNotifier {
  static const _likedMemberIdsKey = 'liked_team_member_ids';

  List<TeamMember> _members = [];
  bool _isLoading = false;
  String? _error;
  bool _didLoadLocalState = false;
  Set<String> _likedMemberIds = <String>{};

  List<TeamMember> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _baseUrl => AppConfig.apiBaseUrl;

  TeamMember? memberById(String id) {
    for (final member in _members) {
      if (member.id == id) return member;
    }
    return null;
  }

  bool isMemberLiked(String memberId) {
    final member = memberById(memberId);
    if (member != null && member.likedByCurrentActor) return true;
    return _likedMemberIds.contains(memberId);
  }

  Future<void> fetchTeamMembers() async {
    await _ensureLocalStateLoaded();
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final visitorId = await VisitorIdentityService.getVisitorId();
      final uri = Uri.parse(
        '$_baseUrl/team',
      ).replace(queryParameters: {'clientId': visitorId});
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception(_extractError(response.body, 'Failed to load team'));
      }

      final data = json.decode(response.body);
      if (data is! List) {
        throw Exception('Unexpected team response format');
      }

      _members = data
          .whereType<Map<String, dynamic>>()
          .map(TeamMember.fromJson)
          .map(
            (member) => member.copyWith(
              likedByCurrentActor:
                  member.likedByCurrentActor ||
                  _likedMemberIds.contains(member.id),
            ),
          )
          .toList(growable: false);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TeamMember> createTeamMember({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/team'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, 'Failed to create team member'),
      );
    }

    final decoded = json.decode(response.body);
    final memberJson = decoded is Map<String, dynamic>
        ? decoded['member']
        : null;
    if (memberJson is! Map<String, dynamic>) {
      throw Exception('Unexpected create team response');
    }

    final member = TeamMember.fromJson(memberJson);
    _members = [..._members, member]
      ..sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
    return member;
  }

  Future<TeamMember> updateTeamMember({
    required String id,
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/team/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, 'Failed to update team member'),
      );
    }

    final decoded = json.decode(response.body);
    final memberJson = decoded is Map<String, dynamic>
        ? decoded['member']
        : null;
    if (memberJson is! Map<String, dynamic>) {
      throw Exception('Unexpected update team response');
    }

    final member = TeamMember.fromJson(memberJson);
    final index = _members.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _members[index] = member;
    } else {
      _members = [..._members, member];
    }
    _members.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
    return member;
  }

  Future<void> deleteTeamMember(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/team/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, 'Failed to delete team member'),
      );
    }

    _members.removeWhere((item) => item.id == id);
    _likedMemberIds.remove(id);
    await _persistLikedMemberIds();
    notifyListeners();
  }

  Future<void> registerMemberView({
    required String memberId,
    String? userId,
  }) async {
    final visitorId = await VisitorIdentityService.getVisitorId();
    final response = await http.post(
      Uri.parse('$_baseUrl/team/$memberId/view'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'clientId': visitorId,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response.body, 'Failed to register team member view'),
      );
    }

    final decoded = json.decode(response.body);
    final memberJson = decoded is Map<String, dynamic>
        ? decoded['member']
        : null;
    _updateMemberFromResponse(memberJson);
  }

  Future<bool> toggleMemberLike({
    required String memberId,
    String? userId,
  }) async {
    await _ensureLocalStateLoaded();
    final visitorId = await VisitorIdentityService.getVisitorId();
    final response = await http.post(
      Uri.parse('$_baseUrl/team/$memberId/like'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'clientId': visitorId,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, 'Failed to update like'));
    }

    final decoded = json.decode(response.body);
    final liked = decoded is Map<String, dynamic> && decoded['liked'] == true;
    if (liked) {
      _likedMemberIds.add(memberId);
    } else {
      _likedMemberIds.remove(memberId);
    }
    await _persistLikedMemberIds();

    final memberJson = decoded is Map<String, dynamic>
        ? decoded['member']
        : null;
    _updateMemberFromResponse(memberJson, overrideLikedState: liked);
    return liked;
  }

  Future<void> addMemberComment({
    required String memberId,
    required String authorName,
    required String message,
    String? userId,
  }) async {
    final visitorId = await VisitorIdentityService.getVisitorId();
    final response = await http.post(
      Uri.parse('$_baseUrl/team/$memberId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'clientId': visitorId,
        'authorName': authorName.trim(),
        'message': message.trim(),
        if (userId != null && userId.isNotEmpty) 'userId': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractError(response.body, 'Failed to add comment'));
    }

    final decoded = json.decode(response.body);
    final memberJson = decoded is Map<String, dynamic>
        ? decoded['member']
        : null;
    _updateMemberFromResponse(memberJson);
  }

  Future<void> _ensureLocalStateLoaded() async {
    if (_didLoadLocalState) return;
    final prefs = await SharedPreferences.getInstance();
    final likedIds = prefs.getStringList(_likedMemberIdsKey) ?? const [];
    _likedMemberIds = likedIds.where((item) => item.trim().isNotEmpty).toSet();
    _didLoadLocalState = true;
  }

  Future<void> _persistLikedMemberIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _likedMemberIdsKey,
      _likedMemberIds.toList(growable: false),
    );
  }

  void _updateMemberFromResponse(
    dynamic memberJson, {
    bool? overrideLikedState,
  }) {
    if (memberJson is! Map<String, dynamic>) {
      throw Exception('Unexpected team member response');
    }

    final parsedMember = TeamMember.fromJson(memberJson);
    final memberId = (memberJson['_id'] ?? '').toString();
    final updatedMember = parsedMember.copyWith(
      likedByCurrentActor:
          overrideLikedState ??
          parsedMember.likedByCurrentActor ||
              _likedMemberIds.contains(memberId),
    );

    final index = _members.indexWhere((item) => item.id == updatedMember.id);
    if (index >= 0) {
      _members[index] = updatedMember;
    } else {
      _members = [..._members, updatedMember];
    }
    _members.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  String _extractError(String body, String fallback) {
    try {
      final data = json.decode(body);
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return fallback;
  }
}
