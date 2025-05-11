import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';

class AudioController extends GetxController {
  final AudioPlayer _audioPlayer = AudioPlayer();

  play({required String file}) {
    if (Platform.isIOS) {
      _audioPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.interruptSpokenAudioAndMixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ));
    }

    _audioPlayer.play(
      AssetSource(file),
      // https://github.com/ryanheise/just_audio/issues/941
      position: const Duration(milliseconds: 10),
    );

    if (Platform.isIOS) {
      Future.delayed(const Duration(seconds: 2)).then((value) {
        _audioPlayer.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.interruptSpokenAudioAndMixWithOthers,
            },
          ),
        ));
      });
    }
  }
}
