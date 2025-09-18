import 'package:flutter/material.dart';

class WallpaperScaffold extends StatelessWidget {
  final Widget child;
  final bool showWallpaper;

  const WallpaperScaffold({
    super.key,
    required this.child,
    this.showWallpaper = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (showWallpaper)
            SizedBox.expand(
              child: Image.asset(
                "images/wallpaper.png",
                fit: BoxFit.cover,
              ),
            ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
