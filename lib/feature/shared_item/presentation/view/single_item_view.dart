part of 'shared_items_view.dart';

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

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
          userCaption: userThoughts.text,
        );

        await itemsCubit.updateItem(updatedItem);
        if (context.mounted) {
          showCupertinoSnackbar(context, 'Item saved successfully');
        }
        // Show success feedback
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (!context.mounted) {
          return;
        }

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
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) =>
                            FullScreenImageView(imagePath: item.imagePath!, heroTag: 'shared_item_image_${item.id}'),
                      ),
                    );
                  },
                  child: Hero(
                    tag: 'shared_item_image_${item.id}',
                    child: ClipRSuperellipse(
                      borderRadius: UIRadius.mdBorder,
                      child: Image.file(File(item.imagePath!), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            );
          }
          return const Text('No image');

        case SharedItemType.text:
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(item.text ?? "", style: UITextStyles.body),
            ),
          );

        case SharedItemType.url:
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.urlThumbnailPath != null && item.urlThumbnailPath != "") ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (_) => FullScreenImageView(
                                      imagePath: item.urlThumbnailPath!,
                                      heroTag: "shared_item_link_image_${item.id}",
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: "shared_item_link_image_${item.id}",
                                child: ClipRSuperellipse(
                                  borderRadius: UIRadius.smBorder,
                                  child: SizedBox(
                                    height: 80, // Fixed height
                                    child: Image.file(File(item.urlThumbnailPath!), fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            ),
                            UIGap.mdHorizontal(),
                            SizedBox(height: 80, child: UIDivider.verticalExtraThin),
                            UIGap.mdHorizontal(),

                            if (item.urlTitle != null)
                              Expanded(child: SelectableText(item.urlTitle!, style: UITextStyles.bodyBold)),
                          ],
                        ),
                        UIGap.sVertical(),
                      ] else if (item.urlTitle != null)
                        SelectableText(item.urlTitle!, style: UITextStyles.bodyBold),
                      const SizedBox(height: 4),
                      Text(
                        item.url!,
                        style: UITextStyles.body.copyWith(color: UIColors.secondary),
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (item.urlDescription != null) ...[
                        const SizedBox(height: 4),
                        SelectableText(
                          item.urlDescription!,
                          style: UITextStyles.body,

                          // overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.antiAlias,
              slivers: [
                CupertinoSliverNavigationBar(
                  backgroundColor: UIColors.background,
                  largeTitle: Image.asset(kAppLogo, height: 36),
                  previousPageTitle: "Home",
                  heroTag: 'home_nav_bar',
                  trailing: watchCubit.state is! SharedItemsLoading
                      ? UIIconButton(
                          icon: const Icon(CupertinoIcons.delete_solid, color: UIColors.error),
                          onPressed: () async {
                            await itemsCubit.deleteItem(item.id);
                            if (context.mounted) {
                              showCupertinoSnackbar(context, 'Item deleted');
                              Navigator.pop(context);
                            }
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

                                    final launchSucceeded = await launchUrl(
                                      Uri.parse(item.url!),
                                      mode: LaunchMode.externalNonBrowserApplication,
                                    );

                                    if (!launchSucceeded) {
                                      await launchUrl(Uri.parse(item.url!), mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: Icon(CupertinoIcons.link),
                                ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: Text(
                                  "Shared on ${DateFormat('yy/MM/dd, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(item.createdAt))}",
                                  textAlign: TextAlign.end,
                                  style: UITextStyles.captionSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        UIGap.mdVertical(),

                        if (item.contentType == SharedItemType.image)
                          Container(
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: ShapeDecoration(
                              shape: UIRadius.mdShape.copyWith(
                                side: item.contentType == SharedItemType.image
                                    ? null
                                    : BorderSide(color: UIColors.border),
                              ),
                              color: item.contentType == SharedItemType.image ? UIColors.card : UIColors.background,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: buildContent(item),
                            ),
                          )
                        else
                          ExpandableContainer(
                            collapsedHeight: 250,
                            threshold: 240,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              shape: UIRadius.mdShape.copyWith(
                                side: item.contentType == SharedItemType.image
                                    ? null
                                    : BorderSide(color: UIColors.border),
                              ),
                              color: item.contentType == SharedItemType.image ? UIColors.card : UIColors.background,
                            ),
                            child: buildContent(item),
                          ),

                        // Topics Selection - Using filter chips
                        BlocBuilder<UserTopicsCubit, UserTopicState>(
                          builder: (context, state) {
                            List<UserTopic> activeTopics = [];

                            if (state is UserTopicLoaded) {
                              activeTopics = state.items.where((t) => t.isActive).toList();
                            }

                            if (activeTopics.isEmpty) {
                              return Padding(
                                padding: EdgeInsets.only(left: UISpacing.md, right: UISpacing.md, top: UISpacing.md),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.card),
                                  child: Column(
                                    children: [
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
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  UIGap.mdVertical(),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: ShapeDecoration(
                                          shape: UIRadius.mdShape.copyWith(
                                            side: BorderSide(color: UIColors.border, width: 0.25),
                                          ),
                                          color: UIColors.background,
                                        ),
                                        child: Text(
                                          'Baskets (${selectedTopics.value.length})',
                                          style: UITextStyles.bodyBold,
                                        ),
                                      ),

                                      SizedBox(height: 40, child: UIDivider.verticalExtraThin),

                                      ...activeTopics.map((topic) {
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
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        UIGap.mdVertical(),

                        Padding(padding: UIInsets.horizontal, child: UIDivider.horizontalExtraThin),

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
                                maxLines: 2,
                                style: UITextStyles.body,
                                placeholder: "Why did you share this?",
                                textInputAction: TextInputAction.done,
                                decoration: BoxDecoration(borderRadius: UIRadius.mdBorder),
                              ),
                            ),
                          ),
                        ),
                        UIGap.xlVertical(),
                        UIGap.xlVertical(),
                        UIGap.xlVertical(),
                        UIGap.xlVertical(),
                        UIGap.xlVertical(),
                      ]),
                    );
                  },
                ),
              ],
            ),

            if (bottomInset < 100)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<SharedItemsCubit, SharedItemsState>(
                  builder: (context, state) {
                    if (state is SharedItemsLoading) {
                      return SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
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
                          height: 24,
                        ),
                        Container(
                          color: UIColors.background,
                          child: SafeArea(
                            top: false,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: UIInsets.horizontal,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: UIPrimaryButton(onPressed: saveItem, child: const Text('Save')),
                                  ),
                                ),
                                UIGap.mdVertical(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
