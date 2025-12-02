part of "shared_items_view.dart";

class FullScreenImageView extends StatelessWidget {
  final String imagePath;
  final String heroTag;

  const FullScreenImageView({super.key, required this.imagePath, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: CupertinoThemeData(primaryColor: UIColors.background),
      child: CupertinoPageScaffold(
        backgroundColor: Colors.black,

        navigationBar: CupertinoNavigationBar(
          backgroundColor: Colors.black.withAlpha(40),
          border: null,

          middle: const Text('Image'),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: UIInsets.vertical,
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(File(imagePath), fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
