import 'package:flutter/material.dart';

class AvatarModel {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String requirement;
  final Color primaryColor;
  final Color accentColor;
  final String accessory; // 'antenna', 'helmet', 'climber', 'racer', 'wizard', 'crown', 'super', 'ninja'
  final int unlockedAfterLevelId;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.requirement,
    required this.primaryColor,
    required this.accentColor,
    required this.accessory,
    required this.unlockedAfterLevelId,
  });

  static const List<AvatarModel> allAvatars = [
    AvatarModel(
      id: 'classic_robi',
      name: 'Klasik Robi',
      emoji: '🤖',
      description: 'Sadık, sevimli ve enerjik başlangıç robotu.',
      requirement: 'Başlangıçta Açık (Bölüm 1)',
      primaryColor: Color(0xFF29B6F6),
      accentColor: Color(0xFF0288D1),
      accessory: 'antenna',
      unlockedAfterLevelId: 0,
    ),
    AvatarModel(
      id: 'astro_robi',
      name: 'Astro Robi',
      emoji: '👨‍🚀',
      description: 'Yıldızlararası görevler için uzay kasklı astronot robot.',
      requirement: '1. Dünya (Bölüm 10) Tamamlanınca Hediye',
      primaryColor: Color(0xFF673AB7),
      accentColor: Color(0xFFFFD54F),
      accessory: 'helmet',
      unlockedAfterLevelId: 10,
    ),
    AvatarModel(
      id: 'climber_robi',
      name: 'Dağcı Robi',
      emoji: '🧗',
      description: 'En dik kaya labirentlerini kolayca aşan maceracı robot.',
      requirement: '2. Dünya (Bölüm 20) Tamamlanınca Hediye',
      primaryColor: Color(0xFF4CAF50),
      accentColor: Color(0xFF81C784),
      accessory: 'climber',
      unlockedAfterLevelId: 20,
    ),
    AvatarModel(
      id: 'turbo_robi',
      name: 'Turbo Robi',
      emoji: '🏎️',
      description: 'Döngüleri ışık hızında geçen yarışçı robot.',
      requirement: '3. Dünya (Bölüm 30) Tamamlanınca Hediye',
      primaryColor: Color(0xFFFF5722),
      accentColor: Color(0xFFFFEB3B),
      accessory: 'racer',
      unlockedAfterLevelId: 30,
    ),
    AvatarModel(
      id: 'magic_robi',
      name: 'Büyücü Robi',
      emoji: '🧙‍♂️',
      description: 'Koşulları ve labirentleri sihirle aşan bilge robot.',
      requirement: '4. Dünya (Bölüm 40) Tamamlanınca Hediye',
      primaryColor: Color(0xFF9C27B0),
      accentColor: Color(0xFFE1BEE7),
      accessory: 'wizard',
      unlockedAfterLevelId: 40,
    ),
    AvatarModel(
      id: 'king_robi',
      name: 'Kral Robi',
      emoji: '👑',
      description: 'Fonksiyonların ve algoritmaların altın taçlı efendisi.',
      requirement: '5. Dünya (Bölüm 50) Tamamlanınca Hediye',
      primaryColor: Color(0xFFFFB300),
      accentColor: Color(0xFFFFF8E1),
      accessory: 'crown',
      unlockedAfterLevelId: 50,
    ),
    AvatarModel(
      id: 'super_robi',
      name: 'Süper Robi',
      emoji: '🦸',
      description: 'Fabrikaları ve dev labirentleri tek hamlede çözen kahraman.',
      requirement: '6. Dünya (Bölüm 60) Tamamlanınca Hediye',
      primaryColor: Color(0xFFE53935),
      accentColor: Color(0xFF1E88E5),
      accessory: 'super',
      unlockedAfterLevelId: 60,
    ),
    AvatarModel(
      id: 'ninja_robi',
      name: 'Siber Ninja',
      emoji: '🥋',
      description: 'Tüm hataları ayıklayan efsanevi şampiyon siber ninja.',
      requirement: 'Tüm Oyunu (Bölüm 100) Tamamlayınca Hediye',
      primaryColor: Color(0xFF263238),
      accentColor: Color(0xFF00E676),
      accessory: 'ninja',
      unlockedAfterLevelId: 100,
    ),
  ];
}
