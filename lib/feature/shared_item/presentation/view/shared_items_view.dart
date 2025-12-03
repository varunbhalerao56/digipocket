import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:digipocket/feature/data_export/data_export.dart';
import 'package:digipocket/feature/setting/setting.dart';
import 'package:digipocket/feature/shared_item/shared_item.dart';
import 'package:digipocket/feature/user_topic/user_topic.dart';
import 'package:digipocket/global/constants/constants.dart';
import 'package:digipocket/global/services/clipboard_service.dart';
import 'package:digipocket/global/services/share_outside_service.dart';
import 'package:digipocket/global/themes/themes.dart';
import 'package:digipocket/global/widgets/widgets.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

part 'shared_items_widgets.dart';
part 'shared_items_sheet.dart';
part 'single_item_view.dart';
part 'single_item_full_view.dart';

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
      if ((selectedType.value == null && selectedTopic.value == null)) {
        applyFilters.value = false;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await context.read<SharedItemsCubit>().searchItems(
            searchQuery: searchController.text.isNotEmpty ? searchController.text : null,
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
      if ((selectedType.value == null && selectedTopic.value == null)) {
        applyFilters.value = false;

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await context.read<SharedItemsCubit>().searchItems(
            searchQuery: searchController.text.isNotEmpty ? searchController.text : null,
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
                CupertinoSliverNavigationBar(
                  backgroundColor: UIColors.background,
                  largeTitle: Image.asset(kAppLogo, height: 36),
                  stretch: true,
                  border: null,
                  heroTag: 'home_nav_bar',
                  leading: UIIconButton(
                    onPressed: () {
                      final settingsCubit = context.read<SettingsCubit>();
                      final dataExportCubit = context.read<DataExportCubit>();
                      final sharedItemCubit = context.read<SharedItemsCubit>();
                      final userTopicsCubit = context.read<UserTopicsCubit>();

                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(value: settingsCubit..init()),
                              BlocProvider.value(value: dataExportCubit),
                              BlocProvider.value(value: sharedItemCubit),
                              BlocProvider.value(value: userTopicsCubit),
                            ],
                            child: SettingsView(),
                          ),
                        ),
                      );
                    },
                    icon: Icon(CupertinoIcons.settings_solid),
                  ),
                  trailing: UIIconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<UserTopicsCubit>()..loadUserTopic(),
                            child: UserTopicView(),
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.shopping_basket_rounded),
                  ),
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
                    if (state is SharedItemsData && state.processingQueue == true || state is SharedItemsLoading) {
                      if (state is SharedItemsData && state.items.isEmpty) {
                        return _LoadingView(message: 'Hold on, getting your basket ready...');
                      }

                      return SliverToBoxAdapter(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.only(
                            left: UISpacing.md,
                            right: UISpacing.md,
                            bottom: UISpacing.sm,
                            top: UISpacing.sm,
                          ),
                          margin: const EdgeInsets.only(left: UISpacing.md, right: UISpacing.md, bottom: UISpacing.md),
                          decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.success),
                          child: Center(
                            child: Row(
                              children: [
                                Text(
                                  "Chuck'ing your items in the basket",
                                  style: UITextStyles.body.copyWith(color: UIColors.background),
                                ),
                                Spacer(),
                                CupertinoActivityIndicator(color: UIColors.background),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),

                BlocBuilder<UserTopicsCubit, UserTopicState>(
                  builder: (context, userTopicState) {
                    return BlocBuilder<SharedItemsCubit, SharedItemsState>(
                      builder: (context, state) {
                        if (state is SharedItemsData && state.isLoading == true || state is SharedItemsLoading) {
                          return _LoadingView(message: 'Hold on, getting your basket ready...');
                        }

                        if (state is SharedItemsError) {
                          return _ErrorView(message: state.message);
                        }

                        if (state is SharedItemsData && state.isLoading == false) {
                          if (state.items.isEmpty && state.processingQueue == false) {
                            return _EmptyStateView();
                          }

                          return _ItemsGridView(
                            items: state.items,
                            topics: userTopicState is UserTopicLoaded ? userTopicState.items : [],
                            searchFocusNode: searchFocusNode,
                          );
                        }

                        return _EmptyStateView();
                      },
                    );
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
                  keywordOnlySearch: false,
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
              SizedBox(height: 100, child: Image.asset(kLoadingGif)),
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
              Image.asset(kEmptyLogo, height: 80),
              UIGap.mdVertical(),
              Text(
                'Nothing in your baskets yet!\nShare something to get started.',
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
