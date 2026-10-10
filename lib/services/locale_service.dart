import 'package:flutter/material.dart';
import '../models/command_block.dart';
import 'storage_service.dart';

enum AppLanguage {
  tr,
  en,
}

class LocaleService extends ChangeNotifier {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  AppLanguage _currentLang = AppLanguage.tr;

  AppLanguage get currentLanguage => _currentLang;
  bool get isEnglish => _currentLang == AppLanguage.en;

  void init() {
    final saved = StorageService.instance.languageCode;
    if (saved == 'en') {
      _currentLang = AppLanguage.en;
    } else {
      _currentLang = AppLanguage.tr;
    }
  }

  void toggleLanguage() {
    if (_currentLang == AppLanguage.tr) {
      _currentLang = AppLanguage.en;
      StorageService.instance.saveLanguageCode('en');
    } else {
      _currentLang = AppLanguage.tr;
      StorageService.instance.saveLanguageCode('tr');
    }
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    _currentLang = lang;
    StorageService.instance.saveLanguageCode(lang == AppLanguage.en ? 'en' : 'tr');
    notifyListeners();
  }

  String get languageEmoji => isEnglish ? '🇬🇧' : '🇹🇷';
  String get languageName => isEnglish ? 'English' : 'Türkçe';

  // Komut Blok İsimleri
  String getCommandTitle(CommandType type) {
    if (isEnglish) {
      switch (type) {
        case CommandType.forward:
          return 'Move Forward';
        case CommandType.turnRight:
          return 'Turn Right';
        case CommandType.turnLeft:
          return 'Turn Left';
        case CommandType.loopTimes:
          return 'Repeat';
        case CommandType.ifObstacle:
          return 'If Obstacle';
        case CommandType.callF1:
          return 'Call F1';
      }
    } else {
      switch (type) {
        case CommandType.forward:
          return 'İleri Git';
        case CommandType.turnRight:
          return 'Sağa Dön';
        case CommandType.turnLeft:
          return 'Sola Dön';
        case CommandType.loopTimes:
          return 'Tekrarla';
        case CommandType.ifObstacle:
          return 'Eğer Engel Varsa';
        case CommandType.callF1:
          return 'F1 Fonksiyonu';
      }
    }
  }

  // Genel Arayüz Metinleri
  String tr(String key) {
    final dict = isEnglish ? _enStrings : _trStrings;
    return dict[key] ?? key;
  }

  static const Map<String, String> _trStrings = {
    'run': 'ÇALIŞTIR',
    'step': 'ADIM ADIM',
    'reset': 'SIFIRLA',
    'commandDrawer': '🧩 KOMUT ÇEKMECESİ',
    'tapToAdd': 'Dokun ve ekle',
    'codeOrder': '🚀 Kod Sırası',
    'clear': 'Temizle',
    'howOld': 'Kaç Yaşındasın?',
    'pickAge': 'Yaş grubunu seç ve kodlama macerasına başla! 🎮',
    'dailyChallenge': 'Günün Bulmacası',
    'dailyChallengeDesc': 'Her gün yeni bir zeka bulmacası seni bekliyor!',
    'mysteryChest': 'Yıldız Sandığı',
    'mysteryChestDesc': 'Topladığın yıldızlarla gizemli sandıkları aç!',
    'sandbox': 'Kendi Bölümünü Çiz',
    'sandboxDesc': 'Kendi haritanı tasarla ve arkadaşlarınla paylaş!',
    'shareLevel': 'Bölümü Paylaş',
    'importLevel': 'Bölüm Yükle',
    'levelCode': 'Bölüm Kodu',
    'copyCode': 'Kodu Kopyala',
    'codeCopied': 'Bölüm kodu panoya kopyalandı! 📋',
    'pasteCode': 'Bölüm Kodunu Buraya Yapıştır',
    'loadLevel': 'Haritayı Yükle',
    'hint': 'İpucu',
    'profile': 'Gelişim Raporu',
    'stickers': 'Çıkartma Albümü',
    'watchSolution': 'Nasıl Çözülür? (İzle)',
    'nextLevel': 'Sonraki Bölüm',
    'replay': 'Tekrar Dene',
    'level': 'Bölüm',
    'world': 'Dünya',
    'stars': 'Yıldız',
    'emptyWorkspace': 'Buraya komut blokları ekle!\n(Yukarıdaki çekmeceden tıkla veya sürükle)',
    'insertHere': '+ Araya Ekle',
    'miniModSubtitle': 'Okul Öncesi • Dokun ve Yürü',
    'explorerModSubtitle': 'Temel Kodlama • Döngüler',
    'masterModSubtitle': 'Koşullar • Fonksiyonlar • Tamir',
    'chestLocked': 'Kilitli Sandık',
    'chestUnlocked': 'Tebrikler! Sandık Açıldı! 🎉',
    'chestNeedStars': 'sandığını açmak için toplam',
    'starsNeeded': 'yıldıza ihtiyacın var!',
    'unlockedReward': 'Yeni Karakter Kilidi Açıldı:',
    'alreadyCompletedToday': 'Bugünkü bulmacayı tamamladın! 🎉 Yarın yeni bulmaca için tekrar gel.',
    'congratulations': 'Tebrikler! Harika Kodlama! ⭐',
    'maxCommands': 'Maksimum komut sayısına ulaştın!',
  };

  static const Map<String, String> _enStrings = {
    'run': 'RUN',
    'step': 'STEP-BY-STEP',
    'reset': 'RESET',
    'commandDrawer': '🧩 COMMAND DRAWER',
    'tapToAdd': 'Tap to add',
    'codeOrder': '🚀 Code Order',
    'clear': 'Clear',
    'howOld': 'How Old Are You?',
    'pickAge': 'Select your age group and start coding! 🎮',
    'dailyChallenge': 'Daily Challenge',
    'dailyChallengeDesc': 'A brand new puzzle is waiting for you every day!',
    'mysteryChest': 'Star Chest',
    'mysteryChestDesc': 'Use your collected stars to unlock mystery chests!',
    'sandbox': 'Create Your Level',
    'sandboxDesc': 'Design your own grid map and share it with friends!',
    'shareLevel': 'Share Level',
    'importLevel': 'Import Level',
    'levelCode': 'Level Code',
    'copyCode': 'Copy Code',
    'codeCopied': 'Level code copied to clipboard! 📋',
    'pasteCode': 'Paste Level Code Here',
    'loadLevel': 'Load Level',
    'hint': 'Hint',
    'profile': 'Progress Report',
    'stickers': 'Sticker Album',
    'watchSolution': 'How to Solve? (Watch)',
    'nextLevel': 'Next Level',
    'replay': 'Try Again',
    'level': 'Level',
    'world': 'World',
    'stars': 'Stars',
    'emptyWorkspace': 'Add command blocks here!\n(Tap from above drawer or drag)',
    'insertHere': '+ Insert Here',
    'miniModSubtitle': 'Preschool • Tap & Walk',
    'explorerModSubtitle': 'Core Coding • Loops',
    'masterModSubtitle': 'Conditions • Functions • Debug',
    'chestLocked': 'Locked Chest',
    'chestUnlocked': 'Congratulations! Chest Opened! 🎉',
    'chestNeedStars': 'chest requires a total of',
    'starsNeeded': 'stars to unlock!',
    'unlockedReward': 'New Character Unlocked:',
    'alreadyCompletedToday': 'You finished today\'s challenge! 🎉 Come back tomorrow for a new one.',
    'congratulations': 'Congratulations! Awesome Coding! ⭐',
    'maxCommands': 'Reached maximum command limit!',
  };
}
