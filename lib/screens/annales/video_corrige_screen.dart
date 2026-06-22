import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../theme/app_theme.dart';

/// Lecteur vidéo intégré pour les corrigés vidéo. Gère les liens **YouTube**
/// (via iframe) et les vidéos **directes** (MP4/HLS via Chewie). Lien + libellés
/// passés par `extra`.
class VideoCorrigeScreen extends StatefulWidget {
  final String url;
  final String? title;
  final String? subtitle;
  const VideoCorrigeScreen({super.key, required this.url, this.title, this.subtitle});

  @override
  State<VideoCorrigeScreen> createState() => _VideoCorrigeScreenState();
}

class _VideoCorrigeScreenState extends State<VideoCorrigeScreen> {
  YoutubePlayerController? _yt;
  VideoPlayerController? _vpc;
  ChewieController? _chewie;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final url = widget.url.trim();
    if (url.isEmpty) {
      _error = 'Vidéo indisponible.';
      return;
    }
    final ytId = YoutubePlayerController.convertUrlToId(url);
    if (ytId != null) {
      _yt = YoutubePlayerController.fromVideoId(
        videoId: ytId,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    } else {
      _vpc = VideoPlayerController.networkUrl(Uri.parse(url));
      _vpc!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _chewie = ChewieController(
            videoPlayerController: _vpc!,
            autoPlay: true,
            looping: false,
            aspectRatio: _vpc!.value.aspectRatio == 0 ? 16 / 9 : _vpc!.value.aspectRatio,
            materialProgressColors: ChewieProgressColors(playedColor: OC.o500, handleColor: OC.o500),
          );
        });
      }).catchError((_) {
        if (mounted) setState(() => _error = 'Impossible de lire cette vidéo.');
      });
    }
  }

  @override
  void dispose() {
    _yt?.close();
    _chewie?.dispose();
    _vpc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_yt != null) {
      return _scaffold(AspectRatio(aspectRatio: 16 / 9, child: YoutubePlayer(controller: _yt!)));
    }
    Widget media;
    if (_error != null) {
      media = _msg(_error!);
    } else if (_chewie != null) {
      media = AspectRatio(aspectRatio: _chewie!.aspectRatio ?? 16 / 9, child: Chewie(controller: _chewie!));
    } else {
      media = const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return _scaffold(media);
  }

  Widget _scaffold(Widget player) {
    return Scaffold(
      backgroundColor: OC.ink,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 12, 6),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                onPressed: () => context.canPop() ? context.pop() : context.go('/annales'),
              ),
              Expanded(child: Text(widget.title ?? 'Corrigé vidéo',
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: body(14.5, weight: FontWeight.w700, color: Colors.white))),
            ]),
          ),
          player,
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF7A5AE0).withValues(alpha: 0.25), borderRadius: BorderRadius.circular(999)),
                child: Text('CORRIGÉ VIDÉO', style: body(10.5, weight: FontWeight.w800, color: const Color(0xFFC3B0FF))),
              ),
              const SizedBox(height: 10),
              Text(widget.title ?? 'Corrigé vidéo',
                  style: display(18, weight: FontWeight.w600, color: Colors.white).copyWith(height: 1.2)),
              if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(widget.subtitle!, style: body(12.5, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _msg(String text) => AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(text, textAlign: TextAlign.center, style: body(14, color: Colors.white.withValues(alpha: 0.8))),
          ),
        ),
      );
}
