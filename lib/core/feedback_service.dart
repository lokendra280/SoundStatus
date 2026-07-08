import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackService {
  static const _boxName = 'feedback_prefs';
  static const _kLastPrompt = 'last_prompt_millis';
  static const _kHasReviewed = 'has_reviewed';
  static const _promptInterval = Duration(days: 7);

  static Future<Box> _box() async => Hive.isBoxOpen(_boxName)
      ? Hive.box(_boxName)
      : await Hive.openBox(_boxName);

  /// True once the user has been sent to the Play Store review flow.
  static Future<bool> hasReviewed() async {
    final box = await _box();
    return box.get(_kHasReviewed, defaultValue: false) == true;
  }

  /// True if it's time to show the weekly prompt.
  static Future<bool> shouldPrompt() async {
    final box = await _box();
    if (box.get(_kHasReviewed, defaultValue: false) == true) return false;

    final last = box.get(_kLastPrompt) as int?;
    if (last == null) return true;

    final elapsed = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(last),
    );
    return elapsed >= _promptInterval;
  }

  static Future<void> markPrompted() async {
    final box = await _box();
    await box.put(_kLastPrompt, DateTime.now().millisecondsSinceEpoch);
  }

  /// Call when user rates highly — triggers native Play Store review dialog
  /// and stops future prompts.
  static Future<void> requestStoreReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // Fallback: open the Play Store listing directly
      await inAppReview.openStoreListing();
    }
    final box = await _box();
    await box.put(_kHasReviewed, true);
  }

  /// Save written feedback to Supabase.
  static Future<void> submitFeedback({
    required int rating,
    String? message,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.from('user_feedback').insert({
      'user_id': supabase.auth.currentUser?.id,
      'rating': rating,
    'message': message,
    });
  }
}
