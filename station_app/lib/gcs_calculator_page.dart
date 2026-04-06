import 'package:flutter/material.dart';

class GcsCalculatorPage extends StatefulWidget {
  const GcsCalculatorPage({super.key});

  @override
  State<GcsCalculatorPage> createState() => _GcsCalculatorPageState();
}

class _GcsCalculatorPageState extends State<GcsCalculatorPage> {
  int? eyeResponse;
  int? verbalResponse;
  int? motorResponse;

  int get totalScore =>
      (eyeResponse ?? 0) + (verbalResponse ?? 0) + (motorResponse ?? 0);

  String get resultTitle {
    if (totalScore <= 8) return "Severe";
    if (totalScore <= 12) return "Moderate";
    return "Mild / Better Neurological Status";
  }

  String get resultDescription {
    if (totalScore <= 8) {
      return "GCS suggests severe impairment and urgent evaluation is needed.";
    }
    if (totalScore <= 12) {
      return "GCS suggests moderate impairment. Monitor carefully.";
    }
    return "GCS suggests relatively mild impairment or preserved consciousness.";
  }

  void resetForm() {
    setState(() {
      eyeResponse = null;
      verbalResponse = null;
      motorResponse = null;
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
            "Total GCS: $totalScore / 15",
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
        title: const Text("GCS Calculator", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildQuestionCard(
              title: "Eye Response",
              groupValue: eyeResponse,
              onChanged: (v) => setState(() => eyeResponse = v),
              options: [
                {"label": "No response", "score": 1},
                {"label": "To pain", "score": 2},
                {"label": "To speech", "score": 3},
                {"label": "Spontaneous", "score": 4},
              ],
            ),
            buildQuestionCard(
              title: "Verbal Response",
              groupValue: verbalResponse,
              onChanged: (v) => setState(() => verbalResponse = v),
              options: [
                {"label": "No response", "score": 1},
                {"label": "Incomprehensible sounds", "score": 2},
                {"label": "Inappropriate words", "score": 3},
                {"label": "Confused", "score": 4},
                {"label": "Oriented", "score": 5},
              ],
            ),
            buildQuestionCard(
              title: "Motor Response",
              groupValue: motorResponse,
              onChanged: (v) => setState(() => motorResponse = v),
              options: [
                {"label": "No response", "score": 1},
                {"label": "Extension to pain", "score": 2},
                {"label": "Flexion to pain", "score": 3},
                {"label": "Withdraws from pain", "score": 4},
                {"label": "Localizes pain", "score": 5},
                {"label": "Obeys commands", "score": 6},
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