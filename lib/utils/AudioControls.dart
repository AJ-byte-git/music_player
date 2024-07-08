import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioControls extends StatelessWidget {
  final AudioPlayer audioPlayer;

  const AudioControls({super.key, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
        stream: audioPlayer.playerStateStream,
        builder: (context, snapshot) {
          final playerState = snapshot.data;
          final processingState = playerState?.processingState;
          final playing = playerState?.playing;
          if (!(playing ?? false)) {
            return IconButton(
                iconSize: 80,
                color: Colors.white,
                onPressed: audioPlayer.play,
                icon: const Icon(Icons.play_arrow_sharp));
          } else if (processingState != ProcessingState.completed) {
            return IconButton(
                iconSize: 80,
                color: Colors.white,
                onPressed: audioPlayer.pause,
                icon: const Icon(Icons.pause));
          }
          return IconButton(
            iconSize: 80,
            color: Colors.white,
            icon: const Icon(Icons.play_arrow),
            onPressed: audioPlayer.play,
          );
        });
  }
}
