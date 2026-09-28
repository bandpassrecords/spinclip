enum ReleaseMode { single, multiSong, medley }

extension ReleaseModeLabel on ReleaseMode {
  String get label {
    switch (this) {
      case ReleaseMode.single:
        return 'Single song';
      case ReleaseMode.multiSong:
        return 'Multiple songs (one video each)';
      case ReleaseMode.medley:
        return 'Medley (combine excerpts into one video)';
    }
  }
}
