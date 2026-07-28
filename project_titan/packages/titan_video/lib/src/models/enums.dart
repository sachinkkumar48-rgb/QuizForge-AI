/// Video playback quality settings.
enum VideoQuality {
  auto,
  low360p,
  sd480p,
  hd720p,
  fhd1080p,
  uhd4k,
}

extension VideoQualityX on VideoQuality {
  String get label {
    switch (this) {
      case VideoQuality.auto:
        return 'Auto';
      case VideoQuality.low360p:
        return '360p';
      case VideoQuality.sd480p:
        return '480p';
      case VideoQuality.hd720p:
        return '720p HD';
      case VideoQuality.fhd1080p:
        return '1080p Full HD';
      case VideoQuality.uhd4k:
        return '4K Ultra HD';
    }
  }
}

/// Playback speed multipliers.
enum PlaybackSpeed {
  speed0_5x,
  speed0_75x,
  speed1_0x,
  speed1_25x,
  speed1_5x,
  speed2_0x,
}

extension PlaybackSpeedX on PlaybackSpeed {
  double get multiplier {
    switch (this) {
      case PlaybackSpeed.speed0_5x:
        return 0.5;
      case PlaybackSpeed.speed0_75x:
        return 0.75;
      case PlaybackSpeed.speed1_0x:
        return 1.0;
      case PlaybackSpeed.speed1_25x:
        return 1.25;
      case PlaybackSpeed.speed1_5x:
        return 1.5;
      case PlaybackSpeed.speed2_0x:
        return 2.0;
    }
  }

  String get label {
    return '${multiplier}x';
  }
}
