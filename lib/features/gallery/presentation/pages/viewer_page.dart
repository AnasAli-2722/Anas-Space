import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/unified_asset.dart';
import '../../../../../ui/theme/cyberpunk_theme.dart';
class ViewerPage extends StatelessWidget {
  final UnifiedAsset asset;
  const ViewerPage({super.key, required this.asset});
  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: CyberpunkTheme.darkBg,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.5,
                  colors: [
                    CyberpunkTheme.darkBg,
                    CyberpunkTheme.neonCyan.withValues(
                      alpha: CyberpunkTheme.neonCyan.a * 0.05,
                    ),
                    CyberpunkTheme.neonMagenta.withValues(
                      alpha: CyberpunkTheme.neonMagenta.a * 0.05,
                    ),
                    CyberpunkTheme.darkBg,
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildImage(),
            ),
          ),
          Positioned(
            top: isDesktop ? 40 : 30,
            right: isDesktop ? 30 : 20,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [CyberpunkTheme.neonCyan, CyberpunkTheme.neonMagenta],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: CyberpunkTheme.neonGlow(
                  CyberpunkTheme.neonCyan,
                  intensity: 0.6,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: EdgeInsets.all(isDesktop ? 12 : 10),
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: isDesktop ? 28 : 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: isDesktop ? 30 : 20,
            left: isDesktop ? 30 : 20,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 16 : 12,
                vertical: isDesktop ? 10 : 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CyberpunkTheme.darkBgSecondary.withValues(
                      alpha: CyberpunkTheme.darkBgSecondary.a * 0.9,
                    ),
                    CyberpunkTheme.darkBg.withValues(
                      alpha: CyberpunkTheme.darkBg.a * 0.9,
                    ),
                  ],
                ),
                border: Border.all(
                  color: CyberpunkTheme.neonCyan.withValues(
                    alpha: CyberpunkTheme.neonCyan.a * 0.3,
                  ),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: CyberpunkTheme.neonCyan.withValues(
                      alpha: CyberpunkTheme.neonCyan.a * 0.1,
                    ),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.zoom_in,
                    color: CyberpunkTheme.neonCyan,
                    size: isDesktop ? 18 : 16,
                  ),
                  SizedBox(width: isDesktop ? 8 : 6),
                  Text(
                    "PINCH TO ZOOM",
                    style: TextStyle(
                      color: CyberpunkTheme.neonCyan,
                      fontFamily: 'Courier',
                      fontSize: isDesktop ? 12 : 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildImage() {
    final bool isMobile = Platform.isAndroid || Platform.isIOS;
    if (isMobile && asset.isLocal) {
      return FutureBuilder<File?>(
        future: AssetEntity.fromId(asset.id).then((e) => e?.file),
        builder: (c, s) {
          if (s.hasData && s.data != null) {
            return Image.file(s.data!, fit: BoxFit.contain);
          }
          return const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(CyberpunkTheme.neonCyan),
          );
        },
      );
    }
    if (asset.isLocal && asset.localFile != null) {
      return Image.file(asset.localFile!, fit: BoxFit.contain);
    }
    if (asset.remoteUrl != null) {
      return Image.network(asset.remoteUrl!, fit: BoxFit.contain);
    }
    return const Icon(Icons.error);
  }
}

