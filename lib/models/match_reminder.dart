class MatchReminder {
  final int id;
  final String teamA;
  final String teamB;
  final DateTime scheduledTime;
  final bool notificationsEnabled;

  const MatchReminder({
    required this.id,
    required this.teamA,
    required this.teamB,
    required this.scheduledTime,
    this.notificationsEnabled = false,
  });

  factory MatchReminder.empty({required int id}) {
    final nextHour = DateTime.now().add(const Duration(hours: 1));
    return MatchReminder(
      id: id,
      teamA: '',
      teamB: '',
      scheduledTime: DateTime(
        nextHour.year,
        nextHour.month,
        nextHour.day,
        nextHour.hour,
        0,
      ),
      notificationsEnabled: false,
    );
  }

  MatchReminder copyWith({
    String? teamA,
    String? teamB,
    DateTime? scheduledTime,
    bool? notificationsEnabled,
  }) {
    return MatchReminder(
      id: id,
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
