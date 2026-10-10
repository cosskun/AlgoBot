import 'package:flutter/material.dart';

class SpeechService {
  static void speakTurkish({
    required BuildContext context,
    required String text,
    required String avatarEmoji,
  }) {
    // Sesli anlatım bilgi kutusu ve okuma animasyonu
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF4361EE),
                shape: BoxShape.circle,
              ),
              child: Text(avatarEmoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.volume_up, color: Color(0xFF06D6A0), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Robi Sesli Anlatıyor:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF06D6A0)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
