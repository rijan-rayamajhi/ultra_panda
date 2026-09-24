import 'package:flutter/material.dart';

class GameCardModel {
  final String title;
  final String imagePath;
  final String tag;
  final Color tagColor;

  /// Native artwork width/height, so the card shows the full image uncropped.
  final double aspectRatio;

  const GameCardModel({
    required this.title,
    required this.imagePath,
    required this.tag,
    required this.tagColor,
    this.aspectRatio = 1024 / 1536,
  });
}

class NavItemModel {
  final String iconPath;
  final String label;
  final String badge;

  const NavItemModel({
    required this.iconPath,
    required this.label,
    this.badge = '',
  });
}
