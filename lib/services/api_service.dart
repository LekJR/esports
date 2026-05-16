import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/match_reminder.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const _configuredBaseUrl = String.fromEnvironment('https://esports-production-422e.up.railway.app/');
  static const _deviceId = String.fromEnvironment(
    'DEVICE_ID',
    defaultValue: 'demo-device',
  );

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get deviceId => _deviceId;

  String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    if (kIsWeb) {
      // For web, use the same origin but with :3000 port
      // This works for local development where backend runs on :3000
      return 'http://${Uri.base.host}:3000';
    }

    return 'http://localhost:3000';
  }

  Future<List<TeamOption>> fetchTeams() async {
    final response = await _get('/api/teams');
    return _dataList(
      response,
    ).map((item) => TeamOption.fromJson(item)).toList();
  }

  Future<List<GameOption>> fetchGames() async {
    final response = await _get('/api/games');
    return _dataList(
      response,
    ).map((item) => GameOption.fromJson(item)).toList();
  }

  Future<List<MatchReminder>> fetchMatchesWithReminders() async {
    final responses = await Future.wait([
      _get('/api/matches'),
      _get('/api/reminders?deviceId=$_deviceId'),
    ]);
    final reminderByMatchId = <int, Map<String, dynamic>>{};

    for (final reminder in _dataList(responses[1])) {
      reminderByMatchId[reminder['matchId'] as int] = reminder;
    }

    return _dataList(responses[0])
        .map(
          (match) => MatchReminder.fromMatchJson(
            match,
            reminderJson: reminderByMatchId[match['id'] as int],
          ),
        )
        .toList();
  }

  Future<MatchReminder> createMatch({
    required int gameId,
    required int teamAId,
    required int teamBId,
    required DateTime scheduledTime,
  }) async {
    final response = await _post('/api/matches', {
      'gameId': gameId,
      'teamAId': teamAId,
      'teamBId': teamBId,
      'scheduledAt': scheduledTime.toUtc().toIso8601String(),
    });

    return MatchReminder.fromMatchJson(_dataObject(response));
  }

  Future<MatchReminder> updateMatch(MatchReminder match) async {
    final response = await _put('/api/matches/${match.id}', {
      'gameId': match.gameId,
      'teamAId': match.teamAId,
      'teamBId': match.teamBId,
      'scheduledAt': match.scheduledTime.toUtc().toIso8601String(),
      'status': match.status,
    });

    return MatchReminder.fromMatchJson(_dataObject(response));
  }

  Future<Map<String, dynamic>> upsertReminder({
    required int matchId,
    required bool notificationsEnabled,
  }) async {
    final response = await _post('/api/reminders', {
      'matchId': matchId,
      'deviceId': _deviceId,
      'notificationsEnabled': notificationsEnabled,
      'remindBeforeMinutes': 0,
    });

    return _dataObject(response);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    return _decode(await _client.get(_uri(path)));
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    return _decode(
      await _client.post(
        _uri(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, Object?> body,
  ) async {
    return _decode(
      await _client.put(
        _uri(path),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] as Map<String, dynamic>?;
      throw ApiException((error?['message'] as String?) ?? 'Request failed.');
    }

    return body;
  }

  List<Map<String, dynamic>> _dataList(Map<String, dynamic> response) {
    return (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _dataObject(Map<String, dynamic> response) {
    return response['data'] as Map<String, dynamic>;
  }
}
