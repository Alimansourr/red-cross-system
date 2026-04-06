import 'package:flutter/material.dart';
import '../widgets/patient_app_bar.dart';
import '../widgets/patient_section_card.dart';

class FirstAidGuidePage extends StatelessWidget {
  const FirstAidGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      'Stay calm and call for help immediately in severe emergencies.',
      'Keep the patient in a safe area away from danger.',
      'If conscious, encourage slow and steady breathing.',
      'Do not move the injured person if there may be a neck or spine injury.',
      'Apply direct pressure to visible bleeding if it is safe to do so.',
      'Wait for Red Cross guidance or live support if available.',
    ];

    return Scaffold(
      appBar: patientAppBar(context, 'First Aid & Guidance'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: PatientSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Waiting Instructions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Later, this page can be expanded into categorized first-aid protocols and live guidance support.',
                    style: TextStyle(color: Color(0xff6b7280)),
                  ),
                  const SizedBox(height: 20),
                  ...items.map(
                        (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Icon(
                              Icons.check_circle_outline,
                              color: Color(0xffef3b4c),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xff374151),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}