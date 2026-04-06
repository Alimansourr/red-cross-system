import 'package:flutter/material.dart';
import 'main.dart';
import 'station_dashboard_page.dart';
import 'services/schedule_service.dart';
import 'helpers/auth_helper.dart';

class WeeklySchedulePage extends StatefulWidget {
  final bool fromLogin;

  const WeeklySchedulePage({
    super.key,
    required this.fromLogin,
  });

  @override
  State<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends State<WeeklySchedulePage> {
  final ScheduleService _scheduleService = ScheduleService();

  List<Map<String, dynamic>> weekSchedule = [];
  Map<String, dynamic> stationInfo = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _scheduleService.fetchSchedule(),
        _scheduleService.fetchStationInfo(),
      ]);

      if (mounted) {
        setState(() {
          weekSchedule = results[0] as List<Map<String, dynamic>>;
          stationInfo = results[1] as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load schedule.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<String> _readStringList(
      Map<String, dynamic> data,
      List<String> possibleKeys,
      ) {
    for (final key in possibleKeys) {
      final value = data[key];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xffef3b4c),
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeadOfStationCard(),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int cols = 5;
                        if (constraints.maxWidth < 1200) cols = 3;
                        if (constraints.maxWidth < 800) cols = 2;
                        if (constraints.maxWidth < 500) cols = 1;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics:
                          const NeverScrollableScrollPhysics(),
                          itemCount: weekSchedule.length,
                          gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.42,
                            // mainAxisExtent: 420,
                          ),
                          itemBuilder: (context, index) =>
                              _buildDayCard(weekSchedule[index]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadOfStationCard() {
    final head = stationInfo['headOfStation'] ?? 'Ali Al Mokdad';
    final phone = stationInfo['headPhone'] ?? '3504469';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Head of Station",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            head,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 16,
                color: Color(0xff6b7280),
              ),
              const SizedBox(width: 8),
              Text(
                phone,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff6b7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayData) {
    final drivers = _readStringList(dayData, ['drivers']);
    final missionLeaders =
    _readStringList(dayData, ['missionLeaders', 'mission_leaders']);
    final emts = _readStringList(dayData, ['emts', 'EMTs']);
    final firstResponders = _readStringList(
      dayData,
      ['firstResponders', 'first_responders', 'First Responders'],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayData['day'] ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Team Leader",
            style: TextStyle(
              color: Color(0xffef4444),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.star,
                color: Color(0xfff4b400),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dayData['teamLeader'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xff1f2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 16,
                color: Color(0xff6b7280),
              ),
              const SizedBox(width: 8),
              Text(
                dayData['leaderPhone'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff6b7280),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xffe5e7eb)),
          const SizedBox(height: 12),

          const Text(
            "Drivers",
            style: TextStyle(
              color: Color(0xff2563eb),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (drivers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'No drivers assigned',
                style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
              ),
            )
          else
            ...drivers.map(
                  (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff1f2937),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Text(
            "Mission Leaders",
            style: TextStyle(
              color: Color(0xffef4444),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (missionLeaders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'No mission leaders assigned',
                style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
              ),
            )
          else
            ...missionLeaders.map(
                  (l) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  l,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff1f2937),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Text(
            "EMTs",
            style: TextStyle(
              color: Color(0xff059669),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (emts.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'No EMTs assigned',
                style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
              ),
            )
          else
            ...emts.map(
                  (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  e,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff1f2937),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),
          const Text(
            "First Responders",
            style: TextStyle(
              color: Color(0xff7c3aed),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          if (firstResponders.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'No first responders assigned',
                style: TextStyle(fontSize: 14, color: Color(0xff6b7280)),
              ),
            )
          else
            ...firstResponders.map(
                  (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  r,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff1f2937),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xfff3f4f6),
        border: Border(
          bottom: BorderSide(color: Color(0xffe5e7eb)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isSmall = constraints.maxWidth < 700;

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.calendar_month,
                      color: Color(0xffef3b4c),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Weekly Schedule",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Station 104",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff6b7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.fromLogin)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                            (route) => false,
                      ),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text("Home"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff111827),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xffd1d5db)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StationDashboardPage(),
                            ),
                                (route) => false,
                          ),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text("Home"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xff111827),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xffd1d5db)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => logoutUser(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xffef3b4c),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text("Logout"),
                        ),
                      ),
                    ],
                  ),
              ],
            );
          }

          return Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xff111827),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.calendar_month,
                color: Color(0xffef3b4c),
                size: 30,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Weekly Schedule",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Station 104",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xff6b7280),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => widget.fromLogin
                        ? const LoginPage()
                        : const StationDashboardPage(),
                  ),
                      (route) => false,
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text("Home"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff111827),
                  side: const BorderSide(color: Color(0xffd1d5db)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (!widget.fromLogin) ...[
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => logoutUser(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffef3b4c),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Logout"),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}