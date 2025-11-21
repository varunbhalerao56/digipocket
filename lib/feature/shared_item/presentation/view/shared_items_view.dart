import 'dart:io';
import 'dart:ui';

import 'package:digipocket/feature/shared_item/presentation/view/single_item_view.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/themes/themes.dart';
import 'package:digipocket/global/widgets/cupertino_buttons.dart';
import 'package:digipocket/global/widgets/cupertino_filter_chips.dart';
import 'package:digipocket/global/widgets/link_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

part 'shared_items_widgets.dart';
part 'shared_items_sheet.dart';

class SharedItemView extends HookWidget {
  const SharedItemView({super.key});

  static const double _collapsedContentHeight = 12 + 16 + 50; // = 78

  @override
  Widget build(BuildContext context) {
    final selectedTopic = useState<UserTopic?>(null);
    final selectedType = useState<SharedItemType?>(null);
    final applyFilters = useState<bool>(false);
    final sheetController = useMemoized(() => DraggableScrollableController());
    final searchFocusNode = useFocusNode();
    final searchController = useTextEditingController();

    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedSize = _collapsedContentHeight / screenHeight;
    final maxSize = 0.7;

    useEffect(() {
      void handleFocusChange() {
        if (!searchFocusNode.hasFocus) {
          sheetController.reset();
        }
      }

      searchFocusNode.addListener(handleFocusChange);
      return () {
        searchFocusNode.removeListener(handleFocusChange);
      };
    }, [searchFocusNode]);

    useEffect(() {
      void sheetListener() {
        if (sheetController.size == 0.7) {
        } else if (sheetController.size == collapsedSize.clamp(0.1, 1.0)) {
          if (searchFocusNode.hasFocus) {
            searchFocusNode.unfocus();
          }
        }
      }

      sheetController.addListener(sheetListener);
      return () {
        sheetController.removeListener(sheetListener);
      };
    }, [sheetController]);

    useEffect(() {
      if ((applyFilters.value && selectedType.value == null && selectedTopic.value == null)) {
        applyFilters.value = false;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await sheetController.animateTo(
            collapsedSize,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );

          await context.read<SharedItemsCubit>().searchItems(
            searchQuery: searchController.text.isNotEmpty ? searchController.text : null,
            typeFilter: null,
            userTopic: null,
          );
        });
      }

      if (selectedType.value == null && selectedTopic.value == null) {
        applyFilters.value = false;
      }

      if (applyFilters.value) {
        applyFilters.value = false;
      }

      return null;
    }, [selectedTopic.value]);

    useEffect(() {
      if ((applyFilters.value && selectedType.value == null && selectedTopic.value == null)) {
        applyFilters.value = false;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await sheetController.animateTo(
            collapsedSize,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );

          await context.read<SharedItemsCubit>().searchItems(
            searchQuery: searchController.text.isNotEmpty ? searchController.text : null,
            typeFilter: null,
            userTopic: null,
          );
        });
      }

      if (selectedType.value == null && selectedTopic.value == null) {
        applyFilters.value = false;
      }

      if (applyFilters.value) {
        applyFilters.value = false;
      }

      return null;
    }, [selectedType.value]);

    useEffect(() {
      if (selectedType.value == null && selectedTopic.value == null) {
        applyFilters.value = false;
      }

      return null;
    }, [applyFilters.value]);

    return GestureDetector(
      onTap: () {
        if (searchFocusNode.hasFocus) {
          searchFocusNode.unfocus();
        }
      },
      child: CupertinoPageScaffold(
        backgroundColor: UIColors.background,
        child: Stack(
          children: [
            CustomScrollView(
              physics: BouncingScrollPhysics(),
              clipBehavior: Clip.antiAlias,
              slivers: [
                _AppNavigationBar(),
                _GradientHeader(),

                BlocBuilder<SharedItemsCubit, SharedItemsState>(
                  builder: (context, state) {
                    if (state is SharedItemsLoading) {
                      return _LoadingView(message: 'Hold on, getting your basket ready...');
                    }

                    if (state is SharedItemsError) {
                      return _ErrorView(message: state.message);
                    }

                    if (state is SharedItemsLoaded) {
                      if (state.items.isEmpty) {
                        return _EmptyStateView();
                      }

                      return _ItemsGridView(items: state.items);
                    }

                    return _EmptyStateView();
                  },
                ),
                SliverToBoxAdapter(child: SizedBox(height: 160)),
              ],
            ),
            BlocBuilder<UserTopicsCubit, UserTopicState>(
              builder: (context, state) {
                return _BottomFilterSheet(
                  sheetController: sheetController,
                  searchController: searchController,
                  searchFocusNode: searchFocusNode,
                  collapsedSize: collapsedSize,
                  maxSize: maxSize,
                  selectedType: selectedType,
                  selectedTopic: selectedTopic,
                  applyFilters: applyFilters,
                  userTopicState: state,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// State Views
// ============================================================================

class _LoadingView extends StatelessWidget {
  final String message;

  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 150),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100, child: Image.asset("assets/loading2.gif")),
              UIGap.mdVertical(),
              Text(message, style: UITextStyles.body, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 150),
        child: Center(child: Text('Error: $message', style: UITextStyles.body)),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView();

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 150),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No shared items yet!\nShare something to get started.',
                style: UITextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
