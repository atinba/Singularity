import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:singularity/Screens/Player/audioplayer.dart';
import 'package:singularity/Services/audio_service.dart';

class AudioHandlerHelper {
  static final AudioHandlerHelper _instance = AudioHandlerHelper._internal();
  factory AudioHandlerHelper() {
    return _instance;
  }

  AudioHandlerHelper._internal();

  static bool _isInitialized = false;
  static AudioPlayerHandler? audioHandler;

  Future<void> _initialize() async {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandlerImpl(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'org.xf.singularity.channel.audio',
        androidNotificationChannelName: 'Singularity',
        androidNotificationIcon: 'drawable/ic_stat_music_note',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
        // Hive.box('settings').get('stopServiceOnPause', defaultValue: true) as bool,
        notificationColor: Colors.grey[900],
      ),
    );
  }

  Future<AudioPlayerHandler> getAudioHandler() async {
    if (!_isInitialized) {
      await _initialize();
      _isInitialized = true;
    }
    return audioHandler!;
  }
}
