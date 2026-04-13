import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'weekly_schedule_page.dart';
import 'event_signups_page.dart';
import 'mission_registration_page.dart';
import 'wound_care_report_page.dart';
import 'ambulance_checklist_page.dart';
import 'protocols_page.dart';
import 'calculators_home_page.dart';
import 'services/dashboard_service.dart';

class StationDashboardPage extends StatefulWidget {
  const StationDashboardPage({super.key});

  @override
  State<StationDashboardPage> createState() => _StationDashboardPageState();
}

class _StationDashboardPageState extends State<StationDashboardPage> {
  String selectedFilter = "All Checklists";
  final DateTime today = DateTime.now();
  late DateTime focusedMonth;
  String _loggedInName = '';
  final DashboardService _dashboardService = DashboardService();
  late Future<List<String>> _carNumbersFuture;
  Future<Map<String, List<CalendarMarker>>>? _calendarMarkersFuture;

  final List<Map<String, dynamic>> quickLinks = [
    {"title": "View Schedule", "icon": Icons.calendar_month_outlined},
    {"title": "Events", "icon": Icons.event_outlined},
    {"title": "Mission Registration", "icon": Icons.alt_route_outlined},
    {"title": "Wound Care Report", "icon": Icons.favorite_border},
    {"title": "Go to Checklist", "icon": Icons.checklist_rtl},
    {"title": "Protocols", "icon": Icons.menu_book_outlined},
    {"title": "Calculators", "icon": Icons.calculate_outlined},
  ];

  @override
  void initState() {
    super.initState();
    focusedMonth = DateTime(today.year, today.month, 1);
    _loadUserName();
    _carNumbersFuture = _dashboardService.fetchCarNumbersFromChecklistStatus();
    _calendarMarkersFuture =
        _dashboardService.fetchCalendarMarkersForMonth(focusedMonth);
  }

