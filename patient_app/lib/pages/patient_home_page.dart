import 'package:flutter/material.dart';
import '../widgets/patient_app_bar.dart';
import '../widgets/home_action_card.dart';
import '../services/auth_service.dart';
import 'emergency_request_page.dart';
import 'transport_request_page.dart';
import 'first_aid_guide_page.dart';
import 'feedback_page.dart';
import 'request_history_page.dart';
import 'patient_profile_page.dart';
import 'patient_login_page.dart';

class PatientHomePage extends StatelessWidget {
  const PatientHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientLoginPage(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: patientAppBar(context, 'Patient Home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffef3b4c), Color(0xfff97316)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Need Help Quickly?',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Request emergency help, transport services, or view first-aid guidance while waiting for assistance.',
                        style: TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_outlined),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff111827),
                      side: const BorderSide(color: Color(0xffd1d5db)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 800;

                    final cards = [
                      HomeActionCard(
                        icon: Icons.emergency_outlined,
                        title: 'Emergency Request',
                        subtitle:
                        'Send an ambulance request with your location.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EmergencyRequestPage(),
                          ),
                        ),
                      ),
                      HomeActionCard(
                        icon: Icons.local_taxi_outlined,
                        title: 'Transport Request',
                        subtitle:
                        'Request home-to-hospital or hospital-to-home transport.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransportRequestPage(),
                          ),
                        ),
                      ),
                      HomeActionCard(
                        icon: Icons.menu_book_outlined,
                        title: 'First Aid & Guidance',
                        subtitle:
                        'See instructions and tips while waiting for help.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FirstAidGuidePage(),
                          ),
                        ),
                      ),
                      HomeActionCard(
                        icon: Icons.reviews_outlined,
                        title: 'Feedback',
                        subtitle:
                        'Rate and review the service after completion.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FeedbackPage(),
                          ),
                        ),
                      ),
                      HomeActionCard(
                        icon: Icons.history_outlined,
                        title: 'My Requests',
                        subtitle:
                        'See your previous emergency and transport requests.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RequestHistoryPage(),
                          ),
                        ),
                      ),
                      HomeActionCard(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        subtitle: 'View and manage your patient information.',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientProfilePage(),
                          ),
                        ),
                      ),
                    ];

                    if (isSmall) {
                      return Column(
                        children: cards
                            .map(
                              (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: card,
                          ),
                        )
                            .toList(),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cards.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                      ),
                      itemBuilder: (context, index) => cards[index],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}