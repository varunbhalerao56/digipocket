part of 'shared_items_view.dart';

// ============================================================================
// Navigation Bar
// ============================================================================

class AnimatedProcessingBanner extends HookWidget {
  final String text;
  final TextStyle? style;

  const AnimatedProcessingBanner({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(duration: const Duration(milliseconds: 1000));

    final scaleAnimation = useMemoized(
      () => Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
      [controller],
    );

    useEffect(() {
      controller.repeat(reverse: true);
      return controller.dispose;
    }, []);

    return ScaleTransition(
      scale: scaleAnimation,
      child: Text(text, style: style),
    );
  }
}

// ============================================================================
// Gradient Header
// ============================================================================

class _GradientHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Gradient gradient;

  _GradientHeaderDelegate({required this.height, required this.gradient});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return IgnorePointer(
      child: Container(decoration: BoxDecoration(gradient: gradient)),
    );
  }

  @override
  bool shouldRebuild(_GradientHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || gradient != oldDelegate.gradient;
  }
}

// ============================================================================
// Shared Item Card
// ============================================================================

class _ItemsGridView extends StatelessWidget {
  final List<SharedItem> items;
  final List<UserTopic> topics;
  final FocusNode searchFocusNode;

  const _ItemsGridView({required this.items, required this.topics, required this.searchFocusNode});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          StaggeredGrid.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: items.map((item) {
              return StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: _ItemCard(item: item, topics: topics, searchFocusNode: searchFocusNode),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final SharedItem item;
  final List<UserTopic> topics;
  final FocusNode searchFocusNode;

  const _ItemCard({required this.item, this.topics = const [], required this.searchFocusNode});

  List<String> filterTagsByUserTopics(List<String> tags, List<UserTopic> userTopics) {
    // Create a Set of lowercase topic names for fast lookup
    final topicNames = userTopics.map((topic) => topic.name.toLowerCase()).toSet();

    // Return only tags that exist in user topics (case-insensitive)
    return tags.where((tag) => topicNames.contains(tag.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return _AnimatedPressableCard(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (_) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider<SharedItemsCubit>.value(value: context.read<SharedItemsCubit>()),
                  BlocProvider<UserTopicsCubit>.value(value: context.read<UserTopicsCubit>()),
                ],
                child: SingleItemView(item: item),
              );
            },
          ),
        );
      },
      onLongPress: () {
        searchFocusNode.unfocus();

        final cubit = context.read<SharedItemsCubit>();

        showCupertinoModalPopup(
          context: context,
          builder: (BuildContext modalContext) => Padding(
            padding: const EdgeInsets.only(left: UISpacing.sm, right: UISpacing.sm, bottom: UISpacing.md),
            child: CupertinoActionSheet(
              actions: [
                CupertinoActionSheetAction(
                  onPressed: () async {
                    await ShareHelper.shareItem(item);

                    if (context.mounted) {
                      Navigator.of(modalContext).pop();
                    }
                  },
                  child: Text('Share'),
                ),

                CupertinoActionSheetAction(
                  onPressed: () async {
                    await ClipboardHelper.copyItem(item);

                    if (context.mounted) {
                      Navigator.of(modalContext).pop();
                      showCupertinoSnackbar(context, "Copied to clipboard");
                    }
                  },
                  child: Text('Copy to Clipboard'),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.of(modalContext).pop();
                  },
                  child: Text('Cancel'),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    cubit.deleteItem(item.id);
                    Navigator.of(modalContext).pop();
                  },
                  isDestructiveAction: true,
                  child: Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
      child: _SharedItemCard(item: item, showNoBasketTag: filterTagsByUserTopics(item.userTags ?? [], topics).isEmpty),
    );
  }
}

class _SharedItemCard extends StatelessWidget {
  final SharedItem item; // Replace with your actual type
  final bool showNoBasketTag;

  const _SharedItemCard({required this.item, required this.showNoBasketTag});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: UIColors.card,
        shape: RoundedSuperellipseBorder(borderRadius: UIRadius.mdBorder),
        // shadows: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 8, offset: const Offset(0, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showNoBasketTag) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: ShapeDecoration(
                color: UIColors.logo.withAlpha(150),
                shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text("No Basket", style: UITextStyles.captionBold.copyWith(color: UIColors.primary)),
            ),
          ],

