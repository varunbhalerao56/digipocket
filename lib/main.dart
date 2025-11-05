import 'dart:io';
import 'dart:ui';

import 'package:any_link_preview/any_link_preview.dart';
import 'package:digipocket/feature/llama_cpp/llama_cpp.dart';
import 'package:digipocket/feature/shared_items/shared_items.dart';
import 'package:digipocket/link_preview.dart';
import 'package:digipocket/llama_presets.dart';
import 'package:digipocket/llama_widget.dart';
import 'package:digipocket/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

void main() {
  // Initialize database
  final database = AppDatabase();

  // Initialize datasource
  final queueDataSource = ShareQueueDataSource();

  // Initialize repository
  final sharedItemsRepository = SharedItemsRepository(database: database, shareQueueDataSource: queueDataSource);

  runApp(MyApp(database: database, sharedItemsRepository: sharedItemsRepository));
}

class MyApp extends StatelessWidget {
  final AppDatabase database;
  final SharedItemsRepository sharedItemsRepository;

  const MyApp({super.key, required this.database, required this.sharedItemsRepository});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<SharedItemsRepository>.value(value: sharedItemsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => SharedItemsCubit(repository: sharedItemsRepository)..processQueue()),
        ],
        child: MaterialApp(
          title: 'DigiPocket',
          theme: AppTheme.lightTheme,
          home: const AppLifecycleWrapper(child: MyHomePage(title: 'DigiPocket')),
        ),
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

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LlamaParent? parent;
  ChatMLFormat? format;
  @override
  Widget build(BuildContext context) {
    const double _blurSigma = 8.0;
    final statusBarHeight = MediaQuery.viewInsetsOf(context).top + kToolbarHeight;

    Widget content(SharedItem item) {
      switch (item.type) {
        case 'image':
          if (item.imagePath != null) {
            return ClipRSuperellipse(
              borderRadius: UIRadius.mdBorder,
              child: Image.file(File(item.imagePath!), fit: BoxFit.cover, width: double.infinity),
            );
          } else {
            return const Text('No image available');
          }
        case 'text':
          return Padding(
            padding: UIInsets.sm,
            child: Text(
              item.content ?? 'No content',
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: UITextStyles.subheadlineBold,
            ),
          );
        case 'url':
          if (item.url == null) {
            return const Text('No URL available');
          } else {
            return LinkPreviewWidget(url: item.url!);
          }

        default:
          return const Text('Unknown item type');
      }
    }

    return Scaffold(
      body: BlocBuilder<SharedItemsCubit, SharedItemsState>(
        builder: (context, state) {
          if (state is SharedItemsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SharedItemsError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is SharedItemsLoaded) {
            if (state.items.isEmpty) {
              return const Center(child: Text('No shared items yet!'));
            }

            // return Center(
            //   child: TextButton(
            //     onPressed: () async {
            //       for (var items in state.items) {
            //         await context.read<SharedItemsCubit>().deleteItem(items.id);
            //       }
            //     },
            //     child: Text("Debug Button"),
            //   ),
            // );

            return CustomScrollView(
              cacheExtent: 1000,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  stretch: true,
                  centerTitle: false,
                  backgroundColor: UIColors.primary,
                  foregroundColor: UIColors.primary,
                  surfaceTintColor: Colors.transparent,
                  expandedHeight: 125.0,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.only(bottomLeft: UIRadius.md, bottomRight: UIRadius.md),
                  ),

                  title: Text(widget.title, style: UITextStyles.title1.copyWith(color: UIColors.background)),

                  flexibleSpace: ClipRSuperellipse(
                    child: FlexibleSpaceBar(
                      background: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(height: statusBarHeight + UISpacing.md * 2),

                          Container(
                            decoration: ShapeDecoration(
                              color: UIColors.primary,
                              shape: RoundedSuperellipseBorder(
                                borderRadius: BorderRadius.only(bottomLeft: UIRadius.md, bottomRight: UIRadius.md),
                              ),
                            ),
                            child: Padding(
                              padding: UIInsets.md,
                              child: ClipRSuperellipse(
                                borderRadius: UIRadius.mdBorder,
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    fillColor: UIColors.card,
                                    filled: true,
                                    hintText: "Search your pocket...",
                                  ),
                                  // decoration: UIInputDecoration.defaultStyle(
                                  //   hintText: "Search your pocket...",
                                  //   // suffixIcon: Icons.filter_list_alt,
                                  // ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // bottom: ,
                ),

                // if (parent != null && format != null)
                //   SliverToBoxAdapter(
                //     child: Padding(
                //       padding: const EdgeInsets.all(12),
                //       child: LlamaChatPanel(
                //         llamaParent: parent!,
                //
                //         systemPrompt: "You are a concise, helpful assistant.",
                //         addGenerationPrompt: true,
                //       ),
                //     ),
                //   ),
                // SliverToBoxAdapter(
                //   child: Row(
                //     children: [
                //       ElevatedButton(
                //         onPressed: () async {
                //           try {
                //             // Get the model path
                //             final modelPath = await LlamaPresets.materializeModel();
                //
                //             setState(() {
                //               format = ChatMLFormat();
                //             });
                //
                //             final loadCommand = LlamaLoad(
                //               path: modelPath,
                //               modelParams: LlamaPresets.modelDevice(),
                //               contextParams: LlamaPresets.ctxDevice(),
                //               samplingParams: LlamaPresets.samplerDeviceBalanced(),
                //               format: format,
                //               // verbose: true,
                //             );
                //
                //             final llamaParent = LlamaParent(loadCommand);
                //
                //             setState(() {
                //               parent = llamaParent;
                //             });
                //
                //             await parent?.init();
                //
                //             // llamaParent.stream.listen((response) => print(response));
                //             // llamaParent.sendPrompt(format.preparePrompt("Hi"));
                //           } catch (e) {
                //             print('Error: $e');
                //           }
                //         },
                //         child: Text("Test LLM"),
                //       ),
                //     ],
                //   ),
                // ),
                SliverPadding(
                  padding: UIInsets.md,
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: UISpacing.sm,
                    mainAxisSpacing: UISpacing.sm,
                    childCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];

                      return Card(
                        shape: UIRadius.mdShape,
                        shadowColor: Theme.of(context).colorScheme.shadow.withAlpha(5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            content(item),
                            if (item.sourceApp != "unknown")
                              Text(
                                item.sourceApp,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('Welcome to DigiPocket!'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // context.read<SharedItemsCubit>().processQueue();

          // print('Refreshing shared items...');
          //
          //
          // for (var items in (context.read<SharedItemsCubit>() as SharedItemsLoaded).items) {
          //   print('Deleting item id: ${items.id}');
          //   await context.read<SharedItemsCubit>().deleteItem(items.id);
          // }
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
