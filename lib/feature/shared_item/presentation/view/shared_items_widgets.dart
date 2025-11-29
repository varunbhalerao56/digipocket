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

  const _ItemsGridView({required this.items, required this.topics});

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
                child: _ItemCard(item: item, topics: topics),
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

  const _ItemCard({required this.item, this.topics = const []});

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
              borderRadius: BorderRadius.circular(12),
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
            padding: EdgeInsets.only(left: 12, right: 12, top: showNoBasketTag ? 0 : 12, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.urlTitle != null)
                  Text(item.urlTitle!, style: UITextStyles.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  item.url!,
                  style: UITextStyles.body.copyWith(color: UIColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (item.urlDescription != null) ...[
                  const SizedBox(height: 4),
                  Text(item.urlDescription!, style: UITextStyles.body, maxLines: 3, overflow: TextOverflow.ellipsis),
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

          HapticFeedback.lightImpact();
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
