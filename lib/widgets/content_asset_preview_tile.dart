import 'package:flutter/material.dart';

import '../models/content_asset.dart';
import 'app_network_image.dart';
import 'auto_play_video_preview.dart';

class ContentAssetPreviewTile extends StatelessWidget {
  final ContentAsset asset;
  final VoidCallback onTap;
  final double borderRadius;

  const ContentAssetPreviewTile({
    super.key,
    required this.asset,
    required this.onTap,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final previewUrl = asset.previewUrl;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (asset.isVideo)
                  IgnorePointer(
                    child: AutoPlayVideoPreview(
                      url: Uri.parse(asset.url),
                      fit: BoxFit.cover,
                      placeholder: previewUrl != null
                          ? AppNetworkImage(
                              url: previewUrl,
                              fit: BoxFit.cover,
                              placeholder: const ColoredBox(
                                color: Colors.white10,
                              ),
                              errorWidget: const ColoredBox(
                                color: Colors.white10,
                              ),
                            )
                          : const ColoredBox(color: Colors.white10),
                      errorWidget: previewUrl != null
                          ? AppNetworkImage(
                              url: previewUrl,
                              fit: BoxFit.cover,
                              placeholder: const ColoredBox(
                                color: Colors.white10,
                              ),
                              errorWidget: const ColoredBox(
                                color: Colors.white10,
                              ),
                            )
                          : const ColoredBox(color: Colors.white10),
                    ),
                  )
                else if (previewUrl != null)
                  AppNetworkImage(
                    url: previewUrl,
                    fit: BoxFit.cover,
                    placeholder: const ColoredBox(color: Colors.white10),
                    errorWidget: const ColoredBox(color: Colors.white10),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE50914).withValues(alpha: 0.28),
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Icon(
                      asset.isVideo
                          ? Icons.play_circle_outline
                          : Icons.image_outlined,
                      color: Colors.white70,
                      size: 42,
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
                PositionedDirectional(
                  top: 10,
                  start: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      asset.isVideo
                          ? Icons.play_arrow_rounded
                          : Icons.image_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                if (asset.isVideo)
                  Container(
                    margin: const EdgeInsets.all(12),
                    alignment: Alignment.center,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.90),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Color(0xFFE50914),
                        size: 30,
                      ),
                    ),
                  ),
                PositionedDirectional(
                  start: 10,
                  end: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          asset.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: isRtl ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.35,
                          ),
                        ),
                        if (asset.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            asset.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: isRtl ? TextAlign.right : TextAlign.left,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
