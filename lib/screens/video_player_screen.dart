import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController controller;

  bool initialized = false;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await controller.initialize();

      await controller.setLooping(false);

      await controller.setVolume(1.0);

      await controller.play();

      if (!mounted) return;

      setState(() {
        initialized = true;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void togglePlay() {
    if (!initialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Video"),
      ),
      body: Center(
        child: loading
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : error != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(controller),

                                ValueListenableBuilder(
                                  valueListenable: controller,
                                  builder: (context, VideoPlayerValue value, _) {
                                    if (value.isBuffering) {
                                      return const CircularProgressIndicator(
                                        color: Colors.white,
                                      );
                                    }

                                    return const SizedBox.shrink();
                                  },
                                ),

                                GestureDetector(
                                  onTap: togglePlay,
                                  child: ValueListenableBuilder(
                                    valueListenable: controller,
                                    builder: (context, VideoPlayerValue value, _) {
                                      return AnimatedOpacity(
                                        duration: const Duration(milliseconds: 300),
                                        opacity: value.isPlaying ? 0 : 1,
                                        child: const Icon(
                                          Icons.play_circle_fill,
                                          size: 90,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: VideoProgressIndicator(
                          controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.green,
                            bufferedColor: Colors.grey,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, VideoPlayerValue value, _) {
                          return IconButton(
                            iconSize: 65,
                            color: Colors.white,
                            icon: Icon(
                              value.isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                            ),
                            onPressed: togglePlay,
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
      ),
    );
  }
}
