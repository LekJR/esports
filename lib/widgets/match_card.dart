import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/match_reminder.dart';

class MatchCard extends StatefulWidget {
  final MatchReminder match;
  final List<TeamOption> teams;
  final ValueChanged<TeamOption> onTeamAChanged;
  final ValueChanged<TeamOption> onTeamBChanged;
  final ValueChanged<DateTime> onTimeChanged;
  final VoidCallback onToggleNotification;

  const MatchCard({
    super.key,
    required this.match,
    required this.teams,
    required this.onTeamAChanged,
    required this.onTeamBChanged,
    required this.onTimeChanged,
    required this.onToggleNotification,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  String get formattedTime {
    final time = TimeOfDay.fromDateTime(widget.match.scheduledTime);
    return time.format(context);
  }

  Future<void> _showTimeWheelPicker() async {
    final now = DateTime.now();
    DateTime normalizeSelectedTime(DateTime value) {
      final todayAtSelectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        value.hour,
        value.minute,
      );
      return todayAtSelectedTime.isBefore(now)
          ? todayAtSelectedTime.add(const Duration(days: 1))
          : todayAtSelectedTime;
    }

    var selectedTime = normalizeSelectedTime(widget.match.scheduledTime);

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return Container(
          height: 320,
          decoration: const BoxDecoration(
            color: Color(0xFF120505),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const Text(
                      'Select match time',
                      style: TextStyle(
                        decoration: TextDecoration.none,
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        widget.onTimeChanged(selectedTime);
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    brightness: Brightness.dark,
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: widget.match.scheduledTime,
                    use24hFormat: false,
                    minuteInterval: 1,
                    onDateTimeChanged: (value) {
                      selectedTime = normalizeSelectedTime(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<TeamOption> get _gameTeams {
    return widget.teams
        .where((team) => team.gameId == widget.match.gameId)
        .toList();
  }

  int? _dropdownValueFor(int teamId) {
    if (_gameTeams.any((team) => team.id == teamId)) {
      return teamId;
    }
    return null;
  }

  Widget _buildTeamDropdown({
    required String hint,
    required int currentValue,
    required ValueChanged<TeamOption> onChanged,
  }) {
    final teams = _gameTeams;

    return DropdownButtonFormField<int>(
      initialValue: _dropdownValueFor(currentValue),
      onChanged: teams.length < 2
          ? null
          : (value) {
              for (final selected in teams) {
                if (selected.id != value) {
                  continue;
                }
                onChanged(selected);
                break;
              }
            },
      isExpanded: true,
      alignment: Alignment.center,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
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
        return teams
            .map(
              (team) => Center(
                child: Text(
                  team.shortName,
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
      items: teams
          .map(
            (team) => DropdownMenuItem<int>(
              value: team.id,
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  team.shortName,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3B0E0E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD32F2F), width: 1.8),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTeamDropdown(
                    hint: 'Team A',
                    currentValue: widget.match.teamAId,
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
                    currentValue: widget.match.teamBId,
                    onChanged: widget.onTeamBChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showTimeWheelPicker,
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
