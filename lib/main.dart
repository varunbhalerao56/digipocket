import 'package:digipocket/feature/setting/data/repository/shared_pref_repository.dart';
import 'package:digipocket/feature/setting/presentation/cubit/settings_cubit.dart';
import 'package:digipocket/feature/shared_item/data/isolates/shared_item_isolate.dart';
import 'package:digipocket/feature/shared_item/data/repository/search_repository.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/db/app.dart';
import 'package:digipocket/global/themes/themes.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kdefaultTextEmbeddingMatcher = 0.40;
const kdefaultImageEmbeddingMatcher = 0.99;
const kdefaultCombinedEmbeddingMatcher = 0.61;
const kdefaultKeywordMatcher = true;
const kdefaultMaxTags = 1;

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // await RustLib.init();
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

class MyApp extends StatelessWidget {
  final AppDatabase database;
  final SharedPreferences sharedPreferences;

  const MyApp({super.key, required this.database, required this.sharedPreferences});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SharedPreferences>.value(value: sharedPreferences),
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<ShareQueueDataSource>(create: (context) => ShareQueueDataSource()),
        // Add the isolate manager as a repository provider
        RepositoryProvider<EmbeddingIsolateManager>(create: (context) => EmbeddingIsolateManager()),
      ],
      child: CupertinoApp(
        debugShowCheckedModeBanner: false,
        title: "Chuck'it",
        theme: AppTheme.cupertinoLightTheme,
        home: const _AppHome(),
      ),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  bool _isInitializing = true;
  String _initMessage = 'Hold on, getting your basket ready...';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final isolateManager = context.read<EmbeddingIsolateManager>();

    try {
      // Listen to initialization progress
      final subscription = isolateManager.responseStream.listen((response) {
        if (response is InitProgressResponse && mounted) {
          setState(() {
            _initMessage = response.message;
          });
        }
      });

      // Initialize the isolate
      await isolateManager.initialize();

      await subscription.cancel();

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        // Remove splash screen after successful init
        Future.delayed(const Duration(milliseconds: 500), () {
          FlutterNativeSplash.remove();
        });
      }
    } catch (e) {
      print('❌ Initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString();
        });
      }
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while initializing
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100, child: Image.asset("assets/loading2.gif")),
              UIGap.mdVertical(),
              Text(_initMessage, style: UITextStyles.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    // Show error
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to initialize', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              CupertinoButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isInitializing = true;
                    _initMessage = 'Retrying...';
                  });
                  _initializeApp();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Initialization complete - build the app
    final isolateManager = context.read<EmbeddingIsolateManager>();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SharedPrefRepository>(
          create: (context) => SharedPrefRepository(sharedPreferences: context.read<SharedPreferences>()),
        ),
        RepositoryProvider<UserTopicRepository>(
          create: (context) => UserTopicRepository(
            database: context.read<AppDatabase>().topicDb,
            embeddingIsolateManager: isolateManager,
          ),
        ),
        RepositoryProvider<SharedItemRepository>(
          create: (context) => SharedItemRepository(
            database: context.read<AppDatabase>().itemDb,
            userTopicRepository: context.read<UserTopicRepository>(),
            embeddingIsolateManager: isolateManager,
            shareQueueDataSource: context.read<ShareQueueDataSource>(),
            sharedPrefRepository: context.read<SharedPrefRepository>(),
          ),
        ),
        RepositoryProvider<SearchRepository>(
          create: (context) => SearchRepository(
            sharedItemRepository: context.read<SharedItemRepository>(),
            embeddingIsolateManager: isolateManager,
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => UserTopicsCubit(repository: context.read<UserTopicRepository>())..loadUserTopic(),
          ),
          BlocProvider(
            create: (context) =>
                SharedItemsCubit(
                    repository: context.read<SharedItemRepository>(),
                    searchRepository: context.read<SearchRepository>(),
                  )
                  ..processQueue()
                  ..loadSharedItems(),
          ),

          BlocProvider(
            create: (context) => SettingsCubit(
              sharedPrefRepository: context.read<SharedPrefRepository>(),
              userTopicsCubit: context.read<UserTopicsCubit>(),
              sharedItemsCubit: context.read<SharedItemsCubit>(),
            )..init(),
          ),
        ],
        child: const AppLifecycleWrapper(child: SharedItemView()),
      ),
    );
  }
}

// Wrapper to handle app lifecycle
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - process queue
      context.read<SharedItemsCubit>().processQueue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
