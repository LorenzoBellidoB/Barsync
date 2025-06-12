import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

void showErrorFlushbar(BuildContext context, String message) {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    messageText: Text(
      message,
      style: const TextStyle(color: Colors.white, fontSize: 16),
    ),
    icon: const Icon(Icons.error, color: Colors.white),
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(12),
    backgroundGradient: const LinearGradient(
      colors: [Colors.red, Colors.deepOrange],
    ),
    leftBarIndicatorColor: Colors.white,
  ).show(context);
}

void showSuccessFlushbar(BuildContext context, String message) {
  Flushbar(
    flushbarPosition: FlushbarPosition.TOP,
    messageText: Text(
      message,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
    duration: const Duration(seconds: 2),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    borderRadius: BorderRadius.circular(12),
    backgroundGradient: const LinearGradient(
      colors: [Color(0xFF43A047), Color(0xFF388E3C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    leftBarIndicatorColor: Colors.white,
  ).show(context);
}
