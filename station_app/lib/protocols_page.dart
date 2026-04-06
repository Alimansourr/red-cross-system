import 'package:flutter/material.dart';
import 'main.dart';
import 'station_dashboard_page.dart';
import 'helpers/auth_helper.dart';

class ProtocolsPage extends StatefulWidget {
  final bool fromLogin;

  const ProtocolsPage({
    super.key,
    required this.fromLogin,
  });

  @override
  State<ProtocolsPage> createState() => _ProtocolsPageState();
}

class _ProtocolsPageState extends State<ProtocolsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> protocols = [
    {
      "title": "Protocol 1: Scene Size Up",
      "description": "Initial scene evaluation before patient contact.",
      "details": [
        "Ensure the scene is safe before approaching the patient.",
        "Wear appropriate PPE and body substance isolation.",
        "Identify mechanism of injury (MOI) or nature of illness (NOI).",
        "Determine the number of patients at the scene.",
        "Consider the need for additional resources or backup.",
        "Prepare to proceed to the primary patient assessment."
      ],
      "flow": [
        "Scene Safety",
        "PPE",
        "NOI / MOI",
        "Patient Count",
        "Resources",
        "Assessment"
      ]
    },
    {
      "title": "Protocol 2: Patient Assessment",
      "description":
      "5 minutes for critical patients - 15 minutes for non-critical patients.",
      "details": [
        "Form a general impression of the patient.",
        "Assess responsiveness using AVPU.",
        "Check airway patency.",
        "Assess breathing effectiveness.",
        "Assess circulation and major bleeding.",
        "Assess disability and neurological status.",
        "Expose when necessary while preserving dignity.",
        "Determine patient priority."
      ],
      "flow": [
        "General Impression",
        "AVPU",
        "Airway",
        "Breathing",
        "Circulation",
        "Disability",
        "Exposure"
      ]
    },
    {
      "title": "Protocol 3: Oxygen Protocol",
      "description": "Guidelines for oxygen administration.",
      "details": [
        "Assess respiratory distress and work of breathing.",
        "Measure oxygen saturation if equipment is available.",
        "Apply oxygen if clinically indicated.",
        "Select suitable oxygen delivery method.",
        "Monitor patient response continuously.",
        "Reassess respiratory status during transport."
      ],
      "flow": [
        "Respiratory Check",
        "SpO2",
        "Need Oxygen?",
        "Give Oxygen",
        "Monitor",
        "Reassess"
      ]
    },
    {
      "title": "Protocol 4: Assisted Ventilation",
      "description": "Support ventilation when breathing is inadequate.",
      "details": [
        "Open the airway using the appropriate maneuver.",
        "Insert airway adjunct if indicated.",
        "Use BVM for inadequate or absent breathing.",
        "Ensure visible chest rise during ventilation.",
        "Monitor oxygenation and patient response.",
        "Continue reassessment and prepare transport."
      ],
      "flow": [
        "Open Airway",
        "Adjunct",
        "BVM",
        "Chest Rise",
        "Monitor",
        "Transport"
      ]
    },
    {
      "title": "Protocol 5: FAST Pre-hospital Stroke Exam",
      "description": "Quick stroke identification procedure.",
      "details": [
        "Check for facial droop.",
        "Check for arm weakness or drift.",
        "Check for speech difficulty.",
        "Determine the time symptoms started.",
        "Document findings clearly.",
        "Arrange urgent transport to appropriate facility."
      ],
      "flow": [
        "Face",
        "Arm",
        "Speech",
        "Time",
        "Document",
        "Transport"
      ]
    },
    {
      "title": "Protocol 6: Shock",
      "description": "Recognition and management of shock.",
      "details": [
        "Recognize signs of poor perfusion and altered mental status.",
        "Check pulse, skin signs, and blood pressure if available.",
        "Control external bleeding if present.",
        "Provide oxygen and supportive care.",
        "Keep the patient warm.",
        "Transport urgently and monitor continuously."
      ],
      "flow": [
        "Recognize Shock",
        "Assess Perfusion",
        "Control Cause",
        "Support",
        "Keep Warm",
        "Transport"
      ]
    },
    {
      "title": "Protocol 7: CPR and AED Usage",
      "description": "Basic resuscitation steps and AED use.",
      "details": [
        "Check responsiveness and breathing.",
        "Call for help and request AED.",
        "Begin high-quality chest compressions.",
        "Attach AED as soon as available.",
        "Follow AED prompts carefully.",
        "Continue CPR until advised otherwise or help arrives."
      ],
      "flow": [
        "Unresponsive",
        "Call Help",
        "Start CPR",
        "Attach AED",
        "Follow Prompts",
        "Continue"
      ]
    },
  ];

  String searchText = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget protocolFlowDiagram(List<String> steps) {
    return Column(
      children: List.generate(steps.length, (index) {
        final bool isLast = index == steps.length - 1;

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff111827),
                  ),
                ),
              ),
            ),
            if (!isLast)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Icon(
                  Icons.arrow_downward,
                  color: Color(0xffef3b4c),
                  size: 22,
                ),
              ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredProtocols = protocols.where((protocol) {
      final title = protocol["title"].toString().toLowerCase();
      final description = protocol["description"].toString().toLowerCase();

      return title.contains(searchText.toLowerCase()) ||
          description.contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xffe5e7eb)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Protocols",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Click on a protocol to view its content.",
                        style: TextStyle(
                          color: Color(0xff6b7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search protocols...",
                          hintStyle: const TextStyle(color: Color(0xff9ca3af)),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xff6b7280),
                          ),
                          filled: true,
                          fillColor: const Color(0xfffafafa),
                          contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: Color(0xffd1d5db)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: Color(0xffd1d5db)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            const BorderSide(color: Color(0xffef3b4c)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "General",
                        style: TextStyle(
                          color: Color(0xffef3b4c),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filteredProtocols.isEmpty
                            ? const Center(
                          child: Text(
                            "No protocols found.",
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xff6b7280),
                            ),
                          ),
                        )
                            : ListView.builder(
                          itemCount: filteredProtocols.length,
                          itemBuilder: (context, index) {
                            final protocol = filteredProtocols[index];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0xffe5e7eb),
                                  ),
                                ),
                              ),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                iconColor: const Color(0xff111827),
                                collapsedIconColor:
                                const Color(0xff111827),
                                childrenPadding: const EdgeInsets.only(
                                  left: 0,
                                  right: 0,
                                  bottom: 16,
                                ),
                                title: Text(
                                  protocol["title"],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff111827),
                                  ),
                                ),
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      protocol["description"],
                                      style: const TextStyle(
                                        color: Color(0xff6b7280),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: List.generate(
                                      (protocol["details"] as List).length,
                                          (i) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "• ",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xff111827),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                protocol["details"][i],
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color:
                                                  Color(0xff111827),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                      BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xffd1d5db),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Flow Diagram",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xffef3b4c),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        protocolFlowDiagram(
                                          List<String>.from(
                                            protocol["flow"],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
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
                      Icons.menu_book_outlined,
                      color: Color(0xffef3b4c),
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Station Protocols",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff111827),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Reference guide for volunteers",
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
                Icons.menu_book_outlined,
                color: Color(0xffef3b4c),
                size: 30,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Station Protocols",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Reference guide for volunteers",
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
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xffd1d5db)),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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