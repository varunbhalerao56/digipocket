import 'package:digipocket/feature/setting/presentation/cubit/settings_cubit.dart';
import 'package:digipocket/feature/shared_item/presentation/cubit/shared_items_cubit.dart';
import 'package:digipocket/global/themes/themes.dart';
import 'package:digipocket/global/widgets/cupertino_buttons.dart';
import 'package:digipocket/global/widgets/cupertino_filter_chips.dart';
import 'package:digipocket/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:digipocket/feature/data_export/data_export.dart';

part 'embedding_settings_view.dart';
part 'backup_settings_view.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return state is SettingsLoaded
            ? _SettingsView(
                defaultTextEmbeddingMatcher: state.textEmbeddingMatcherThreshold,
                defaultImageEmbeddingMatcher: state.imageEmbeddingMatcherThreshold,
                defaultCombinedEmbeddingMatcher: state.combinedEmbeddingMatcherThreshold,
                defaultKeywordMatcher: state.keywordMatcher,
                defaultMaxTags: state.maxTags,
              )
            : CupertinoPageScaffold(
                backgroundColor: UIColors.background,
                child: Center(child: CupertinoActivityIndicator()),
              );
      },
      listener: (context, state) {},
    );
  }
}

class _SettingsView extends HookWidget {
  final double defaultTextEmbeddingMatcher;
  final double defaultImageEmbeddingMatcher;
  final double defaultCombinedEmbeddingMatcher;
  final bool defaultKeywordMatcher;
  final int defaultMaxTags;

  const _SettingsView({
    required this.defaultTextEmbeddingMatcher,
    required this.defaultImageEmbeddingMatcher,
    required this.defaultCombinedEmbeddingMatcher,
    required this.defaultKeywordMatcher,
    required this.defaultMaxTags,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: CupertinoPageScaffold(
        backgroundColor: UIColors.background,
        child: CustomScrollView(
          physics: BouncingScrollPhysics(),
          clipBehavior: Clip.antiAlias,
          slivers: [
            CupertinoSliverNavigationBar(
              backgroundColor: UIColors.background,
              largeTitle: Text("Settings", style: UITextStyles.largeTitle),
              previousPageTitle: "Home",
              heroTag: 'user_settings',

              stretch: true,
              border: null,
            ),

            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: UIInsets.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CupertinoListTile(
                        padding: EdgeInsets.zero,
                        title: const Text("Embedding Settings"),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          final settingsCubit = context.read<SettingsCubit>();

                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: settingsCubit,
                                child: _EmbeddingSettingsView(
                                  defaultTextEmbeddingMatcher: defaultTextEmbeddingMatcher,
                                  defaultImageEmbeddingMatcher: defaultImageEmbeddingMatcher,
                                  defaultCombinedEmbeddingMatcher: defaultCombinedEmbeddingMatcher,
                                  defaultKeywordMatcher: defaultKeywordMatcher,
                                  defaultMaxTags: defaultMaxTags,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      UIGap.mdVertical(),

                      CupertinoListTile(
                        padding: EdgeInsets.zero,
                        title: const Text("Backup Settings"),
                        trailing: const CupertinoListTileChevron(),
                        onTap: () {
                          final dataExportCubit = context.read<DataExportCubit>();
                          final sharedItemCubit = context.read<SharedItemsCubit>();

                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => BlocProvider.value(
                                value: dataExportCubit,
                                child: _BackupSettingsView(
                                  onImport: () {
                                    sharedItemCubit.loadSharedItems();
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      UIGap.mdVertical(),
                      UIDivider.horizontalExtraThin,

                      UIGap.mdVertical(),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              child: UIOutlinedButton(
                                onPressed: () async {
                                  bool confirm = await showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: Text("Confirm Reset"),
                                      content: Text(
                                        "Are you sure you want to reset all shared items? This action cannot be undone.",
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: Text("Cancel"),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: Text("Reset"),
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                        ),
                                      ],
                                    ),
                                  );

                                  if (!confirm) return;
                                  await context.read<SettingsCubit>().resetSharedItems();
                                },
                                child: Text("Reset Items"),
                              ),
                            ),
                          ),

                          UIGap.mdHorizontal(),

                          Expanded(
                            child: SizedBox(
                              child: UIOutlinedButton(
                                onPressed: () async {
                                  bool confirm = await showCupertinoDialog(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: Text("Confirm Reset"),
                                      content: Text(
                                        "Are you sure you want to reset all shared items? This action cannot be undone.",
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: Text("Cancel"),
                                          onPressed: () {
                                            Navigator.of(context).pop(false);
                                          },
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: Text("Reset"),
                                          onPressed: () {
                                            Navigator.of(context).pop(true);
                                          },
                                        ),
                                      ],
                                    ),
                                  );

                                  if (!confirm) return;

                                  await context.read<SettingsCubit>().resetUserTopics();
                                },
                                child: Text("Reset Baskets"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
