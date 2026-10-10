import 'package:flutter/material.dart';
import '../core/app_colors.dart';

enum AgeMode {
  mini, // 4 - 6 Yaş (Okul Öncesi)
  explorer, // 7 - 9 Yaş (Temel Kodlama)
  master, // 10+ Yaş (İleri Algoritma & Strateji)
}

extension AgeModeExtension on AgeMode {
  String get title {
    switch (this) {
      case AgeMode.mini:
        return 'Mini Mod';
      case AgeMode.explorer:
        return 'Kaşif Modu';
      case AgeMode.master:
        return 'Usta Kodlayıcı';
    }
  }

  String get ageRange {
    switch (this) {
      case AgeMode.mini:
        return '4 - 6 Yaş';
      case AgeMode.explorer:
        return '7 - 9 Yaş';
      case AgeMode.master:
        return '10+ Yaş';
    }
  }

  String get emoji {
    switch (this) {
      case AgeMode.mini:
        return '🐣';
      case AgeMode.explorer:
        return '🚀';
      case AgeMode.master:
        return '🧠';
    }
  }

  String get description {
    switch (this) {
      case AgeMode.mini:
        return 'Sıfır yazı, anında dokun-ilerle butonları ve yanmasız eğlence!';
      case AgeMode.explorer:
        return 'Sıralı komut blokları, yıldız avı ve döngüler.';
      case AgeMode.master:
        return 'Koşullar, F1 fonksiyonları, hata ayıklama ve kod optimizasyonu.';
    }
  }

  Color get color {
    switch (this) {
      case AgeMode.mini:
        return AppColors.ageMini;
      case AgeMode.explorer:
        return AppColors.ageExplorer;
      case AgeMode.master:
        return AppColors.ageMaster;
    }
  }
}
