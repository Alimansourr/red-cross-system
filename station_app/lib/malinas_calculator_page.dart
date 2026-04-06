import 'package:flutter/material.dart';

class MalinasCalculatorPage extends StatefulWidget {
  const MalinasCalculatorPage({super.key});

  @override
  State<MalinasCalculatorPage> createState() => _MalinasCalculatorPageState();
}

class _MalinasCalculatorPageState extends State<MalinasCalculatorPage> {
  int? durationOfLabor;
  int? durationOfContractions;
  int? intervalBetweenContractions;
  int? lossOfWater;

  int get totalScore {
    return (durationOfLabor ?? 0) +
        (durationOfContractions ?? 0) +
        (intervalBetweenContractions ?? 0) +
        (lossOfWater ?? 0);
  }

  String get resultTitle {
    if (totalScore >= 6) return "Imminent Delivery";
    if (totalScore >= 3) return "Possible Delivery Soon";
    return "Delivery Not Imminent";
  }

  String get resultDescription {
    if (totalScore >= 6) {
      return "There is a need for imminent delivery.";
    }
    if (totalScore >= 3) {
      return "Monitor the patient closely and prepare for possible delivery.";
    }
    return "The current score does not indicate imminent delivery.";
  }

  void resetForm() {
    setState(() {
      durationOfLabor = null;
      durationOfContractions = null;
      intervalBetweenContractions = null;
      lossOfWater = null;
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: options.map((option) {
              return RadioListTile<int>(
                value: option["score"],
                groupValue: groupValue,
                activeColor: Colors.red,
                contentPadding: EdgeInsets.zero,
                title: Text("${option["label"]} (${option["score"]})"),
                onChanged: onChanged,
              );
            }).toList(),
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
        title: const Text(
          "Malinas Calculator",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildQuestionCard(
              title: "Duration of labor",
              groupValue: durationOfLabor,
              onChanged: (value) => setState(() => durationOfLabor = value),
              options: [
                {"label": "<3 hours", "score": 0},
                {"label": "3-5 hours", "score": 1},
                {"label": ">6 hours", "score": 2},
              ],
            ),
            buildQuestionCard(
              title: "Duration of contractions",
              groupValue: durationOfContractions,
              onChanged: (value) =>
                  setState(() => durationOfContractions = value),
              options: [
                {"label": "<1 min", "score": 0},
                {"label": "1 min", "score": 1},
                {"label": ">1 min", "score": 2},
              ],
            ),
            buildQuestionCard(
              title: "Interval between 2 contractions",
              groupValue: intervalBetweenContractions,
              onChanged: (value) =>
                  setState(() => intervalBetweenContractions = value),
              options: [
                {"label": ">5 min", "score": 0},
                {"label": "3-5 min", "score": 1},
                {"label": "<3 min", "score": 2},
              ],
            ),
            buildQuestionCard(
              title: "Loss of water",
              groupValue: lossOfWater,
              onChanged: (value) => setState(() => lossOfWater = value),
              options: [
                {"label": "No", "score": 0},
                {"label": "Recent", "score": 1},
                {"label": "1 hour", "score": 2},
              ],
            ),
            const SizedBox(height: 18),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Malinas Score:",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "$totalScore",
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
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
                    resultTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resultDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Note: Malinas score alone is not enough to determine whether to perform childbirth on site or not.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: 140,
              child: OutlinedButton(
                onPressed: resetForm,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Reset"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}