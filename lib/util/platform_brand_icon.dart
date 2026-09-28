import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A small brand icon for a platform preset (used as a FilterChip avatar),
/// in that platform's own brand color, or a generic fallback for any preset
/// this doesn't recognize.
Widget platformBrandIcon(String presetId, {double size = 18}) {
  switch (presetId) {
    case 'youtube':
      return FaIcon(
        FontAwesomeIcons.youtube,
        size: size,
        color: const Color(0xFFFF0000),
      );
    case 'instagram_feed':
    case 'instagram_reels_stories':
    case 'instagram_portrait_4x5':
      return FaIcon(
        FontAwesomeIcons.instagram,
        size: size,
        color: const Color(0xFFE1306C),
      );
    case 'tiktok':
      return FaIcon(FontAwesomeIcons.tiktok, size: size, color: Colors.white);
    case 'facebook_feed':
      return FaIcon(
        FontAwesomeIcons.facebook,
        size: size,
        color: const Color(0xFF1877F2),
      );
    case 'spotify_canvas':
      return FaIcon(
        FontAwesomeIcons.spotify,
        size: size,
        color: const Color(0xFF1DB954),
      );
    default:
      return Icon(Icons.videocam_outlined, size: size, color: Colors.white70);
  }
}
