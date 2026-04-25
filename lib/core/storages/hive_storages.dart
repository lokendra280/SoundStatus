import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<bool>('onboarding');
    await Hive.openBox<bool>('language');
  }

  Future<bool> checkOnboardingCompleted() async {
    await Hive.openBox<bool>('onboarding');
    final box = Hive.box<bool>('onboarding');
    return box.get('completed', defaultValue: false)!;
  }

  Future<void> markOnboardingCompleted() async {
    await Hive.openBox<bool>('onboarding');
    final box = Hive.box<bool>('onboarding');
    await box.put('completed', true);
  }

  Future<bool> checkLanguageSelected() async {
    await Hive.openBox<bool>('language');
    final box = Hive.box<bool>('language');
    return box.get('selected', defaultValue: false)!;
  }

  Future<void> markLanguageSelected() async {
    final box = Hive.box<bool>('language');
    await box.put('selected', true);
  }
}
