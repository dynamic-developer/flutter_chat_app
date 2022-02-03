import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class KVideoPlayer extends StatefulWidget {
  const KVideoPlayer({Key? key, required this.videoPlayerController})
      : super(key: key);
  final VideoPlayerController videoPlayerController;

  @override
  _KVideoPlayerState createState() => _KVideoPlayerState();
}

class _KVideoPlayerState extends State<KVideoPlayer> {
  late ChewieController _chewieController;

  @override
  void initState() {
    // ignore: todo
    // TODO: implement  initState
    super.initState();

    _chewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,
      aspectRatio: widget.videoPlayerController.value.aspectRatio,
      autoInitialize: true,
      placeholder: const Center(
          child: CircularProgressIndicator(
        color: Colors.white,
      )),
      autoPlay: false,
      looping: false,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _chewieController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 4,
      child: ClipRRect(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Chewie(
          controller: _chewieController,
        ),
      ),
    );
  }
}
