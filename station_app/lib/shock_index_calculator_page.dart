import 'package:flutter/material.dart';

class ShockIndexCalculatorPage extends StatefulWidget {
  const ShockIndexCalculatorPage({super.key});

  @override
  State<ShockIndexCalculatorPage> createState() => _ShockIndexCalculatorPageState();
}

class _ShockIndexCalculatorPageState extends State<ShockIndexCalculatorPage> {
  final TextEditingController heartRateController = TextEditingController();
  final TextEditingController systolicBpController = TextEditingController();

  double? shockIndex;

  void calculateShockIndex() {
    final hr = double.tryParse(heartRateController.text);
    final sbp = double.tryParse(systolicBpController.text);

    if (hr != null && sbp != null && sbp > 0) {
      setState(() {
        shockIndex = hr / sbp;
      });
    } else {
      setState(() {
        shockIndex = null;
      });
    }
  }

  String get resultTitle {
    if (shockIndex == null) return "Enter values";
    if (shockIndex! < 0.7) return "Within Typical Range";
    if (shockIndex! < 1.0) return "Borderline / Observe Carefully";
    return "High Risk / Concerning";
  }

  String get resultDescription {
    if (shockIndex == null) return "Please enter valid heart rate and systolic blood pressure.";
    if (shockIndex! < 0.7) return "Shock index appears relatively acceptable.";
    if (shockIndex! < 1.0) return "Monitor the patient closely and reassess frequently.";
    return "Elevated shock index may suggest hemodynamic instability.";
  }

  void resetForm() {
    setState(() {
      heartRateController.clear();
      systolicBpController.clear();
      shockIndex = null;
    });
  }

  Widget buildInputCard({
    required String title,
    required String hint,
    required TextEditingController controller,
    required String suffix,
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
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: (_) => calculateShockIndex(),
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffix,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    heartRateController.dispose();
    systolicBpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = shockIndex == null ? "--" : shockIndex!.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Shock Index Calculator", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildInputCard(
              title: "Heart Rate",
              hint: "Enter heart rate",
              controller: heartRateController,
              suffix: "bpm",
            ),
            buildInputCard(
              title: "Systolic Blood Pressure",
              hint: "Enter systolic BP",
              controller: systolicBpController,
              suffix: "mmHg",
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
                    "Shock Index: $displayValue",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    resultTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    resultDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  ),
                ],
              ),
            ),
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