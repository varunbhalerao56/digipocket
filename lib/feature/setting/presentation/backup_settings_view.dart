part of 'settings_view.dart';

class _BackupSettingsView extends StatelessWidget {
  final VoidCallback onImport;

  const _BackupSettingsView({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DataExportCubit, DataExportState>(
      listener: (context, state) {
        final cubit = context.read<DataExportCubit>();

        if (state is DataExportSuccess) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("Export Successful"),
              content: Text(
                "Exported ${state.result.itemCount} items, ${state.result.topicCount} baskets, and ${state.result.imageCount} images.\n\nSaved to: Chuck'it/Exports in your files",
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    cubit.reset();
                  },
                ),
              ],
            ),
          );
        } else if (state is DataImportSuccess) {
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("Import Successful"),
              content: Text(
                "Added: ${state.result.itemsAdded} items\n"
                "Updated: ${state.result.itemsUpdated} items\n"
                "Skipped: ${state.result.itemsSkipped} items\n"
                "Baskets: ${state.result.topicsAdded} added",
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();

                    cubit.reset();
                    onImport();
                  },
                ),
              ],
            ),
          );
        } else if (state is DataExportError) {
          print('Data export error: ${state.error}');
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text("Error"),
              content: Text(state.error),
              actions: [
                CupertinoDialogAction(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                    cubit.reset();
                  },
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is DataExportLoading;
        final loadingMessage = state is DataExportLoading ? state.message : '';

        return CupertinoPageScaffold(
          backgroundColor: UIColors.background,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.antiAlias,
            slivers: [
              CupertinoSliverNavigationBar(
                backgroundColor: UIColors.background,
                largeTitle: Text("Backup Settings", style: UITextStyles.largeTitle),
                previousPageTitle: "Settings",
                heroTag: 'backup_settings',
                stretch: true,
                border: null,
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  if (isLoading)
                    Padding(
                      padding: UIInsets.md,
                      child: Container(
                        padding: UIInsets.md,
                        decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.logo),
                        child: Row(
                          children: [
                            const CupertinoActivityIndicator(),
                            UIGap.mdHorizontal(),
                            Expanded(
                              child: Text(
                                loadingMessage,
                                style: UITextStyles.subheadline.copyWith(color: UIColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: UIInsets.horizontal,
                    child: Container(
                      padding: UIInsets.md,
                      decoration: ShapeDecoration(shape: UIRadius.mdShape, color: UIColors.logo),
                      child: Text(
                        "Export your data to a ZIP file or import from a previous backup. Exports are saved to your Downloads folder.",
                        style: UITextStyles.subheadline.copyWith(color: UIColors.primary),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                  Padding(
                    padding: UIInsets.md,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UIGap.mdVertical(),
                        Text("Markdown Backup", style: UITextStyles.title2),
                        UIGap.sVertical(),
                        Text(
                          "Export all your items in a markdown format, organized by baskets.",
                          style: UITextStyles.subheadline.copyWith(color: UIColors.secondary),
                        ),
                        UIGap.mdVertical(),
                        SizedBox(
                          width: double.infinity,
                          child: UIOutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final confirm = await showCupertinoDialog<bool>(
                                      context: context,
                                      builder: (context) => CupertinoAlertDialog(
                                        title: const Text("Export to Markdown"),
                                        content: const Text("This will create markdown files organized by baskets."),
                                        actions: [
                                          CupertinoDialogAction(
                                            child: const Text("Cancel"),
                                            onPressed: () => Navigator.of(context).pop(false),
                                          ),
                                          CupertinoDialogAction(
                                            isDefaultAction: true,
                                            child: const Text("Export"),
                                            onPressed: () => Navigator.of(context).pop(true),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true && context.mounted) {
                                      await context.read<DataExportCubit>().exportMarkdown();
                                    }
                                  },
                            child: const Text("Export to Markdown"),
                          ),
                        ),
                        UIGap.mdVertical(),

                        Text("JSON Backup", style: UITextStyles.title2),
                        UIGap.sVertical(),
                        Text(
                          "Export all your items, baskets, and images as a JSON file.",
                          style: UITextStyles.subheadline.copyWith(color: UIColors.secondary),
                        ),
                        UIGap.mdVertical(),
                        SizedBox(
                          width: double.infinity,
                          child: UIOutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final confirm = await showCupertinoDialog<bool>(
                                      context: context,
                                      builder: (context) => CupertinoAlertDialog(
                                        title: const Text("Export Data"),
                                        content: const Text(
                                          "This will create a backup of all your items and baskets in the Downloads folder.",
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            child: const Text("Cancel"),
                                            onPressed: () => Navigator.of(context).pop(false),
                                          ),
                                          CupertinoDialogAction(
                                            isDefaultAction: true,
                                            child: const Text("Export"),
                                            onPressed: () => Navigator.of(context).pop(true),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true && context.mounted) {
                                      await context.read<DataExportCubit>().exportJson();
                                    }
                                  },
                            child: const Text("Export to JSON"),
                          ),
                        ),
                        UIGap.mdVertical(),
                        SizedBox(
                          width: double.infinity,
                          child: UIOutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final confirm = await showCupertinoDialog<bool>(
                                      context: context,
                                      builder: (context) => CupertinoAlertDialog(
                                        title: const Text("Import Data"),
                                        content: const Text(
                                          "This will import items and baskets from a backup file. Newer items will be kept in case of conflicts.",
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            child: const Text("Cancel"),
                                            onPressed: () => Navigator.of(context).pop(false),
                                          ),
                                          CupertinoDialogAction(
                                            isDefaultAction: true,
                                            child: const Text("Import"),
                                            onPressed: () => Navigator.of(context).pop(true),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true && context.mounted) {
                                      await context.read<DataExportCubit>().importJson();
                                    }
                                  },
                            child: const Text("Import from JSON"),
                          ),
                        ),
                        UIGap.lVertical(),
                        UIDivider.horizontalExtraThin,
                        UIGap.lVertical(),
                        Text("Google Drive Backup", style: UITextStyles.title2),
                        UIGap.sVertical(),
                        Text(
                          "Coming soon: Automatic backup to Google Drive.",
                          style: UITextStyles.subheadline.copyWith(color: UIColors.secondary),
                        ),
                        UIGap.mdVertical(),
                        SizedBox(
                          width: double.infinity,
                          child: UIOutlinedButton(
                            onPressed: null, // Disabled for now
                            child: const Text("Connect Google Drive"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
