import 'package:flutter/material.dart';
import '../models/media.dart';
import '../screens/image_viewer_screen.dart';
import '../screens/media_detail_screen.dart';
import '../utils/responsive.dart';
import 'app_network_image.dart';

class MediaGrid extends StatelessWidget {
  final List<Media> mediaList;

  const MediaGrid({super.key, required this.mediaList});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(Responsive.scale(context, 8)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isDesktop(context)
            ? 4
            : Responsive.isTablet(context)
                ? 3
                : 2,
        childAspectRatio: Responsive.isDesktop(context) ? 0.7 : 0.8,
        crossAxisSpacing: Responsive.scale(context, 8),
        mainAxisSpacing: Responsive.scale(context, 8),
      ),
      itemCount: mediaList.length,
      itemBuilder: (context, index) {
        final media = mediaList[index];
        final imageItems = mediaList.where((item) => item.isImage).toList();
        final initialImageIndex = imageItems.indexWhere((item) => item.id == media.id);
        return GestureDetector(
          onTap: () {
            if (media.isImage && initialImageIndex != -1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageViewerScreen(
                    urls: imageItems.map((e) => e.url).toList(),
                    titles: imageItems.map((e) => e.title).toList(),
                    initialIndex: initialImageIndex,
                  ),
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MediaDetailScreen(media: media),
              ),
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Responsive.scale(context, 12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: media.isVideo
                        ? Stack(
                            children: [
                              Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_filled,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: AppNetworkImage(
                                  url: media.thumbnail ?? media.url,
                                  fit: BoxFit.cover,
                                  placeholder: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: const Icon(Icons.error),
                                ),
                              ),
                            ],
                          )
                        : AppNetworkImage(
                            url: media.url,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: const Icon(Icons.error),
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(Responsive.scale(context, 8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        media.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            media.isVideo ? Icons.videocam : Icons.image,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            media.category.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.visibility, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            '${media.views}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
