import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Discover',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _isTitleVisible ? 48 : 38,
                      fontWeight: FontWeight.bold,
                    ),
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
            if (_isTitleVisible) ...[
              const SizedBox(height: 6),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Match reminders',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  SliverList _buildMatchSliver(
    List<MatchReminder> matches, {
    double itemSpacing = 16,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final match = matches[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == matches.length - 1 ? 0 : itemSpacing,
          ),
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

  Widget _buildMatchSection({
    required String title,
    required List<MatchReminder> matches,
    double topSpacing = 16,
    double bottomSpacing = 0,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate(title: title),
        ),
        if (topSpacing > 0)
          SliverToBoxAdapter(child: SizedBox(height: topSpacing)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: _buildMatchSliver(matches),
        ),
        if (bottomSpacing > 0)
          SliverToBoxAdapter(child: SizedBox(height: bottomSpacing)),
      ],
    );
  }

  Widget _buildBottomDock() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 4, 24, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.09),
                  const Color(0xFF210505).withOpacity(0.56),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 0.9,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 26),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.24),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DockIcon(icon: Icons.home_rounded),
                    _DockIcon(
                      icon: Icons.explore_rounded,
                      isActive: true,
                    ),
                    _DockIcon(icon: Icons.person_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
              colors: [Color.fromARGB(255, 101, 0, 0), Color.fromARGB(255, 0, 0, 0)],
            ),
          ),
          child: Stack(
            children: [
              Column(
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
                            if (_ongoingMatches.isNotEmpty)
                              _buildMatchSection(
                                title: 'Ongoing matches',
                                matches: _ongoingMatches,
                                topSpacing: 16,
                                bottomSpacing: 20,
                              ),
                            if (_upcomingMatches.isNotEmpty)
                              _buildMatchSection(
                                title: 'Upcoming matches',
                                matches: _upcomingMatches,
                                topSpacing: 16,
                              ),
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverToBoxAdapter(
                                child: const SizedBox(height: 132),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _buildBottomDock(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;

  const _DockIcon({
    required this.icon,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.16),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 26,
        ),
      );
    }

    return Icon(
      icon,
      color: Colors.white.withOpacity(0.72),
      size: 26,
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF180809).withOpacity(0.9),
            const Color(0xFF0E0F12).withOpacity(0.62),
          ],
        ),
        borderRadius: BorderRadius.circular(0),
        border: Border(
        top: BorderSide(color: Colors.white.withOpacity(0.02), width: 0.8),
        bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 0.8),
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