  Future<void> _loadUserName() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (mounted) {
        setState(() {
          _loggedInName = doc.data()?['fullName']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  void _changeMonth(int delta) {
    setState(() {
      focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + delta, 1);
      _calendarMarkersFuture =
          _dashboardService.fetchCalendarMarkersForMonth(focusedMonth);
    });
  }

  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];
    return months[month - 1];
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Color _tileFillColor({required bool checked, required String shift}) {
    if (!checked) return const Color(0xfffee2e2);
    if (shift == 'morning') return const Color(0xffdcfce7);
    return const Color(0xffecfccb);
  }

  Color _tileBorderColor({required bool checked, required String shift}) {
    if (!checked) return const Color(0xfffecaca);
    if (shift == 'morning') return const Color(0xff22c55e);
    return const Color(0xff84cc16);
  }

  Color _tileTextColor({required bool checked, required String shift}) {
    if (!checked) return const Color(0xffb91c1c);
    if (shift == 'morning') return const Color(0xff166534);
    return const Color(0xff3f6212);
  }

  Color _dayBackgroundColor({
    required bool isToday,
    required bool isWeekend,
    required bool hasEvent,
  }) {
    if (isToday) return const Color(0xffef3b4c);
    if (hasEvent) return const Color(0xffdbeafe);
    if (isWeekend) return const Color(0xfffffbeb);
    return Colors.transparent;
  }

  Color _dayTextColor({
    required bool isToday,
    required bool hasEvent,
    required bool isWeekend,
  }) {
    if (isToday) return Colors.white;
    if (hasEvent) return const Color(0xff1d4ed8);
    if (isWeekend) return const Color(0xffa16207);
    return const Color(0xff111827);
  }

  Future<void> _showDayDetails({
    required DateTime date,
    required List<CalendarMarker> markers,
    required bool isWeekend,
  }) async {
    final eventMarkers =
    markers.where((marker) => marker.type == 'event').toList();

    final hasAnything = eventMarkers.isNotEmpty || isWeekend;
    if (!hasAnything) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${date.day}/${date.month}/${date.year}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWeekend)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('• Weekend'),
                ),
              ...eventMarkers.map((marker) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• Event: ${marker.title}'),
                );
              }),
            ],
          ),
          actions: [
            if (eventMarkers.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EventSignupsPage(fromLogin: false),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffef3b4c),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go to Events Page'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildAnnouncementsCard(),
                    const SizedBox(height: 16),
                    _buildQuickLinksCard(),
                    const SizedBox(height: 16),
                    _buildFilterRow(),
                    const SizedBox(height: 16),
                    _buildChecklistStatusCard(
                      title: "Morning Check Status",
                      subtitle: "Today's Shift (Day Duty)",
                      icon: Icons.wb_sunny_outlined,
                      shift: 'morning',
                      iconColor: const Color(0xfff59e0b),
                    ),
                    const SizedBox(height: 16),
                    _buildChecklistStatusCard(
                      title: "Evening Check Status",
                      subtitle: "Today's Shift (Shift Teams)",
                      icon: Icons.nights_stay_outlined,
                      shift: 'evening',
                      iconColor: const Color(0xff3b82f6),
                    ),
                    const SizedBox(height: 16),
                    _buildCalendarCard(),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const AmbulanceChecklistPage(fromLogin: false),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffef3b4c),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Go to Checklist Form",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 260,
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xfff3f4f6)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.10),
              Colors.white.withOpacity(0.88),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffef3b4c),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Logout"),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _loggedInName.isEmpty
                  ? 'Welcome to Station 104'
                  : 'Welcome, $_loggedInName',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Hope Comes in Red and White",
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Station Announcements",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Latest updates and important notices.",
            style: TextStyle(color: Colors.blueGrey.shade500),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _dashboardService.watchAnnouncements(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xffef3b4c)),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfff9fafb),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffe5e7eb)),
                  ),
                  child: const Text(
                    'No announcements at the moment.',
                    style: TextStyle(color: Color(0xff6b7280)),
                  ),
                );
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final isBlue = (data['color'] ?? '') == 'blue';
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isBlue
                          ? const Color(0xffdbeafe)
                          : const Color(0xfffef3c7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isBlue
                            ? const Color(0xff93c5fd)
                            : const Color(0xfff5d76e),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.circle,
                            size: 10,
                            color: isBlue
                                ? const Color(0xff3b82f6)
                                : const Color(0xffeab308),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['text'] ?? '',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if ((data['postedBy'] ?? '').isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Posted by ${data['postedBy']}',
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinksCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Links",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            "Your station management tools.",
            style: TextStyle(color: Colors.blueGrey.shade500),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            itemCount: quickLinks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemBuilder: (context, index) {
              final item = quickLinks[index];
              return InkWell(
                onTap: () => _handleQuickLink(item['title']),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe5e7eb)),
                    color: Colors.white,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item["icon"],
                        color: const Color(0xffef3b4c),
                        size: 28,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          item["title"],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleQuickLink(String title) {
    final routes = {
      "View Schedule": const WeeklySchedulePage(fromLogin: false),
      "Events": const EventSignupsPage(fromLogin: false),
      "Mission Registration": const MissionRegistrationPage(fromLogin: false),
      "Wound Care Report": const WoundCareReportPage(fromLogin: false),
      "Go to Checklist": const AmbulanceChecklistPage(fromLogin: false),
      "Protocols": const ProtocolsPage(fromLogin: false),
      "Calculators": const CalculatorsHomePage(fromLogin: false),
    };
    final page = routes[title];
    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }

  Widget _buildFilterRow() {
    return _card(
      child: Row(
        children: [
          const Text(
            "Filter Check Status:",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffe5e7eb)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFilter,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: "All Checklists",
                      child: Text("All Checklists"),
                    ),
                    DropdownMenuItem(
                      value: "Completed",
                      child: Text("Completed"),
                    ),
                    DropdownMenuItem(
                      value: "Pending",
                      child: Text("Pending"),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedFilter = value);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistStatusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String shift,
    required Color iconColor,
  }) {
    return FutureBuilder<List<String>>(
      future: _carNumbersFuture,
      builder: (context, carsSnapshot) {
        if (carsSnapshot.connectionState == ConnectionState.waiting) {
          return _card(
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xffef3b4c)),
              ),
            ),
          );
        }
        final unitIds = carsSnapshot.data ?? [];
        return StreamBuilder<DocumentSnapshot>(
          stream: _dashboardService.watchChecklistStatus(),
          builder: (context, snapshot) {
            final Map<String, bool> unitStatus = {
              for (final id in unitIds) id: false,
            };
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              final shiftData = data?[shift] as Map<String, dynamic>? ?? {};
              for (final id in unitIds) {
                unitStatus[id] = shiftData[id] as bool? ?? false;
              }
            }
            final filteredIds = unitIds.where((id) {
              if (selectedFilter == "Completed") return unitStatus[id] == true;
              if (selectedFilter == "Pending") return unitStatus[id] == false;
              return true;
            }).toList();
            return _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffdcfce7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xff16a34a),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xff16a34a),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.blueGrey.shade500),
                  ),
                  const SizedBox(height: 16),
                  if (filteredIds.isEmpty)
                    const Text(
                      'No units match this filter.',
                      style: TextStyle(color: Color(0xff6b7280)),
                    )
                  else
                    GridView.builder(
                      itemCount: filteredIds.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (context, index) {
                        final id = filteredIds[index];
                        final ok = unitStatus[id] ?? false;
                        return Container(
                          decoration: BoxDecoration(
                            color: _tileFillColor(checked: ok, shift: shift),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _tileBorderColor(
                                checked: ok,
                                shift: shift,
                              ),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.local_shipping_outlined,
                                  size: 34,
                                  color: _tileTextColor(
                                    checked: ok,
                                    shift: shift,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Text(
                                  id,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _tileTextColor(
                                      checked: ok,
                                      shift: shift,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalendarCard() {
    const days = ["M", "T", "W", "T", "F", "S", "S"];
    final int year = focusedMonth.year;
    final int month = focusedMonth.month;
    final DateTime firstDay = DateTime(year, month, 1);
    final int daysInMonth = DateUtils.getDaysInMonth(year, month);
    final int leadingEmpty = firstDay.weekday - 1;
    final int totalCells = leadingEmpty + daysInMonth;
    final int finalCellCount = ((totalCells / 7).ceil()) * 7;

    return _card(
      child: FutureBuilder<Map<String, List<CalendarMarker>>>(
        future: _calendarMarkersFuture,
        builder: (context, snapshot) {
          final markersByDate = snapshot.data ?? {};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "${_monthName(month)} $year",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _changeMonth(-1),
                    borderRadius: BorderRadius.circular(10),
                    child: _smallSquareButton(Icons.chevron_left),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _changeMonth(1),
                    borderRadius: BorderRadius.circular(10),
                    child: _smallSquareButton(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: days
                    .map(
                      (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          color: Colors.blueGrey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                itemCount: finalCellCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingEmpty || index >= leadingEmpty + daysInMonth) {
                    return const SizedBox.shrink();
                  }
                  final int dayNumber = index - leadingEmpty + 1;
                  final DateTime current = DateTime(year, month, dayNumber);
                  final bool isToday = _isSameDate(current, today);
                  final bool isWeekend = _isWeekend(current);
                  final String key = _dateKey(current);
                  final List<CalendarMarker> markers = markersByDate[key] ?? [];
                  final bool hasEvent =
                  markers.any((marker) => marker.type == 'event');

                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => _showDayDetails(
                      date: current,
                      markers: markers,
                      isWeekend: isWeekend,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _dayBackgroundColor(
                          isToday: isToday,
                          isWeekend: isWeekend,
                          hasEvent: hasEvent,
                        ),
                        shape: BoxShape.circle,
                        border: !isToday && (hasEvent || isWeekend)
                            ? Border.all(
                          color: hasEvent
                              ? const Color(0xff93c5fd)
                              : const Color(0xfffde68a),
                        )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$dayNumber",
                            style: TextStyle(
                              color: _dayTextColor(
                                isToday: isToday,
                                hasEvent: hasEvent,
                                isWeekend: isWeekend,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isToday && (hasEvent || isWeekend)) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasEvent)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xff3b82f6),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                if (hasEvent && isWeekend)
                                  const SizedBox(width: 3),
                                if (isWeekend)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xfff59e0b),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 10,
                children: [
                  _legendItem(color: const Color(0xff3b82f6), label: 'Event'),
                  _legendItem(color: const Color(0xfff59e0b), label: 'Weekend'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xff4b5563),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _smallSquareButton(IconData icon) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe5e7eb)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe5e7eb)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}