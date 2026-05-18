import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalUserService {
  static const _key = 'anonymous_user_id';

  // Call this on app start
  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_key);

    if (userId == null) {
      userId = const Uuid().v4(); // ✅ generate once
      await prefs.setString(_key, userId);
    }

    return userId; // always same ID on same device
  }
}
