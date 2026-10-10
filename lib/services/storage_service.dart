import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../models/age_mode.dart';

class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  static const String _storageKey = 'algokids_game_save_v1';

  bool _initialized = false;
  bool _hasSelectedAge = false;
  AgeMode _ageMode = AgeMode.explorer;
  String _avatarId = AppConstants.defaultAvatarId;
  final Set<String> _unlockedAvatars = {AppConstants.defaultAvatarId};
  int _unlockedLevelId = 1;
  final Map<int, int> _levelStars = {};
  String _languageCode = AppConstants.defaultLanguageCode;
  final Set<String> _dailyCompletedDates = {};
  final Set<String> _openedChestIds = {};
  final List<Map<String, dynamic>> _customLevels = [];

  bool get hasSelectedAge => _hasSelectedAge;
  AgeMode get ageMode => _ageMode;
  String get avatarId => _avatarId;
  Set<String> get unlockedAvatars => Set.unmodifiable(_unlockedAvatars);
  int get unlockedLevelId => _unlockedLevelId;
  Map<int, int> get levelStars => Map.unmodifiable(_levelStars);
  String get languageCode => _languageCode;
  Set<String> get dailyCompletedDates => Set.unmodifiable(_dailyCompletedDates);
  Set<String> get openedChestIds => Set.unmodifiable(_openedChestIds);
  List<Map<String, dynamic>> get customLevels => List.unmodifiable(_customLevels);

  int get totalStars {
    return _levelStars.values.fold(0, (sum, stars) => sum + stars);
  }

  File? _getFallbackDesktopFile() {
    if (kIsWeb) return null;
    try {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (home == null || home.isEmpty) return null;
      final dir = Directory('$home/.algokids');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      return File('${dir.path}/game_save.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // 1. Primary storage: SharedPreferences (Native Android, iOS, Web, Desktop)
      final prefs = await SharedPreferences.getInstance();
      String? savedJson = prefs.getString(_storageKey);

      // 2. Fallback check: Desktop local file if SharedPreferences was empty
      if (savedJson == null || savedJson.isEmpty) {
        final file = _getFallbackDesktopFile();
        if (file != null && file.existsSync()) {
          savedJson = await file.readAsString();
        }
      }

      if (savedJson != null && savedJson.isNotEmpty) {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        _loadFromMap(map);
      }
    } catch (e) {
      debugPrint('StorageService init error: $e');
    }
  }

  void _loadFromMap(Map<String, dynamic> map) {
    _hasSelectedAge = map['hasSelectedAge'] as bool? ?? false;
    final modeIndex = map['ageModeIndex'] as int?;
    if (modeIndex != null && modeIndex >= 0 && modeIndex < AgeMode.values.length) {
      _ageMode = AgeMode.values[modeIndex];
    }

    _avatarId = map['avatarId'] as String? ?? AppConstants.defaultAvatarId;
    if (map['unlockedAvatars'] is List) {
      _unlockedAvatars.clear();
      _unlockedAvatars.addAll((map['unlockedAvatars'] as List).cast<String>());
      _unlockedAvatars.add(AppConstants.defaultAvatarId);
    }

    _unlockedLevelId = map['unlockedLevelId'] as int? ?? 1;

    if (map['levelStars'] is Map) {
      final stars = map['levelStars'] as Map<String, dynamic>;
      _levelStars.clear();
      stars.forEach((k, v) {
        final intKey = int.tryParse(k);
        if (intKey != null && v is int) {
          _levelStars[intKey] = v;
        }
      });
    }

    _languageCode = map['languageCode'] as String? ?? AppConstants.defaultLanguageCode;

    if (map['dailyCompletedDates'] is List) {
      _dailyCompletedDates.clear();
      _dailyCompletedDates.addAll((map['dailyCompletedDates'] as List).cast<String>());
    }

    if (map['openedChestIds'] is List) {
      _openedChestIds.clear();
      _openedChestIds.addAll((map['openedChestIds'] as List).cast<String>());
    }

    if (map['customLevels'] is List) {
      _customLevels.clear();
      _customLevels.addAll(
        (map['customLevels'] as List).whereType<Map<String, dynamic>>(),
      );
    }
  }

  Future<void> saveAgeMode(AgeMode mode) async {
    _ageMode = mode;
    _hasSelectedAge = true;
    await _persist();
  }

  Future<void> saveAvatar(String id) async {
    _avatarId = id;
    _unlockedAvatars.add(id);
    await _persist();
  }

  Future<void> unlockAvatar(String id) async {
    _unlockedAvatars.add(id);
    await _persist();
  }

  Future<void> saveLevelProgress(int levelId, int stars) async {
    if (levelId + 1 > _unlockedLevelId) {
      _unlockedLevelId = levelId + 1;
    }
    final prev = _levelStars[levelId] ?? 0;
    if (stars > prev) {
      _levelStars[levelId] = stars;
    }
    await _persist();
  }

  Future<void> saveLanguageCode(String code) async {
    _languageCode = code;
    await _persist();
  }

  Future<void> markDailyChallengeCompleted(String dateKey) async {
    _dailyCompletedDates.add(dateKey);
    await _persist();
  }

  bool isDailyChallengeCompleted(String dateKey) {
    return _dailyCompletedDates.contains(dateKey);
  }

  Future<void> openChest(String chestId) async {
    _openedChestIds.add(chestId);
    await _persist();
  }

  bool isChestOpened(String chestId) {
    return _openedChestIds.contains(chestId);
  }

  Future<void> saveCustomLevel(Map<String, dynamic> levelJson) async {
    _customLevels.removeWhere((l) => l['id'] == levelJson['id']);
    _customLevels.add(levelJson);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final map = {
        'hasSelectedAge': _hasSelectedAge,
        'ageModeIndex': _ageMode.index,
        'avatarId': _avatarId,
        'unlockedAvatars': _unlockedAvatars.toList(),
        'unlockedLevelId': _unlockedLevelId,
        'levelStars': _levelStars.map((k, v) => MapEntry(k.toString(), v)),
        'languageCode': _languageCode,
        'dailyCompletedDates': _dailyCompletedDates.toList(),
        'openedChestIds': _openedChestIds.toList(),
        'customLevels': _customLevels,
      };
      final jsonString = jsonEncode(map);

      // 1. SharedPreferences (Permanent on Android, iOS, Web)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonString);

      // 2. Desktop file fallback
      final file = _getFallbackDesktopFile();
      if (file != null) {
        await file.writeAsString(jsonString);
      }
    } catch (e) {
      debugPrint('StorageService persist error: $e');
    }
  }

  @visibleForTesting
  void resetForTesting({
    bool hasSelectedAge = false,
    AgeMode ageMode = AgeMode.explorer,
    String avatarId = AppConstants.defaultAvatarId,
    int unlockedLevelId = 1,
    Map<int, int>? levelStars,
    String languageCode = AppConstants.defaultLanguageCode,
  }) {
    _initialized = true;
    _hasSelectedAge = hasSelectedAge;
    _ageMode = ageMode;
    _avatarId = avatarId;
    _unlockedAvatars
      ..clear()
      ..add(avatarId);
    _unlockedLevelId = unlockedLevelId;
    _levelStars
      ..clear()
      ..addAll(levelStars ?? {});
    _languageCode = languageCode;
    _dailyCompletedDates.clear();
    _openedChestIds.clear();
    _customLevels.clear();
  }
}
