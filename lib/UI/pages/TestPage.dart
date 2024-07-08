import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_player/utils/AudioControls.dart';
import 'package:rxdart/rxdart.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late AudioPlayer _audioPlayer;
  final playlist = ConcatenatingAudioSource(children: [
    AudioSource.asset('lib/assets/audio/Jugnu.mp3',
        tag: const MediaItem(id: '0', title: 'Jugnu')),
    AudioSource.asset('lib/assets/audio/1blinding_lights.mp3', tag: const MediaItem(id: '0', title: 'Jugnu')),
    AudioSource.asset('lib/assets/audio/akhiyangulab.mp3', tag: const MediaItem(id: '0', title: 'Jugnu')),
    AudioSource.asset('lib/assets/audio/notimeforcaution.mp3', tag: const MediaItem(id: '0', title: 'Jugnu')),
    AudioSource.asset('lib/assets/audio/saathi.mp3', tag: const MediaItem(id: '0', title: 'Jugnu')),
  ]);

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _audioPlayer.positionStream,
          _audioPlayer.bufferedPositionStream,
          _audioPlayer.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  void initState() {
    _audioPlayer = AudioPlayer();
    init();
    super.initState();
  }

  Future<void> init() async {
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSource(playlist);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          "Sound Wave",
          style: TextStyle(color: Colors.white),
        ),
        actions: const [
          Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Icon(
                Icons.person,
                color: Colors.white,
              ))
        ],
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF144771), Color(0xFF071A2C)])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: StreamBuilder(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;
                    return ProgressBar(
                      baseBarColor: Colors.grey,
                      progressBarColor: Colors.red,
                      bufferedBarColor: Colors.grey,
                      thumbColor: Colors.red,
                      thumbGlowRadius: 10,
                      timeLabelTextStyle: const TextStyle(color: Colors.white),
                      progress: positionData?.position ?? Duration.zero,
                      total: positionData?.duration ?? Duration.zero,
                      buffered: positionData?.bufferPosition ?? Duration.zero,
                      onSeek: _audioPlayer.seek,
                    );
                  }),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    iconSize: 80,
                    color: Colors.white,
                    onPressed: _audioPlayer.seekToPrevious,
                    icon: const Icon(Icons.skip_previous_sharp)),
                AudioControls(audioPlayer: _audioPlayer),
                IconButton(
                  iconSize: 80,
                    color: Colors.white,
                    onPressed: _audioPlayer.seekToNext,
                    icon: const Icon(Icons.skip_next_sharp)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PositionData {
  const PositionData(this.position, this.bufferPosition, this.duration);

  final Duration position;
  final Duration bufferPosition;
  final Duration duration;
}
