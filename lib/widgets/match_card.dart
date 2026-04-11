import 'package:flutter/material.dart';
import '../models/match_reminder.dart';

class MatchCard extends StatefulWidget {
  final MatchReminder match;
  final ValueChanged<String> onTeamAChanged;
  final ValueChanged<String> onTeamBChanged;
  final ValueChanged<DateTime> onTimeChanged;
  final VoidCallback onToggleNotification;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTeamAChanged,
    required this.onTeamBChanged,
    required this.onTimeChanged,
    required this.onToggleNotification,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late final TextEditingController _teamAController;
  late final TextEditingController _teamBController;

  @override
  void initState() {
    super.initState();
    _teamAController = TextEditingController(text: widget.match.teamA);
    _teamBController = TextEditingController(text: widget.match.teamB);
  }

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  String get formattedTime {
    final time = TimeOfDay.fromDateTime(widget.match.scheduledTime);
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B0E0E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade700, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.match.notificationsEnabled
                    ? 'Reminder ON'
                    : 'Reminder OFF',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(
                  widget.match.notificationsEnabled
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  color: widget.match.notificationsEnabled
                      ? const Color.fromARGB(255, 255, 7, 7)
                      : Colors.white70,
                ),
                onPressed: widget.onToggleNotification,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _teamAController,
            onChanged: widget.onTeamAChanged,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Team A',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
          ),
          Center(
            child: Text(
              'VS',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextField(
            controller: _teamBController,
            onChanged: widget.onTeamBChanged,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Team B',
              hintStyle: TextStyle(color: Colors.white54),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(widget.match.scheduledTime),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      timePickerTheme: const TimePickerThemeData(
                        backgroundColor: Colors.black,
                        dialHandColor: Colors.red,
                        dialBackgroundColor: Color(0xFF2F0A0A),
                        hourMinuteTextColor: Colors.white,
                        hourMinuteTextStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        dayPeriodTextColor: Colors.white,
                        dayPeriodColor: Colors.red,
                        entryModeIconColor: Colors.white,
                        hourMinuteColor: Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                final selected = DateTime(
                  widget.match.scheduledTime.year,
                  widget.match.scheduledTime.month,
                  widget.match.scheduledTime.day,
                  time.hour,
                  time.minute,
                );
                widget.onTimeChanged(selected);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2F0A0A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Match Time',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
