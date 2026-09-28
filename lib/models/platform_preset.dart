class PlatformPreset {
  final String id;
  final String name;
  final int width;
  final int height;
  final String notes;

  /// When set, this preset always renders a short seamless loop of this
  /// length in seconds, overriding RenderSettings.fullDuration/trim for
  /// this preset's job only (e.g. Spotify Canvas).
  final double? fixedLoopSeconds;

  const PlatformPreset({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.notes,
    this.fixedLoopSeconds,
  });

  String get aspectRatioLabel {
    final g = _gcd(width, height);
    return '${width ~/ g}:${height ~/ g}';
  }

  static int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

  static const instagramFeed = PlatformPreset(
    id: 'instagram_feed',
    name: 'Instagram Feed',
    width: 1080,
    height: 1080,
    notes: 'Square feed post',
  );

  static const instagramReelsStories = PlatformPreset(
    id: 'instagram_reels_stories',
    name: 'Instagram Reels/Stories',
    width: 1080,
    height: 1920,
    notes: 'Vertical full-screen',
  );

  static const tiktok = PlatformPreset(
    id: 'tiktok',
    name: 'TikTok',
    width: 1080,
    height: 1920,
    notes: 'Vertical full-screen',
  );

  static const youtube = PlatformPreset(
    id: 'youtube',
    name: 'YouTube',
    width: 1920,
    height: 1080,
    notes: 'Landscape 16:9',
  );

  static const facebookFeed = PlatformPreset(
    id: 'facebook_feed',
    name: 'Facebook Feed',
    width: 1920,
    height: 1080,
    notes: 'Landscape feed video',
  );

  static const instagramPortrait4x5 = PlatformPreset(
    id: 'instagram_portrait_4x5',
    name: 'Instagram Portrait (4:5)',
    width: 1080,
    height: 1350,
    notes: 'Portrait feed post',
  );

  /// Publicly documented as 9:16, 720x1280 minimum (1080x1920 recommended),
  /// a seamless loop of 3-8s, MP4, no audio needed in the file itself.
  /// Verify these numbers against Spotify's current documentation before
  /// relying on them in production.
  static const spotifyCanvas = PlatformPreset(
    id: 'spotify_canvas',
    name: 'Spotify Canvas',
    width: 1080,
    height: 1920,
    notes: 'Seamless loop, ~8s, no audio track needed in file',
    fixedLoopSeconds: 8,
  );

  static const all = <PlatformPreset>[
    instagramFeed,
    instagramReelsStories,
    instagramPortrait4x5,
    tiktok,
    youtube,
    facebookFeed,
    spotifyCanvas,
  ];
}
