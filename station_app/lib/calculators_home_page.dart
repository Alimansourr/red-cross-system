import 'package:flutter/material.dart';
import 'package:fyp/main.dart';
import 'malinas_calculator_page.dart';
import 'gcs_calculator_page.dart';
import 'apgar_calculator_page.dart';
import 'shock_index_calculator_page.dart';
import 'station_dashboard_page.dart';
import 'helpers/auth_helper.dart';

class CalculatorsHomePage extends StatelessWidget {
  final bool fromLogin;

  const CalculatorsHomePage({
    super.key,
    required this.fromLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    _calculatorCard(
                      context,
                      title: "Malinas Score",
                      subtitle: "Assess imminent delivery risk during labor",
                      icon: Icons.pregnant_woman_outlined,
                      page: const MalinasCalculatorPage(),
                    ),
                    _calculatorCard(
                      context,
                      title: "Glasgow Coma Scale (GCS)",
                      subtitle: "Assess level of consciousness",
                      icon: Icons.psychology_alt_outlined,
                      page: const GcsCalculatorPage(),
                    ),
                    _calculatorCard(
                      context,
                      title: "APGAR Score",
                      subtitle: "Assess newborn condition after birth",
                      icon: Icons.child_care_outlined,
                      page: const ApgarCalculatorPage(),
                    ),
                    _calculatorCard(
                      context,
                      title: "Shock Index",
                      subtitle:
                      "Heart rate divided by systolic blood pressure",
                      icon: Icons.monitor_heart_outlined,
                      page: const ShockIndexCalculatorPage(),
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
                      Icons.calculate_outlined,
                      color: Color(0xffef3b4c),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Medical Calculators",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Quick clinical scoring tools",
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
                if (fromLogin)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                              (route) => false,
                        );
                      },
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
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                const StationDashboardPage(),
                              ),
                                  (route) => false,
                            );
                          },
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
                Icons.calculate_outlined,
                color: Color(0xffef3b4c),
                size: 30,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Medical Calculators",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Quick clinical scoring tools",
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
                      builder: (context) => fromLogin
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
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xffd1d5db)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (!fromLogin) ...[
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

  Widget _calculatorCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Widget page,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e7eb)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.red.withOpacity(0.08),
          child: Icon(icon, color: Colors.red),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff111827),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xff6b7280),
            ),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 18,
          color: Color(0xff111827),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}