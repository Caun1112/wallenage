import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../utils.dart';

class AssetIcon extends StatelessWidget {
  final Asset asset;
  final double size;
  const AssetIcon({super.key, required this.asset, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final path = assetIconPath(asset.name);
    if (path != null) {
      return Image.asset(path, width: size, height: size, fit: BoxFit.contain);
    }
    return Text(asset.type.fallbackIcon, style: TextStyle(fontSize: size * 0.65));
  }
}
