// The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.

// import 'dart:io';
//
// import 'package:digipocket/feature/shared_items/shared_items.dart';
// import 'package:digipocket/helpers/fonnex.dart';
// import 'package:digipocket/theme/themes.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Test ONNX model loading
//   print('🚀 Starting ONNX Runtime test...');
//
//   final embeddingService = EmbeddingService();
//
//   try {
//     await embeddingService.initialize();
//     print('✅ Test passed!');
//   } catch (e) {
//     print('❌ Test failed: $e');
//   }
//
//   // Initialize database
//   final database = await AppDatabase.create();
//
//   // Initialize datasource
//   final queueDataSource = ShareQueueDataSource();
//
//   // Initialize repository
//   final sharedItemsRepository = SharedItemsRepository(database: database, shareQueueDataSource: queueDataSource);
//
//   runApp(MyApp(database: database, sharedItemsRepository: sharedItemsRepository));
// }
//
// class MyApp extends StatelessWidget {
//   final AppDatabase database;
//   final SharedItemsRepository sharedItemsRepository;
//
//   const MyApp({super.key, required this.database, required this.sharedItemsRepository});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiRepositoryProvider(
//       providers: [
//         RepositoryProvider<AppDatabase>.value(value: database),
//         RepositoryProvider<SharedItemsRepository>.value(value: sharedItemsRepository),
//       ],
//       child: MultiBlocProvider(
//         providers: [
//           BlocProvider(
//             create: (context) => SharedItemsCubit(repository: sharedItemsRepository)
//               ..processQueue()
//               ..loadSharedItems(),
//           ),
//         ],
//         child: MaterialApp(
//           title: 'DigiPocket',
//           theme: AppTheme.lightTheme,
//           home: const AppLifecycleWrapper(child: MyHomePage(title: 'DigiPocket')),
//         ),
//       ),
//     );
//   }
// }
//
// // Wrapper to handle app lifecycle
// class AppLifecycleWrapper extends StatefulWidget {
//   final Widget child;
//
//   const AppLifecycleWrapper({super.key, required this.child});
//
//   @override
//   State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
// }
//
// class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       // App came back to foreground - process queue
//       context.read<SharedItemsCubit>().processQueue();
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
//
// class MyHomePage extends HookWidget {
//   final String title;
//
//   const MyHomePage({super.key, required this.title});
//
//   @override
//   Widget build(BuildContext context) {
//     final statusBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;
//
//     Widget buildContent(DigipocketItem item) {
//       switch (item.contentType) {
//         case DigipocketItemType.image:
//           if (item.imagePath != null) {
//             return ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.file(File(item.imagePath!), fit: BoxFit.cover, width: double.infinity),
//             );
//           }
//           return const Text('No image available');
//
//         case DigipocketItemType.text:
//           return Padding(
//             padding: const EdgeInsets.all(12),
//             child: Text(
//               item.text ?? 'No content',
//               maxLines: 8,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           );
//
//         case DigipocketItemType.url:
//           if (item.url != null) {
//             return Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (item.urlTitle != null)
//                     Text(
//                       item.urlTitle!,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   const SizedBox(height: 4),
//                   Text(
//                     item.url!,
//                     style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             );
//           }
//           return const Text('No URL available');
//       }
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(title),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.delete_sweep),
//             onPressed: () {
//               context.read<SharedItemsCubit>().clearAll();
//             },
//             tooltip: 'Clear All',
//           ),
//         ],
//       ),
//       body: BlocBuilder<SharedItemsCubit, SharedItemsState>(
//         builder: (context, state) {
//           if (state is SharedItemsLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (state is SharedItemsError) {
//             return Center(child: Text('Error: ${state.message}'));
//           }
//
//           if (state is SharedItemsLoaded) {
//             if (state.items.isEmpty) {
//               return const Center(child: Text('No shared items yet!\nShare something to get started.'));
//             }
//
//             return ListView.builder(
//               itemCount: state.items.length,
//               padding: const EdgeInsets.all(16),
//               itemBuilder: (context, index) {
//                 final item = state.items[index];
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       buildContent(item),
//                       Padding(
//                         padding: const EdgeInsets.all(8),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Type: ${item.contentType.name}',
//                               style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete, size: 20),
//                               onPressed: () {
//                                 context.read<SharedItemsCubit>().deleteItem(item.id);
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           }
//
//           return const Center(child: Text('Welcome to DigiPocket!'));
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           context.read<SharedItemsCubit>().processQueue();
//         },
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:digipocket/src/rust/api/simple.dart';
import 'package:digipocket/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Center(
          child: Text(
            'Action: Call Rust `greet("Tom")`\nResult: `${greet(name: "Tom")}`',
          ),
        ),
      ),
    );
  }
}
