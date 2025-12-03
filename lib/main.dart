import 'package:digipocket/global/constants/constants.dart';
import 'package:digipocket/global/db/app.dart';
import 'package:digipocket/app.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final database = await AppDatabase.create();

  SharedPreferences sharedPreference = await SharedPreferences.getInstance();

  if (!sharedPreference.containsKey('textEmbeddingMatcher')) {
    await sharedPreference.setDouble('textEmbeddingMatcher', kdefaultTextEmbeddingMatcher);
  }
  if (!sharedPreference.containsKey('imageEmbeddingMatcher')) {
    await sharedPreference.setDouble('imageEmbeddingMatcher', kdefaultImageEmbeddingMatcher);
  }
  if (!sharedPreference.containsKey('combinedEmbeddingMatcher')) {
    await sharedPreference.setDouble('combinedEmbeddingMatcher', kdefaultCombinedEmbeddingMatcher);
  }

  if (!sharedPreference.containsKey('keywordMatcher')) {
    await sharedPreference.setBool('keywordMatcher', kdefaultKeywordMatcher);
  }
  if (!sharedPreference.containsKey('maxTags')) {
    await sharedPreference.setInt('maxTags', kdefaultMaxTags);
  }

  runApp(MyApp(database: database, sharedPreferences: sharedPreference));
}
