import 'package:flutter/material.dart';

AppBar patientAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xff111827),
    elevation: 0,
    scrolledUnderElevation: 0,
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  );
}