import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  const ImageScreen({Key? key, required this.url}) : super(key: key);

  final String url;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          progressIndicatorBuilder: (context, url, downloadProgress) => Center(
            child: SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(
                  color: Colors.white, value: downloadProgress.progress),
            ),
          ),
          errorWidget: (context, url, error) {
            debugPrint(error);
            return const Icon(Icons.image_search_rounded);
          },
        ),
      ),
    );
  }
}
