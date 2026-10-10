import 'package:flutter/material.dart';

class StickerModel {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final int unlockLevel;
  final Color color;

  const StickerModel({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.unlockLevel,
    required this.color,
  });

  static const List<StickerModel> allStickers = [
    StickerModel(
      id: 'st_1',
      title: 'İlk Adım Rozeti',
      emoji: '⭐',
      description: '5. Bölümü tamamlayarak kazandığın ilk başarı rozeti!',
      unlockLevel: 5,
      color: Color(0xFFFFC107),
    ),
    StickerModel(
      id: 'st_2',
      title: 'Ada Kaşifi',
      emoji: '🧭',
      description: '10. Bölümde İlk Adımlar Adası\'nın haritasını fethettin!',
      unlockLevel: 10,
      color: Color(0xFF4CAF50),
    ),
    StickerModel(
      id: 'st_3',
      title: 'Kanyon Yolcusu',
      emoji: '🧗',
      description: '15. Bölümde dar kanyon geçitlerini başarıyla aştın.',
      unlockLevel: 15,
      color: Color(0xFF795548),
    ),
    StickerModel(
      id: 'st_4',
      title: 'Kaya Delici',
      emoji: '⛏️',
      description: '20. Bölümde tüm kaya engellerini ve labirentleri fethettin!',
      unlockLevel: 20,
      color: Color(0xFF8D6E63),
    ),
    StickerModel(
      id: 'st_5',
      title: 'Döngü Çırağı',
      emoji: '🔄',
      description: '25. Bölümde kodlarını tekrarlarla sadeleştirmeyi öğrendin.',
      unlockLevel: 25,
      color: Color(0xFFFF9800),
    ),
    StickerModel(
      id: 'st_6',
      title: 'Turbo Hızlandırıcı',
      emoji: '🏎️',
      description: '30. Bölümde döngülerin ustası olup ışık hızına eriştin!',
      unlockLevel: 30,
      color: Color(0xFFFF5722),
    ),
    StickerModel(
      id: 'st_7',
      title: 'Spiral Mimarı',
      emoji: '🌀',
      description: '35. Bölümde geometrik spiral labirentleri çözdün.',
      unlockLevel: 35,
      color: Color(0xFF009688),
    ),
    StickerModel(
      id: 'st_8',
      title: 'Sihirli Kristal',
      emoji: '🔮',
      description: '40. Bölümde Spiral Kulesi\'nin zirvesine ulaştın!',
      unlockLevel: 40,
      color: Color(0xFF9C27B0),
    ),
    StickerModel(
      id: 'st_9',
      title: 'Hazine Sandığı',
      emoji: '🎁',
      description: '45. Bölümde gizli tapınağın ilk hazinesini açtın.',
      unlockLevel: 45,
      color: Color(0xFFFFB300),
    ),
    StickerModel(
      id: 'st_10',
      title: 'Altın Anahtar',
      emoji: '🔑',
      description: '50. Bölümde tüm gizemli tapınak kapılarını açtın!',
      unlockLevel: 50,
      color: Color(0xFFFFD700),
    ),
    StickerModel(
      id: 'st_11',
      title: 'Akıllı Sensör',
      emoji: '💡',
      description: '55. Bölümde "Eğer" koşulları ile robotuna zeka kattın.',
      unlockLevel: 55,
      color: Color(0xFF10B981),
    ),
    StickerModel(
      id: 'st_12',
      title: 'Süper Kahraman Pelerini',
      emoji: '🦸',
      description: '60. Bölümde Karar Ormanı\'nın bilge lideri oldun!',
      unlockLevel: 60,
      color: Color(0xFFE53935),
    ),
    StickerModel(
      id: 'st_13',
      title: 'Fonksiyon Çırağı',
      emoji: '🧪',
      description: '65. Bölümde F1 modüler fonksiyonlarını kullanmaya başladın.',
      unlockLevel: 65,
      color: Color(0xFF8B5CF6),
    ),
    StickerModel(
      id: 'st_14',
      title: 'Büyü Kitabı',
      emoji: '📖',
      description: '70. Bölümde Büyü Vadisi\'nin en güçlü algoritmalarını yazdın!',
      unlockLevel: 70,
      color: Color(0xFFE91E63),
    ),
    StickerModel(
      id: 'st_15',
      title: 'Dişli Çark',
      emoji: '⚙️',
      description: '75. Bölümde büyük fabrikanın montaj bantlarını yönettin.',
      unlockLevel: 75,
      color: Color(0xFF3F51B5),
    ),
    StickerModel(
      id: 'st_16',
      title: 'Fabrika Ustabaşı',
      emoji: '🏭',
      description: '80. Bölümde tüm fabrika otomasyonunu kusursuz tamamladın!',
      unlockLevel: 80,
      color: Color(0xFF455A64),
    ),
    StickerModel(
      id: 'st_17',
      title: 'Hata Avcısı Büyüteç',
      emoji: '🔍',
      description: '85. Bölümde bozuk kodlardaki hataları tek tek ayıkladın.',
      unlockLevel: 85,
      color: Color(0xFF00BCD4),
    ),
    StickerModel(
      id: 'st_18',
      title: 'Altın İngiliz Anahtarı',
      emoji: '🛠️',
      description: '90. Bölümde Robot Tamirhanesi\'nin Baş Mühendisi oldun!',
      unlockLevel: 90,
      color: Color(0xFF009688),
    ),
    StickerModel(
      id: 'st_19',
      title: 'Siber Kalkan',
      emoji: '🛡️',
      description: '95. Bölümde Büyük Usta Şampiyonası finallerine girdin.',
      unlockLevel: 95,
      color: Color(0xFF3F51B5),
    ),
    StickerModel(
      id: 'st_20',
      title: 'Büyük Şampiyonluk Kupası',
      emoji: '🏆',
      description: '100. Bölüm! 100 Seviyenin tamamını bitiren Efsanevi Algoritma Şampiyonu!',
      unlockLevel: 100,
      color: Color(0xFFFFD700),
    ),
  ];
}
