import 'package:flutter/material.dart';

class AppUtils {
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        } else {
          return '${difference.inMinutes}m ago';
        }
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  static Color getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  static IconData getCrimeTypeIcon(String crimeType) {
    switch (crimeType.toLowerCase()) {
      case 'Maling':
        return Icons.money_off;
      case 'Jambret':
        return Icons.local_police;
      case 'Kekerasan':
        return Icons.warning;
      case 'Perusakan':
        return Icons.broken_image;
      case 'Pembohongan':
        return Icons.attach_money;
      case 'Kecelakaan':
        return Icons.directions_car;
      case 'Narkoba':
        return Icons.local_hospital;
      default:
        return Icons.error;
    }
  }
}
