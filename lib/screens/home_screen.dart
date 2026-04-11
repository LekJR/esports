import 'package:flutter/material.dart';
import 'dart:async';
import '../models/match_reminder.dart';
import '../widgets/match_card.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<MatchReminder> _matches = [];
  int _nextId = 0;
  Timer? _timer;
  final ScrollController _scrollController = ScrollController();
  bool _isTitleVisible = true;
  double _lastScrollPosition = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _addMatch();
    _startTimer();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
    // Request web notification permission if running on web
    await _notificationService.requestWebNotificationPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  void _onScroll(double currentScrollPosition) {
    final scrollDelta = currentScrollPosition - _lastScrollPosition;

    if (scrollDelta > 4 && _isTitleVisible) {
      setState(() {
        _isTitleVisible = false;
      });
    } else if (scrollDelta < -4 && !_isTitleVisible) {
      setState(() {
        _isTitleVisible = true;
      });
    }

    _lastScrollPosition = currentScrollPosition;
  }

  void _addMatch() {
    setState(() {
      _matches.add(MatchReminder.empty(id: _nextId++));
    });
  }

  void _updateMatch(int id, MatchReminder updatedMatch) {
    setState(() {
      final index = _matches.indexWhere((match) => match.id == id);
      if (index != -1) {
        _matches[index] = updatedMatch;
      }
    });
  }

  void _toggleNotification(MatchReminder match) {
    final updatedMatch = match.copyWith(
      notificationsEnabled: !match.notificationsEnabled,
    );
    _updateMatch(match.id, updatedMatch);

    if (updatedMatch.notificationsEnabled) {
      _notificationService.scheduleMatchNotification(
        updatedMatch.id,
        updatedMatch.teamA,
        updatedMatch.teamB,
        updatedMatch.scheduledTime,
      );
    } else {
      _notificationService.cancelNotification(updatedMatch.id);
    }
  }

  void _updateMatchTime(MatchReminder match, DateTime newTime) {
    final updatedMatch = match.copyWith(scheduledTime: newTime);
    _updateMatch(match.id, updatedMatch);

    if (updatedMatch.notificationsEnabled) {
      _notificationService.cancelNotification(updatedMatch.id);
      _notificationService.scheduleMatchNotification(
        updatedMatch.id,
        updatedMatch.teamA,
        updatedMatch.teamB,
        updatedMatch.scheduledTime,
      );
    }
  }

  Future<void> _refreshMatches() {
    return Future.microtask(() => setState(() {}));
  }

  List<MatchReminder> get _ongoingMatches {
    final now = DateTime.now();
    return _matches
        .where(
          (match) =>
              match.scheduledTime.isBefore(now) ||
              match.scheduledTime.isAtSameMomentAs(now),
        )
        .toList()
      ..sort(
        (a, b) => b.scheduledTime.compareTo(a.scheduledTime),
      ); // Most recent first
  }

  List<MatchReminder> get _upcomingMatches {
    final now = DateTime.now();
    return _matches.where((match) => match.scheduledTime.isAfter(now)).toList()
      ..sort(
        (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
      ); // Soonest first
  }

  Widget _buildTopBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: _isTitleVisible ? 20 : 12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Discover',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _isTitleVisible ? 48 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isTitleVisible) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Match reminders',
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: _addMatch,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(14),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverList _buildMatchSliver(List<MatchReminder> matches) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final match = matches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: MatchCard(
            match: match,
            onTeamAChanged: (value) {
              _updateMatch(match.id, match.copyWith(teamA: value));
            },
            onTeamBChanged: (value) {
              _updateMatch(match.id, match.copyWith(teamB: value));
            },
            onTimeChanged: (newTime) => _updateMatchTime(match, newTime),
            onToggleNotification: () => _toggleNotification(match),
          ),
        );
      }, childCount: matches.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 132, 0, 0), Color(0xFF0B0505)],
            ),
          ),
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshMatches,
                  color: Colors.red,
                  backgroundColor: Colors.black,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        _onScroll(notification.metrics.pixels);
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (_ongoingMatches.isNotEmpty) ...[
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _SectionHeaderDelegate(
                              title: 'Ongoing matches',
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: _buildMatchSliver(_ongoingMatches),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverToBoxAdapter(
                              child: const SizedBox(height: 32),
                            ),
                          ),
                        ],
                        if (_upcomingMatches.isNotEmpty) ...[
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _SectionHeaderDelegate(
                              title: 'Upcoming matches',
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: _buildMatchSliver(_upcomingMatches),
                          ),
                        ],
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: const SizedBox(height: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.red.shade700, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.home, color: Colors.white, size: 30),
                    Icon(Icons.explore, color: Colors.white, size: 30),
                    Icon(Icons.person, color: Colors.white, size: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;

  _SectionHeaderDelegate({required this.title});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 0, 0),
        borderRadius: BorderRadius.circular(0),
        border: Border(
        top: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 1.0),
        bottom: BorderSide(color: const Color.fromARGB(255, 255, 255, 255), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return oldDelegate.title != title;
  }
}
