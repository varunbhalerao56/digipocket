part of 'shared_items_view.dart';

// ============================================================================
// Bottom Filter Sheet
// ============================================================================

class _BottomFilterSheet extends StatelessWidget {
  final DraggableScrollableController sheetController;
  final FocusNode searchFocusNode;
  final double collapsedSize;
  final double maxSize;
  final TextEditingController searchController;
  final ValueNotifier<SharedItemType?> selectedType;
  final ValueNotifier<UserTopic?> selectedTopic;
  final ValueNotifier<bool> applyFilters;
  final UserTopicState userTopicState;
  final bool keywordOnlySearch;

  const _BottomFilterSheet({
    required this.sheetController,
    required this.searchController,
    required this.searchFocusNode,
    required this.collapsedSize,
    required this.maxSize,
    required this.selectedType,
    required this.selectedTopic,
    required this.applyFilters,
    required this.userTopicState,
    required this.keywordOnlySearch,
  });

  @override
  Widget build(BuildContext context) {
    final keywordValue = context.select<SharedItemsCubit, bool>(
      (cubit) => cubit.state is SharedItemsData ? (cubit.state as SharedItemsData).keywordSearch : false,
    );

    return SafeArea(
      child: Padding(
        padding: UIInsets.md,
        child: DraggableScrollableSheet(
          controller: sheetController,
          initialChildSize: collapsedSize.clamp(0.1, 1.0),
          minChildSize: collapsedSize.clamp(0.1, 1.0),
          maxChildSize: maxSize,
          snap: true,
          snapAnimationDuration: Duration(milliseconds: 100),
          snapSizes: [collapsedSize.clamp(0.1, 1.0), maxSize],
          builder: (context, scrollController) {
            return DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [BoxShadow(color: UIColors.primary.withAlpha(60), blurRadius: 30, offset: Offset(0, -2))],
              ),
              child: ClipRRect(
                borderRadius: UIRadius.lBorder,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    decoration: ShapeDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [UIColors.primary, UIColors.primary.withAlpha(245), UIColors.primary.withAlpha(235)],
                      ),
                      shape: UIRadius.mdShape,
                    ),
                    child: SingleChildScrollView(
                      physics: RangeMaintainingScrollPhysics(),
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Drag Handle
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: UISpacing.sm),
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: ShapeDecoration(
                                  color: UIColors.border,
                                  shape: RoundedSuperellipseBorder(borderRadius: UIRadius.mdBorder),
                                ),
                              ),
                            ),
                          ),
                          UIGap.sVertical(),