          // Content
          buildContent(item, showNoBasketTag),

          // if (item.userTags != null && item.userTags!.isNotEmpty) ...[
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          //     child: Wrap(
          //       spacing: 6,
          //       runSpacing: 6,
          //       children: item.userTags!.map((tag) {
          //         return Container(
          //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //           decoration: ShapeDecoration(
          //             color: UIColors.primary.withAlpha(30),
          //             shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(8)),
          //           ),
          //           child: Text(tag, style: UITextStyles.caption.copyWith(color: UIColors.primary)),
          //         );
          //       }).toList(),
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }

  Widget buildContent(SharedItem item, bool showNoBasketTag) {
    switch (item.contentType) {
      case SharedItemType.image:
        if (item.imagePath != null) {
          return Hero(
            tag: 'shared_item_image_${item.id}',
            child: ClipRRect(
              borderRadius: UIRadius.mdBorder,
              child: Image.file(File(item.imagePath!), fit: BoxFit.cover),
            ),
          );
        }
        return const Text('No image available');

      case SharedItemType.text:
        return Padding(
          padding: EdgeInsets.only(left: 12, right: 12, top: showNoBasketTag ? 0 : 12, bottom: 12),
          child: Text(
            item.text ?? 'No content',
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
            style: UITextStyles.body,
          ),
        );

      case SharedItemType.url:
        if (item.url != null) {
          return Padding(
            padding: EdgeInsets.only(
              top: showNoBasketTag
                  ? 0
                  : item.urlThumbnailPath != null
                  ? 0
                  : 12,
              bottom: 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.urlThumbnailPath != null) ...[
                  Hero(
                    tag: "shared_item_link_image_${item.id}",
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(topLeft: UIRadius.md, topRight: UIRadius.md),
                      child: Image.file(File(item.urlThumbnailPath!), fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                if (item.urlTitle != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      item.urlTitle!,
                      style: UITextStyles.bodyBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    item.url!,
                    style: UITextStyles.body.copyWith(color: UIColors.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (item.urlDescription != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      item.urlDescription!,
                      style: UITextStyles.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return const Text('No URL available');
    }
  }
}

class _AnimatedPressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;

  const _AnimatedPressableCard({required this.child, required this.onLongPress, this.onTap});

  @override
  State<_AnimatedPressableCard> createState() => _AnimatedPressableCardState();
}

class _AnimatedPressableCardState extends State<_AnimatedPressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
      },

      onLongPressStart: (_) {
        setState(() => _isPressed = true);
        HapticFeedback.mediumImpact();
      },
      onLongPressEnd: (_) {
        setState(() => _isPressed = false);

        widget.onLongPress();
      },
      onLongPressCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 1.10 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class ExpandableContainer extends HookWidget {
  final Widget child;
  final double collapsedHeight;
  final double threshold;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final Clip clipBehavior;

  const ExpandableContainer({
    super.key,
    required this.child,
    this.collapsedHeight = 250,
    this.threshold = 240,
    this.margin,
    this.decoration,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState(false);
    final needsExpansion = useState(false);
    final contentKey = useMemoized(() => GlobalKey());

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final box = contentKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null && box.hasSize) {
          needsExpansion.value = box.size.height >= threshold;
        }
      });
      return null;
    }, []);

    return Container(
      clipBehavior: clipBehavior,
      margin: margin,
      decoration: decoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: isExpanded.value ? double.infinity : collapsedHeight),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: KeyedSubtree(key: contentKey, child: child),
            ),
          ),

          if (needsExpansion.value && !isExpanded.value)
            GestureDetector(
              onTap: () => isExpanded.value = true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Show more', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_more, size: 16, color: Colors.grey.shade600),
                  ],
                ),
              ),
            )
          else if (isExpanded.value)
            GestureDetector(
              onTap: () => isExpanded.value = false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Show less', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(width: 4),
                    Icon(Icons.expand_less, size: 16, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
