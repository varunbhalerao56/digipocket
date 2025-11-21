part of 'shared_items_view.dart';

// ============================================================================
// Navigation Bar
// ============================================================================

class _AppNavigationBar extends StatelessWidget {
  const _AppNavigationBar();

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverNavigationBar(
      backgroundColor: UIColors.background,
      largeTitle: Image.asset('assets/app.png', height: 36),
      stretch: true,
      border: null,

      trailing: UIIconButton(
        onPressed: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) =>
                  BlocProvider.value(value: context.read<UserTopicsCubit>()..loadUserTopic(), child: UserTopicView()),
            ),
          );
        },
        icon: Icon(CupertinoIcons.square_grid_2x2),
      ),
    );
  }
}

// ============================================================================
// Gradient Header
// ============================================================================

class _GradientHeader extends StatelessWidget {
  const _GradientHeader();

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
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
    );
  }
}

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
  final List<dynamic> items;

  const _ItemsGridView({required this.items});

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
              return StaggeredGridTile.fit(crossAxisCellCount: 1, child: _ItemCard(item: item));
            }).toList(),
          ),
        ]),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final dynamic item;

  const _ItemCard({required this.item});

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
      child: _SharedItemCard(item: item),
    );
  }
}

class _SharedItemCard extends StatelessWidget {
  final SharedItem item; // Replace with your actual type

  const _SharedItemCard({required this.item});

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
          // Content
          buildContent(item),
        ],
      ),
    );
  }

  Widget buildContent(SharedItem item) {
    switch (item.contentType) {
      case SharedItemType.image:
        if (item.imagePath != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(item.imagePath!), fit: BoxFit.cover),
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
            textAlign: TextAlign.start,
            style: UITextStyles.body,
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
      onTap: widget.onTap,
      onLongPressStart: (_) {
        setState(() => _isPressed = true);
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