                          // Search Bar
                          Padding(
                            padding: UIInsets.horizontal,
                            child: CupertinoSearchTextField(
                              focusNode: searchFocusNode,
                              controller: searchController,
                              style: UITextStyles.body.copyWith(color: UIColors.background),
                              placeholder: "Search your baskets..",
                              cursorColor: UIColors.background.withAlpha(100),
                              placeholderStyle: UITextStyles.body.copyWith(color: UIColors.background.withAlpha(175)),
                              suffixIcon: Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: UIColors.background,
                                size: 20,
                              ),
                              onSuffixTap: () {
                                searchController.clear();
                                if (sheetController.isAttached) {
                                  context.read<SharedItemsCubit>().searchItems(
                                    typeFilter: selectedType.value,
                                    userTopic: selectedTopic.value,
                                    searchQuery: '',
                                  );

                                  sheetController.animateTo(
                                    collapsedSize,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                              suffixInsets: EdgeInsets.only(right: 0),
                              itemColor: UIColors.background,
                              decoration: BoxDecoration(borderRadius: UIRadius.mdBorder),
                              onSubmitted: (value) async {
                                if (sheetController.isAttached) {
                                  await context.read<SharedItemsCubit>().searchItems(
                                    typeFilter: selectedType.value,
                                    userTopic: selectedTopic.value,
                                    searchQuery: searchController.text.trim(),
                                  );
                                }
                              },
                              onTap: () {
                                if (sheetController.isAttached) {
                                  sheetController.animateTo(
                                    collapsedSize + collapsedSize,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                            ),
                          ),

                          UIGap.mdVertical(),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CupertinoListTile(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  'Search Options',
                                  style: UITextStyles.headline.copyWith(color: UIColors.background),
                                ),
                              ),
                              Padding(padding: UIInsets.horizontal, child: UIDivider.horizontalExtraThin),

                              UIGap.mdVertical(),
                              Container(
                                margin: UIInsets.horizontal,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    CupertinoFilterChip(
                                      label: "Keyword Only",
                                      selected: keywordValue,
                                      onSelected: () {
                                        context.read<SharedItemsCubit>().setKeywordSearch(!keywordValue);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          UIGap.sVertical(),
                          // Filter by Type Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CupertinoListTile(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  'Filter by Type',
                                  style: UITextStyles.headline.copyWith(color: UIColors.background),
                                ),
                                trailing: selectedType.value != null
                                    ? UIIconButton(
                                        size: 22,
                                        onPressed: () {
                                          selectedType.value = null;
                                        },
                                        icon: Icon(
                                          CupertinoIcons.clear_circled_solid,
                                          color: UIColors.background,
                                          size: 20,
                                        ),
                                      )
                                    : null,
                              ),
                              Padding(padding: UIInsets.horizontal, child: UIDivider.horizontalExtraThin),

                              UIGap.mdVertical(),

                              Container(
                                margin: UIInsets.horizontal,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (var category in SharedItemType.values)
                                      CupertinoFilterChip(
                                        label: category.toString(),
                                        selected: selectedType.value == category,
                                        onSelected: () {
                                          if (selectedType.value == category) {
                                            selectedType.value = null;
                                            return;
                                          } else {
                                            selectedType.value = category;
                                          }
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          UIGap.xsVertical(),

                          // Filter by Topic Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CupertinoListTile(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  'Filter by Basket',
                                  style: UITextStyles.headline.copyWith(color: UIColors.background),
                                ),
                                trailing: selectedTopic.value != null
                                    ? UIIconButton(
                                        size: 22,
                                        onPressed: () {
                                          selectedTopic.value = null;
                                        },
                                        icon: Icon(
                                          CupertinoIcons.clear_circled_solid,
                                          color: UIColors.background,
                                          size: 20,
                                        ),
                                      )
                                    : null,
                              ),
                              Padding(padding: UIInsets.horizontal, child: UIDivider.horizontalExtraThin),

                              UIGap.mdVertical(),
                              if (userTopicState is UserTopicLoaded &&
                                  (userTopicState as UserTopicLoaded).items.where((topic) => topic.isActive).isEmpty)
                                Padding(
                                  padding: UIInsets.horizontal,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: UITextButton(
                                      onPressed: () async {
                                        Navigator.of(context).push(
                                          CupertinoPageRoute(
                                            builder: (_) => BlocProvider.value(
                                              value: context.read<UserTopicsCubit>()..loadUserTopic(),
                                              child: UserTopicView(),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text("Add Basket"),
                                    ),
                                  ),
                                ),

                              Container(
                                margin: UIInsets.horizontal,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  children: [
                                    if (userTopicState is UserTopicLoaded) ...[
                                      for (var category in (userTopicState as UserTopicLoaded).items.where(
                                        (topic) => topic.isActive,
                                      ))
                                        CupertinoFilterChip(
                                          label: category.name,
                                          selected: selectedTopic.value?.id == category.id,
                                          onSelected: () {
                                            if (selectedTopic.value?.id == category.id) {
                                              selectedTopic.value = null;
                                              return;
                                            } else {
                                              selectedTopic.value = category;
                                            }
                                          },
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                              UIGap.mdVertical(),

                              // Apply Filters Button
                              if (selectedTopic.value != null || selectedType.value != null) ...[
                                Padding(padding: UIInsets.horizontal, child: UIDivider.horizontalExtraThin),

                                UIGap.mdVertical(),

                                Padding(
                                  padding: UIInsets.horizontal,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: UITextButton(
                                      onPressed: () async {
                                        if (applyFilters.value) {
                                          selectedType.value = null;
                                          selectedTopic.value = null;
                                          applyFilters.value = false;

                                          await context.read<SharedItemsCubit>().loadSharedItems();
                                        } else if (applyFilters.value == false &&
                                            (selectedType.value != null ||
                                                selectedTopic.value != null ||
                                                searchController.text.trim().isNotEmpty)) {
                                          applyFilters.value = true;

                                          await sheetController.animateTo(
                                            collapsedSize,
                                            duration: Duration(milliseconds: 300),
                                            curve: Curves.easeOutCubic,
                                          );

                                          print(
                                            'Applying Filters: '
                                            'Type=${selectedType.value}, '
                                            'Topic=${selectedTopic.value}, '
                                            'Query="${searchController.text.trim()}"',
                                          );
                                          if (context.mounted) {
                                            await context.read<SharedItemsCubit>().searchItems(
                                              typeFilter: selectedType.value,
                                              userTopic: selectedTopic.value,
                                              searchQuery: searchController.text.trim(),
                                            );
                                          }
                                        }
                                      },
                                      child: Text(
                                        selectedType.value == null && selectedTopic.value == null
                                            ? 'No Filters Applied'
                                            : applyFilters.value
                                            ? 'Clear Filters'
                                            : 'Apply Filters',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: UISpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
