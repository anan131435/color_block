import 'package:shared_preferences/shared_preferences.dart';

class PrefsManager {
  static const String _keyHighScore = 'high_score';
  static const String _keyStreak = 'current_streak';
  static const String _keyLastPlayedDate = 'last_played_date'; // YYYY-MM-DD

  // High Score Methods
  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyHighScore) ?? 0;
  }

  static Future<void> saveHighScore(int score) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt(_keyHighScore) ?? 0;
    if (score > currentHigh) {
      await prefs.setInt(_keyHighScore, score);
    }
  }

  // Streak Methods
  static Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStreak) ?? 0;
  }

  // Call this when the user starts a game
  static Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = _formatDate(now);

    final lastPlayedStr = prefs.getString(_keyLastPlayedDate);
    final currentStreak = prefs.getInt(_keyStreak) ?? 0;

    if (lastPlayedStr == null) {
      // First time playing
      await prefs.setString(_keyLastPlayedDate, todayStr);
      await prefs.setInt(_keyStreak, 1);
      return;
    }

    if (lastPlayedStr == todayStr) {
      // Already played today, do nothing
      return;
    }

    final lastPlayedDate = DateTime.parse(lastPlayedStr);

    // Calculate difference in days by stripping time
    final todayDate = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      lastPlayedDate.year,
      lastPlayedDate.month,
      lastPlayedDate.day,
    );
    final dayDiff = todayDate.difference(lastDate).inDays;

    if (dayDiff == 1) {
      // Consecutive day
      await prefs.setInt(_keyStreak, currentStreak + 1);
    } else {
      // Missed a day or more, reset to 1
      await prefs.setInt(_keyStreak, 1);
    }

    await prefs.setString(_keyLastPlayedDate, todayStr);
  }

  static String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
