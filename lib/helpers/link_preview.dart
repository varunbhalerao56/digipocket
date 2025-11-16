import 'package:digipocket/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' show LinkPreviewData;

class LinkPreviewWidget extends HookWidget {
  const LinkPreviewWidget({super.key, required this.url});

  final String url;

  String _getFaviconUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return 'https://www.google.com/s2/favicons?domain=${uri.host}&sz=32';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final linkPreviewData = useState<LinkPreviewData?>(null);
    final isLoading = useState(true);

    useEffect(() {
      () async {
        try {
          final metadata = await getLinkPreviewData(url);
          linkPreviewData.value = metadata;
        } finally {
          isLoading.value = false;
        }
      }();
      return null;
    }, [url]);

    if (isLoading.value) {
      return Container(
        color: UIColors.card,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final data = linkPreviewData.value;
    final faviconUrl = _getFaviconUrl(url);
    final hasTitle = data?.title != null && data!.title!.isNotEmpty;

    return Container(
      decoration: ShapeDecoration(
        color: UIColors.card,
        shape: UIRadius.mdShape,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // if (data?.image != null && data!.image!.url.isNotEmpty)
          //   ClipRSuperellipse(
          //     borderRadius: BorderRadius.only(topLeft: UIRadius.md, topRight: UIRadius.md),
          //     child: Image.network(
          //       data.image!.url,
          //       width: double.infinity,
          //       height: 100,
          //       fit: BoxFit.cover,
          //       errorBuilder: (context, error, stackTrace) => Container(
          //         width: double.infinity,
          //         height: 180,
          //         color: UIColors.card,
          //         child: Icon(Icons.broken_image, size: 48, color: UIColors.primary),
          //       ),
          //     ),
          //   ),

          // Favicon + Domain (only if no title)
          if (!hasTitle)
            Padding(
              padding: const EdgeInsets.only(
                top: UISpacing.sm,
                left: UISpacing.sm,
                right: UISpacing.sm,
                bottom: UISpacing.xs,
              ),
              child: Row(
                children: [
                  if (faviconUrl.isNotEmpty)
                    Image.network(
                      faviconUrl,
                      width: 16,
                      height: 16,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.link, size: 16, color: UIColors.primary),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Uri.parse(url).host,
                      style: UITextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Title with favicon
          if (hasTitle)
            Padding(
              padding: const EdgeInsets.only(
                top: UISpacing.sm,
                left: UISpacing.sm,
                right: UISpacing.sm,
                bottom: UISpacing.xs,
              ),
              child: Column(
                spacing: UISpacing.xs,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (faviconUrl.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Image.network(
                            faviconUrl,
                            width: 16,
                            height: 16,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.link,
                              size: 16,
                              color: UIColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          Uri.parse(url).host,
                          style: UITextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  Text(
                    data.title!,
                    style: UITextStyles.subheadlineBold,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          // Description
          if (data?.description != null && data!.description!.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: UISpacing.sm),
              child: Text(
                data.description!,
                style: UITextStyles.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: UISpacing.sm),
          ],
        ],
      ),
    );
  }
}
