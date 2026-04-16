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
  static const List<String> _topValorantTeams = [
    'G2',
    'NRG',
    'T1',
    'SRG',
    'PRX',  
    'DRX',
    'TL',
    'BBL',
    'FNC',
    'MIB',
  ];

  @override
  void didUpdateWidget(covariant MatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  String get formattedTime {
    final time = TimeOfDay.fromDateTime(widget.match.scheduledTime);
    return time.format(context);
  }

  String? _dropdownValueFor(String team) {
    if (_topValorantTeams.contains(team)) {
      return team;
    }
    return null;
  }

  Widget _buildTeamDropdown({
    required String hint,
    required String currentValue,
    required bool enabled,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: _dropdownValueFor(currentValue),
      onChanged: enabled
          ? (value) {
              if (value != null) {
                onChanged(value);
              }
            }
          : null,
      isExpanded: true,
      alignment: Alignment.center,
      icon: enabled
          ? const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70)
          : const SizedBox.shrink(),
      dropdownColor: const Color(0xFF2F0A0A),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 12),
        border: InputBorder.none,
      ),
      hint: Text(
        hint,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54),
      ),
      selectedItemBuilder: (context) {
        return _topValorantTeams
            .map(
              (team) => Center(
                child: Text(
                  team,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList();
      },
      items: _topValorantTeams
          .map(
            (team) => DropdownMenuItem<String>(
              value: team,
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  team,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teamsLocked =
        widget.match.teamA.isNotEmpty && widget.match.teamB.isNotEmpty;

    return Container(
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: teamsLocked
                ? Row(
                    children: [
                      const SizedBox(width: 40),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.match.teamA,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'VS',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.match.teamB,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          onPressed: () {
                            widget.onTeamAChanged('');
                            widget.onTeamBChanged('');
                          },
                          icon: const Icon(
                            Icons.restart_alt_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          tooltip: 'Reset teams',
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildTeamDropdown(
                          hint: 'Team A',
                          currentValue: widget.match.teamA,
                          enabled: true,
                          onChanged: widget.onTeamAChanged,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildTeamDropdown(
                          hint: 'Team B',
                          currentValue: widget.match.teamB,
                          enabled: true,
                          onChanged: widget.onTeamBChanged,
                        ),
                      ),
                    ],
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
