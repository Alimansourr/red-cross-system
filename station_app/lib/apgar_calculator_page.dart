import 'package:flutter/material.dart';

class ApgarCalculatorPage extends StatefulWidget {
  const ApgarCalculatorPage({super.key});

  @override
  State<ApgarCalculatorPage> createState() => _ApgarCalculatorPageState();
}

class _ApgarCalculatorPageState extends State<ApgarCalculatorPage> {
  int? appearance;
  int? pulse;
  int? grimace;
  int? activity;
  int? respiration;

  int get totalScore =>
      (appearance ?? 0) +
          (pulse ?? 0) +
          (grimace ?? 0) +
          (activity ?? 0) +
          (respiration ?? 0);

  String get resultTitle {
    if (totalScore <= 3) return "Critically Low";
    if (totalScore <= 6) return "Moderately Low";
    return "Generally Reassuring";
  }

  String get resultDescription {
    if (totalScore <= 3) {
      return "The newborn may require immediate resuscitative support.";
    }
    if (totalScore <= 6) {
      return "The newborn may require close observation and supportive care.";
    }
    return "The newborn condition appears relatively stable by APGAR score.";
  }

  void resetForm() {
    setState(() {
      appearance = null;
      pulse = null;
      grimace = null;
      activity = null;
      respiration = null;
    });
  }

  Widget buildQuestionCard({
    required String title,
    required int? groupValue,
    required Function(int?) onChanged,
    required List<Map<String, dynamic>> options,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...options.map(
                (option) => RadioListTile<int>(
              value: option["score"],
              groupValue: groupValue,
              activeColor: Colors.red,
              contentPadding: EdgeInsets.zero,
              title: Text("${option["label"]} (${option["score"]})"),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget resultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            "Total APGAR: $totalScore / 10",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 10),
          Text(
            resultTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            resultDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("APGAR Calculator", style: TextStyle(fontWeight: FontWeight.w600)),


      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildQuestionCard(
              title: "Appearance",
              groupValue: appearance,
              onChanged: (v) => setState(() => appearance = v),
              options: [
                {"label": "Blue / pale", "score": 0},
                {"label": "Body pink, extremities blue", "score": 1},
                {"label": "Completely pink", "score": 2},
              ],
            ),
            buildQuestionCard(
              title: "Pulse",
              groupValue: pulse,
              onChanged: (v) => setState(() => pulse = v),
              options: [
                {"label": "Absent", "score": 0},
                {"label": "<100 bpm", "score": 1},
                {"label": "≥100 bpm", "score": 2},
              ],
            ),
            buildQuestionCard(
              title: "Grimace",
              groupValue: grimace,
              onChanged: (v) => setState(() => grimace = v),
              options: [
                {"label": "No response", "score": 0},
                {"label": "Grimace", "score": 1},
                {"label": "Cough / sneeze / pulls away", "score": 2},
              ],
            ),
            buildQuestionCard(
              title: "Activity",
              groupValue: activity,
              onChanged: (v) => setState(() => activity = v),
              options: [
                {"label": "Limp", "score": 0},
                {"label": "Some flexion", "score": 1},
                {"label": "Active motion", "score": 2},
              ],
            ),
            buildQuestionCard(
              title: "Respiration",
              groupValue: respiration,
              onChanged: (v) => setState(() => respiration = v),
              options: [
                {"label": "Absent", "score": 0},
                {"label": "Slow / irregular", "score": 1},
                {"label": "Strong cry", "score": 2},
              ],
            ),
            const SizedBox(height: 16),
            resultCard(),
            const SizedBox(height: 20),
            SizedBox(
              width: 140,
              child: OutlinedButton(
                onPressed: resetForm,
                child: const Text("Reset"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}