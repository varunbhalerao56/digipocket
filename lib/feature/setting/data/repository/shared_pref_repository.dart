import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefRepository {
  final SharedPreferences sharedPreferences;

  SharedPrefRepository({required this.sharedPreferences});

  double getTextEmbeddingMatcher() {
    return sharedPreferences.getDouble('textEmbeddingMatcher') ?? 0.42;
  }

  double getImageEmbeddingMatcher() {
    return sharedPreferences.getDouble('imageEmbeddingMatcher') ?? 0.99;
  }

  double getCombinedEmbeddingMatcher() {
    return sharedPreferences.getDouble('combinedEmbeddingMatcher') ?? 0.64;
  }

  Future<void> setTextEmbeddingMatcher(double value) async {
    await sharedPreferences.setDouble('textEmbeddingMatcher', value);
  }

  Future<void> setImageEmbeddingMatcher(double value) async {
    await sharedPreferences.setDouble('imageEmbeddingMatcher', value);
  }

  Future<void> setCombinedEmbeddingMatcher(double value) async {
    await sharedPreferences.setDouble('combinedEmbeddingMatcher', value);
  }
}
