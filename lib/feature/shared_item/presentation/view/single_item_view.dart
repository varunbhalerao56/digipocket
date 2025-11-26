part of 'shared_items_view.dart';

const List<Widget> itemActionIcons = <Widget>[Icon(CupertinoIcons.archivebox_fill), Icon(CupertinoIcons.heart_fill)];

class SingleItemView extends HookWidget {
  final SharedItem item;

  const SingleItemView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final watchCubit = context.watch<SharedItemsCubit>();
    // Get dependencies from context
    final itemsCubit = context.read<SharedItemsCubit>();

    final text = useTextEditingController();
    final url = useTextEditingController();
    final userThoughts = useTextEditingController();

    final itemActions = useState<List<bool>>([item.isArchived, item.isFavorite]);
    final selectedTopics = useState<List<String>>([]);

    useEffect(() {
      if (item.contentType == SharedItemType.text && item.text != null) {
        text.text = item.text!;
      }
      if (item.contentType == SharedItemType.url && item.url != null) {
        url.text = item.url!;
      }

      if (item.userCaption != null) {
        userThoughts.text = item.userCaption!;
      }

      // Initialize selected topics from item's userTags
      if (item.userTags != null) {
        selectedTopics.value = List.from(item.userTags!);
      }

      return null;
    }, []);

