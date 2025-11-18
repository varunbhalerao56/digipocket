import 'dart:io';

import 'package:digipocket/feature/fonnex/fonnex.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/global/helpers/fonnex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SharedItemView extends HookWidget {
  final String title;

  const SharedItemView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top + kToolbarHeight;

    Widget buildContent(SharedItem item) {
      switch (item.contentType) {
        case SharedItemType.image:
          if (item.imagePath != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(item.imagePath!), fit: BoxFit.cover, width: double.infinity),
            );
          }
          return const Text('No image available');

        case SharedItemType.text:
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              item.text ?? 'No content',
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );

        case SharedItemType.url:
          if (item.url != null) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.urlTitle != null)
                    Text(
                      item.urlTitle!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    item.url!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }
          return const Text('No URL available');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              context.read<SharedItemsCubit>().clearAll();
            },
            tooltip: 'Clear All',
          ),
        ],
      ),
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
              return Center(child: Image.asset('assets/cat.jpg'));

              return const Center(child: Text('No shared items yet!\nShare something to get started.'));
            }

            return ListView.builder(
              itemCount: state.items.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildContent(item),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Type: ${item.contentType.name}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () {
                                context.read<SharedItemsCubit>().deleteItem(item.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return const Center(child: Text('Welcome to DigiPocket!'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final embedder = FonnexEmbeddingRepository.nomic();
          await embedder.initializeText();
          await embedder.initializeVision();

          final vectorText = await embedder.generateTextEmbedding("test", task: NomicTask.searchDocument);

          print('Generated embedding vector: $vectorText');

          final vectorImage = await embedder.generateImageEmbedding("assets/cat.jpg");

          print('Generated embedding vector: $vectorImage');

          // context.read<SharedItemsCubit>().processQueue();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
