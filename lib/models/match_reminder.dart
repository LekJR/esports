class TeamOption {
  final int id;
  final int gameId;
  final String name;
  final String shortName;

  const TeamOption({
    required this.id,
    required this.gameId,
    required this.name,
    required this.shortName,
  });

  factory TeamOption.fromJson(Map<String, dynamic> json) {
    return TeamOption(
      id: json['id'] as int,
      gameId: json['gameId'] as int,
      name: json['name'] as String,
      shortName: (json['shortName'] as String?) ?? (json['name'] as String),
    );
  }
}

class GameOption {
  final int id;
  final String name;

  const GameOption({required this.id, required this.name});

  factory GameOption.fromJson(Map<String, dynamic> json) {
    return GameOption(id: json['id'] as int, name: json['name'] as String);
  }
}

class MatchReminder {
  final int id;
  final int gameId;
  final int teamAId;
  final int teamBId;
  final String teamA;
  final String teamB;
  final DateTime scheduledTime;
  final String status;
  final int? reminderId;
  final bool notificationsEnabled;

  const MatchReminder({
    required this.id,
    required this.gameId,
    required this.teamAId,
    required this.teamBId,
    required this.teamA,
    required this.teamB,
    required this.scheduledTime,
    required this.status,
    this.reminderId,
    this.notificationsEnabled = false,
  });

  factory MatchReminder.fromMatchJson(
    Map<String, dynamic> matchJson, {
    Map<String, dynamic>? reminderJson,
  }) {
    return MatchReminder(
      id: matchJson['id'] as int,
      gameId: matchJson['game']['id'] as int,
      teamAId: matchJson['teamA']['id'] as int,
      teamBId: matchJson['teamB']['id'] as int,
      teamA: _teamLabel(matchJson['teamA'] as Map<String, dynamic>),
      teamB: _teamLabel(matchJson['teamB'] as Map<String, dynamic>),
      scheduledTime: DateTime.parse(
        matchJson['scheduledAt'] as String,
      ).toLocal(),
      status: matchJson['status'] as String,
      reminderId: reminderJson?['id'] as int?,
      notificationsEnabled:
          (reminderJson?['notificationsEnabled'] as bool?) ?? false,
    );
  }

  MatchReminder copyWith({
    int? gameId,
    int? teamAId,
    int? teamBId,
    String? teamA,
    String? teamB,
    DateTime? scheduledTime,
    String? status,
    int? reminderId,
    bool? notificationsEnabled,
  }) {
    return MatchReminder(
      id: id,
      gameId: gameId ?? this.gameId,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      reminderId: reminderId ?? this.reminderId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  static String _teamLabel(Map<String, dynamic> teamJson) {
    return (teamJson['shortName'] as String?) ?? (teamJson['name'] as String);
  }
}
