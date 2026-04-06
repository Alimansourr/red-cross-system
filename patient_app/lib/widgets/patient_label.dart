import 'package:flutter/material.dart';

class PatientLabel extends StatelessWidget {
  final String text;

  const PatientLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xff111827),
      ),
    );
  }
}