    Future<void> saveItem() async {
      print('Saving item with topics: ${selectedTopics.value}');
      try {
        // Update item with current values
        final updatedItem = SharedItem(
          id: item.id,
          contentType: item.contentType,
          createdAt: item.createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          schemaVersion: item.schemaVersion,
          isFavorite: itemActions.value[1],
          isArchived: itemActions.value[0],
          sourceApp: item.sourceApp,
          vectorEmbedding: item.vectorEmbedding,
          generatedTags: item.generatedTags,
          summary: item.summary,
          summaryConfidence: item.summaryConfidence,
          tagConfidence: item.tagConfidence,
          userTags: selectedTopics.value,
          text: text.text.isNotEmpty ? text.text : item.text,
          url: url.text.isNotEmpty ? url.text : item.url,
          imagePath: item.imagePath,
          ocrText: item.ocrText,
          checksum: item.checksum,
          domain: item.domain,
          urlTitle: item.urlTitle,
          urlDescription: item.urlDescription,
          urlThumbnailPath: item.urlThumbnailPath,
          urlFaviconPath: item.urlFaviconPath,
          fileType: item.fileType,
          userCaption: userThoughts.text.isNotEmpty ? userThoughts.text : item.userCaption,
        );

        await itemsCubit.updateItem(updatedItem);
        showCupertinoSnackbar(context, 'Item saved successfully');
        // Show success feedback
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Show error feedback
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to save item: $e'),
            actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    }

    Widget buildContent(SharedItem item) {
      switch (item.contentType) {
        case SharedItemType.image:
          if (item.imagePath != null) {
            return ClipRRect(
              clipBehavior: Clip.antiAlias,
              borderRadius: UIRadius.mdBorder,
              child: Image.file(File(item.imagePath!), fit: BoxFit.contain),
            );
          }
          return const Text('No image available');

        case SharedItemType.text:
          return Padding(
            padding: const EdgeInsets.all(8),
            child: CupertinoTextField(
              controller: text,
              maxLines: null,
              style: UITextStyles.body,
              textInputAction: TextInputAction.done,
              decoration: BoxDecoration(borderRadius: UIRadius.mdBorder),
            ),
          );

        case SharedItemType.url:
          return Padding(
            padding: const EdgeInsets.all(8),
            child: CupertinoTextField(
              controller: url,
              maxLines: null,
              style: UITextStyles.body,
              textInputAction: TextInputAction.done,
              decoration: BoxDecoration(borderRadius: UIRadius.mdBorder),
            ),
          );
      }
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CupertinoPageScaffold(
        backgroundColor: UIColors.background,

        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.antiAlias,
                slivers: [
                  CupertinoSliverNavigationBar(
                    backgroundColor: UIColors.background,
                    largeTitle: Image.asset('assets/app.png', height: 36),
                    previousPageTitle: "Home",
                    trailing: watchCubit.state is! SharedItemsLoading
                        ? UIIconButton(
                            icon: const Icon(CupertinoIcons.delete_solid, color: UIColors.error),
                            onPressed: () async {
                              await itemsCubit.deleteItem(item.id);
                              Navigator.pop(context);
                            },
                          )
                        : null,
                    stretch: true,
                    border: null,
                  ),

                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _GradientHeaderDelegate(
                      height: 24,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          UIColors.background,
                          UIColors.background.withAlpha(250),
                          UIColors.background.withAlpha(235),
                          UIColors.background.withAlpha(209),
                          UIColors.background.withAlpha(173),
                          UIColors.background.withAlpha(122),
                          UIColors.background.withAlpha(71),
                          UIColors.background.withAlpha(31),
                          UIColors.background.withAlpha(10),
                        ],
                      ),
                    ),
                  ),

                  BlocBuilder<SharedItemsCubit, SharedItemsState>(
                    builder: (context, state) {
                      if (state is SharedItemsLoading) {
                        return _LoadingView(message: 'Saving item...');
                      }

                      return SliverList(
                        delegate: SliverChildListDelegate([
                          Padding(
                            padding: UIInsets.horizontal,
                            child: Row(
                              children: [
                                UIIconButton(
                                  onPressed: () async {
                                    await ShareHelper.shareItem(item);
                                  },
                                  icon: Icon(CupertinoIcons.share_solid),
                                ),
                                UIIconButton(
                                  onPressed: () async {
                                    await ClipboardHelper.copyItem(item);

                                    if (context.mounted) {
                                      showCupertinoSnackbar(context, "Copied to clipboard");
                                    }
                                  },
                                  icon: Icon(CupertinoIcons.doc_on_clipboard_fill),
                                ),
                                if (item.contentType == SharedItemType.url)
                                  UIIconButton(
                                    onPressed: () async {
                                      if (item.url == null) return;

                                      launchUrl(Uri.parse(item.url!), mode: LaunchMode.platformDefault);
                                    },
                                    icon: Icon(CupertinoIcons.link),
                                  ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Text(
                                    "Shared on ${DateFormat('yyyy-MM-dd – hh:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(item.createdAt))}",
                                    textAlign: TextAlign.end,
                                    style: UITextStyles.captionSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          UIGap.mdVertical(),
                          Container(
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.card),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 265),
                              child: buildContent(item),
                            ),
                          ),
                          UIGap.mdVertical(),
                          Container(
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.card),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 265),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: CupertinoTextField(
                                  controller: userThoughts,
                                  maxLines: 3,
                                  style: UITextStyles.body,
                                  placeholder: "Why did you share this?",
                                  textInputAction: TextInputAction.done,
                                  decoration: BoxDecoration(borderRadius: UIRadius.mdBorder),
                                ),
                              ),
                            ),
                          ),
                          UIGap.mdVertical(),
                          // Topics Selection - Using filter chips
                          BlocBuilder<UserTopicsCubit, UserTopicState>(
                            builder: (context, state) {
                              List<UserTopic> activeTopics = [];

                              if (state is UserTopicLoaded) {
                                activeTopics = state.items.where((t) => t.isActive).toList();
                              }

                              if (activeTopics.isEmpty) {
                                return Padding(
                                  padding: UIInsets.horizontal,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.card),
                                    child: Column(
                                      children: [
                                        Icon(CupertinoIcons.tray, size: 48, color: UIColors.secondary),
                                        UIGap.sVertical(),
                                        Text(
                                          'You have no baskets',
                                          style: UITextStyles.bodyBold,
                                          textAlign: TextAlign.center,
                                        ),
                                        UIGap.xsVertical(),
                                        Text(
                                          'Create a basket to organize your shared items',
                                          style: UITextStyles.captionSecondary,
                                          textAlign: TextAlign.center,
                                        ),
                                        UIGap.mdVertical(),
                                        UIPrimaryButton(
                                          onPressed: () {
                                            Navigator.of(context).pushReplacement(
                                              CupertinoPageRoute(
                                                builder: (_) => BlocProvider.value(
                                                  value: context.read<UserTopicsCubit>(),
                                                  // This context is from the outer scope
                                                  child: UserTopicView(),
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Create a Basket'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Padding(
                                padding: UIInsets.horizontal,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CupertinoListTile(
                                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                      title: Text(
                                        'Baskets',
                                        style: UITextStyles.headline.copyWith(color: UIColors.primary),
                                      ),
                                    ),
                                    UIDivider.horizontal,
                                    UIGap.mdVertical(),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: activeTopics.map((topic) {
                                        final isSelected = selectedTopics.value.contains(topic.name);
                                        return CupertinoFilterChipSecondary(
                                          label: topic.name,
                                          selected: isSelected,
                                          onSelected: () {
                                            if (isSelected) {
                                              selectedTopics.value = List.from(selectedTopics.value)
                                                ..remove(topic.name);
                                            } else {
                                              selectedTopics.value = List.from(selectedTopics.value)..add(topic.name);
                                            }
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          UIGap.mdVertical(),
                          // Add bottom padding for the fixed button
                          SizedBox(height: 80),
                        ]),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Fixed Save Button at bottom
            if (watchCubit.state is! SharedItemsLoading)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),

                  child: UIPrimaryButton(onPressed: saveItem, child: const Text('Save')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
