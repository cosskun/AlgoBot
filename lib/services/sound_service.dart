import 'package:flutter/services.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  bool isMuted = false;

  void toggleMute() {
    isMuted = !isMuted;
  }

  /// Komut bloğu ekleme (Lego klik sesi)
  void playBlockSnap() {
    if (isMuted) return;
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Yıldız toplama sesi (Parlak çan efekti)
  void playStarCollect() {
    if (isMuted) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Anahtar alma ve kapı açma sesi (Mekanik kilit)
  void playKeyOrDoor() {
    if (isMuted) return;
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  /// Robot adım hareketi
  void playStep() {
    if (isMuted) return;
    HapticFeedback.selectionClick();
  }

  /// Duvara / kayaya çarpma sesi (Bop / Oof)
  void playBump() {
    if (isMuted) return;
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
  }

  /// Bölüm kazanma tebrik fanfarı
  void playCelebration() {
    if (isMuted) return;
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// Sandık açılma sesi
  void playChestOpen() {
    if (isMuted) return;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.mediumImpact());
    Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
  }
}
