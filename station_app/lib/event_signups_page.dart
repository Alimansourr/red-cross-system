import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'station_dashboard_page.dart';
import 'services/event_signup_service.dart';
import 'helpers/auth_helper.dart';
class EventSignupsPage extends StatefulWidget {
  final bool fromLogin;

  const EventSignupsPage({
    super.key,
    required this.fromLogin,
  });

  @override
  State<EventSignupsPage> createState() => _EventSignupsPageState();
}

class _EventSignupsPageState extends State<EventSignupsPage> {
  final EventSignupService _eventSignupService = EventSignupService();
  final TextEditingController subcodeController = TextEditingController();

  bool _isLoadingUser = true;
  String? _userName;
  String? _savedSubcode;
  String? _userRole;
  String? _userTeam;
  String? _userEmail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  @override
  void dispose() {
    subcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final userData = await _eventSignupService.getCurrentUserData();

      setState(() {
        _userName = userData['fullName']?.toString() ?? '';
        _savedSubcode = userData['subcode']?.toString() ?? '';
        _userRole = userData['role']?.toString() ?? '';
        _userTeam = userData['team']?.toString() ?? '';
        _userEmail = userData['email']?.toString() ?? '';
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _signUpForEvent(String eventId, String eventTitle) async {
    try {
      await _eventSignupService.signUpForEvent(
        eventId: eventId,
        enteredSubcode: subcodeController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have successfully signed up for $eventTitle.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _cancelSignup(String eventId, String eventTitle) async {
    try {
      await _eventSignupService.cancelSignup(eventId: eventId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your signup for $eventTitle has been cancelled.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return 'No date';

    try {
      final date = DateTime.parse(rawDate);
      const weekDays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];

      final weekday = weekDays[date.weekday - 1];
      final month = months[date.month - 1];
      final day = date.day;

      return '$weekday, $month ${_withSuffix(day)}, ${date.year}';
    } catch (_) {
      return rawDate;
    }
  }

  String _withSuffix(int day) {
    if (day >= 11 && day <= 13) return '${day}th';

    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
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
              child: _isLoadingUser
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                    const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        _buildUserInfoCard(),
                        const SizedBox(height: 20),
                        _buildUpcomingEventsCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xffef3b4c),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Event Sign-ups",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Browse and register for upcoming events.",
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => widget.fromLogin
                                  ? const LoginPage()
                                  : const StationDashboardPage(),
                            ),
                                (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home_outlined),
                        label: const Text("Home"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xff111827),
                          side: const BorderSide(color: Color(0xffd1d5db)),
                          backgroundColor: Colors.white,
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
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                                (route) => false,
                          );
                        },
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
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xff111827),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xffef3b4c),
                size: 30,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Event Sign-ups",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Browse and register for upcoming events.",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xff6b7280),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => widget.fromLogin
                          ? const LoginPage()
                          : const StationDashboardPage(),
                    ),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.home_outlined),
                label: const Text("Home"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff111827),
                  side: const BorderSide(color: Color(0xffd1d5db)),
                  backgroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(),
                    ),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffef3b4c),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Logout"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard() {
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
            "Your Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Your name is loaded from your account. Enter your subcode to confirm your registration.",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xff6b7280),
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 700;

              if (isSmall) {
                return Column(
                  children: [
                    _buildReadOnlyField("Full Name", _userName ?? ''),
                    const SizedBox(height: 16),
                    _buildEditableSubcodeField(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildReadOnlyField("Full Name", _userName ?? '')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildEditableSubcodeField()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xff111827),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xfff9fafb),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xffd1d5db)),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff374151),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableSubcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Subcode",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xff111827),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: subcodeController,
          decoration: InputDecoration(
            hintText: "Enter your subcode",
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xffd1d5db)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xffef3b4c)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingEventsCard() {
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
            "Upcoming Events",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _eventSignupService.getUpcomingEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Error loading events: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No upcoming events available right now.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff6b7280),
                    ),
                  ),
                );
              }

              return Column(
                children: events.map((event) {
                  return _buildEventItem(event);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(Map<String, dynamic> event) {
    final String eventId = event['id']?.toString() ?? '';
    final String title = event['title']?.toString() ?? 'Untitled Event';
    final String description = event['description']?.toString() ?? '';
    final String location = event['location']?.toString() ?? '';
    final String date = _formatDate(event['date']?.toString());
    final String depart = event['departTime']?.toString() ?? '--:--';
    final String start = event['startTime']?.toString() ?? '--:--';
    final String end = event['endTime']?.toString() ?? '--:--';

    return StreamBuilder<bool>(
      stream: _eventSignupService.isUserSignedUpStream(eventId),
      builder: (context, signupSnapshot) {
        final bool isSignedUp = signupSnapshot.data ?? false;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xfffbfcfe),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffe5e7eb)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xff6b7280),
                ),
              ),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xff64748b),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xff374151),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff4b5563),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isSmall = constraints.maxWidth < 800;

                  if (isSmall) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeItem("Departs at $depart"),
                        const SizedBox(height: 12),
                        _buildTimeItem("Starts at $start"),
                        const SizedBox(height: 12),
                        _buildTimeItem("Ends at $end"),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: _buildTimeItem("Departs at $depart")),
                      Expanded(child: _buildTimeItem("Starts at $start")),
                      Expanded(child: _buildTimeItem("Ends at $end")),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: eventId.isEmpty
                        ? null
                        : () {
                      if (isSignedUp) {
                        _cancelSignup(eventId, title);
                      } else {
                        _signUpForEvent(eventId, title);
                      }
                    },
                    icon: Icon(
                      isSignedUp
                          ? Icons.cancel_outlined
                          : Icons.how_to_reg_outlined,
                      size: 18,
                    ),
                    label: Text(isSignedUp ? "Cancel Sign Up" : "Sign Up"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSignedUp
                          ? const Color(0xff6b7280)
                          : const Color(0xffef3b4c),
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
                  ),
                  if (isSignedUp)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffecfdf3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xffa7f3d0)),
                      ),
                      child: const Text(
                        'You are signed up',
                        style: TextStyle(
                          color: Color(0xff065f46),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeItem(String text) {
    return Row(
      children: [
        const Icon(
          Icons.access_time_outlined,
          size: 20,
          color: Color(0xff64748b),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xff374151),
            ),
          ),
        ),
      ],
    );
  }
}