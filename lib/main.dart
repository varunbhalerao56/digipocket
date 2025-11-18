import 'dart:io';

import 'package:digipocket/feature/fonnex/data/repository/fonnex_embedding_repository.dart';
import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/generated/tokenizer_bridge/frb_generated.dart';
import 'package:digipocket/global/db/app.dart';
import 'package:digipocket/global/helpers/fonnex.dart';
import 'package:digipocket/global/themes/themes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

// class AppServices {
//   static final EmbeddingService embeddingService = EmbeddingService.nomic();
//
//   // Initialize on app startup
//   static Future<void> initialize() async {
//     await embeddingService.initializeText();
//     await embeddingService.initializeVision();
//     // Only init vision if you need images immediately
//     // await embeddingService.initializeVision();
//   }
// }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await RustLib.init();
  final database = await AppDatabase.create();

  runApp(MyApp(database: database));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;

  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<ShareQueueDataSource>(create: (context) => ShareQueueDataSource()),
      ],
      child: BlocProvider(
        create: (context) => FonnexCubit()..init(),
        child: MaterialApp(title: 'DigiPocket', theme: AppTheme.lightTheme, home: const _AppHome()),
      ),
    );
  }
}

class _AppHome extends StatelessWidget {
  const _AppHome();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FonnexCubit, FonnexState>(
      builder: (context, state) {
        // Show loading while embedding model initializes
        if (state is FonnexInitial || state is FonnexLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Show error
        if (state is FonnexError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Failed to initialize embedding model', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(state.exception.message),
                ],
              ),
            ),
          );
        }

        // FonnexDataLoaded - build repositories and main app
        final embeddingRepo = (state as FonnexDataLoaded).repository;

        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<FonnexEmbeddingRepository>.value(value: embeddingRepo),
            RepositoryProvider<UserTopicRepository>(
              create: (context) => UserTopicRepository(
                database: context.read<AppDatabase>().topicDb,
                embeddingRepository: embeddingRepo,
              ),
            ),
            RepositoryProvider<SharedItemRepository>(
              create: (context) => SharedItemRepository(
                database: context.read<AppDatabase>().itemDb,
                userTopicRepository: context.read<UserTopicRepository>(),
                embeddingRepository: embeddingRepo,
                shareQueueDataSource: context.read<ShareQueueDataSource>(),
              ),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (context) => SharedItemsCubit(repository: context.read<SharedItemRepository>())
                  ..processQueue()
                  ..loadSharedItems(),
              ),
            ],
            child: const AppLifecycleWrapper(child: SharedItemView(title: 'DigiPocket')),
          ),
        );
      },
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
