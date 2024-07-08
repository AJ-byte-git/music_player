import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:music_player/utils/AudioControls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late AudioPlayer _audioPlayer;
  List<AudioSource> _playlist = [];
  List<Map<String, String>> _audioFiles = [];
  int? _currentIndex;
  final logger = Logger();
  static const String folderPathKey = 'folder_path';

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _audioPlayer.positionStream,
          _audioPlayer.bufferedPositionStream,
          _audioPlayer.durationStream,
              (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.currentIndexStream.listen((index) {
      setState(() {
        _currentIndex = index;
      });
    });
    _loadSavedFolder();
  }

  Future<void> _loadSavedFolder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? folderPath = prefs.getString(folderPathKey);

    if (folderPath != null) {
      Directory directory = Directory(folderPath);
      if (directory.existsSync()) {
        _loadFilesFromFolder(directory);
      } else {
        logger.e("Directory not found: $folderPath");
      }
    }
  }

  Future<void> _pickFolder() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3'],
      allowMultiple: true,
    );

    if (result != null) {
      String? filePath = result.files.single.path;

      if (filePath != null) {
        Directory directory = Directory(filePath).parent;
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(folderPathKey, directory.path);

        _loadFilesFromFolder(directory);
      } else {
        logger.e("File not found: ${result.files.single.path}");
      }
    }
  }

  Future<void> _loadFilesFromFolder(Directory directory) async {
    List<FileSystemEntity> files = directory.listSync();
    List<Map<String, String>> audioFiles = [];
    List<AudioSource> playlist = [];

    for (var file in files) {
      if (file is File && file.path.endsWith('.mp3')) {
        audioFiles.add({
          'path': file.path,
          'name': file.uri.pathSegments.last.split('.').first,
        });

        playlist.add(AudioSource.uri(
          Uri.file(file.path),
          tag: MediaItem(
            id: file.path,
            title: file.uri.pathSegments.last.split('.').first,
          ),
        ));
      }
    }

    setState(() {
      _audioFiles = audioFiles;
      _playlist = playlist;
    });

    await _audioPlayer
        .setAudioSource(ConcatenatingAudioSource(children: _playlist));
  }

  Future<void> _deleteFile(int index) async {
    setState(() {
      _audioFiles.removeAt(index);
      _playlist.removeAt(index);
    });
    await _audioPlayer
        .setAudioSource(ConcatenatingAudioSource(children: _playlist));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF144771),
        title: const Text(
          "Sound Wave",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            iconSize: 30,
            icon: const Icon(Icons.folder, color: Colors.white),
            onPressed: _pickFolder,
          ),
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
            Expanded(
              child: ListView.builder(
                itemCount: _audioFiles.length,
                itemBuilder: (context, index) {
                  return Slidable(
                    key: ValueKey(_audioFiles[index]['path']),
                    startActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      children: [
                        SlidableAction(
                          onPressed: (context) => _deleteFile(index),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.headphones, color: Colors.white,),
                      title: Text(
                        _audioFiles[index]['name']!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      selected: _currentIndex == index,
                      trailing: _currentIndex == index
                          ? const Icon(Icons.play_arrow, color: Colors.green)
                          : null,
                      onTap: () {
                        _audioPlayer.seek(Duration.zero, index: index);
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 15, 30, 5),
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
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    iconSize: 40,
                    color: Colors.white,
                    onPressed: _audioPlayer.seekToPrevious,
                    icon: const Icon(Icons.skip_previous_sharp),
                  ),
                  AudioControls(audioPlayer: _audioPlayer),
                  IconButton(
                    iconSize: 40,
                    color: Colors.white,
                    onPressed: _audioPlayer.seekToNext,
                    icon: const Icon(Icons.skip_next_sharp),
                  ),
                ],
              ),
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
