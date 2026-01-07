import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../gallery/presentation/widgets/custom_title_bar.dart';
import '../cubit/sync_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cubit/sync_state.dart';
import '../../../../ui/widgets/stone_theme_switch.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  final bool _isDesktop = Platform.isWindows;

  @override
  void dispose() {
    _ipController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: Column(
              children: [
                if (_isDesktop) const CustomTitleBar(),
                if (!_isDesktop) const SafeArea(child: SizedBox(height: 10)),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(cs.surface, cs.onSurface, 0.04)!,
                        cs.surface,
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                              tooltip: "Back to Dashboard",
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "INFINITY SYNC",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2.0,
                                    color: cs.onSurface,
                                  ),
                            ),
                            const Spacer(),
                            const StoneThemeSwitch(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: cs.outlineVariant.withValues(
                                    alpha: 0.85,
                                  ),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: cs.surface,
                              ),
                              child: Text(
                                "${state.remoteAssets.length} FILES",
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.8),
                                  fontFamily: 'Courier',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tabs
                      TabBar(
                        indicatorColor: cs.primary,
                        indicatorWeight: 3,
                        labelColor: cs.onSurface,
                        unselectedLabelColor: cs.onSurface.withValues(
                          alpha: 0.6,
                        ),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                        tabs: const [
                          Tab(
                            text: "REMOTE GALLERY",
                            icon: Icon(Icons.photo_library),
                          ),
                          Tab(text: "TERMINAL", icon: Icon(Icons.terminal)),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildStatusCard(state, context),

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRemoteGalleryTab(context, state),
                      _buildConnectionTab(context, state),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(SyncState state, BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_tokenController.text != state.pairingToken) {
      _tokenController.text = state.pairingToken;
    }

    final bool isOnline = state.isServerRunning;
    final Color statusColor = isOnline ? cs.primary : cs.error;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              isOnline ? Icons.wifi : Icons.wifi_off,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isOnline ? "SERVER ONLINE" : "SERVER OFFLINE",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: statusColor,
              letterSpacing: 1.0,
            ),
          ),
          if (isOnline) const SizedBox(width: 16),
          if (isOnline)
            SelectableText(
              state.myIp,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier',
              ),
            ),
          const SizedBox(width: 12),
          if (isOnline)
            Container(
              width: 140,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.85),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(6),
                color: cs.surface,
              ),
              child: TextField(
                controller: _tokenController,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "PAIR CODE",
                  labelStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                readOnly: true,
              ),
            ),
          const Spacer(),
          Switch(
            value: state.isServerRunning,
            onChanged: (val) => context.read<SyncCubit>().toggleServer(),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteGalleryTab(BuildContext context, SyncState state) {
    final cs = Theme.of(context).colorScheme;

    if (state.remoteAssets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 10),
            Text(
              "NO FILES RECEIVED",
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.6),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        childAspectRatio: 1.0,
      ),
      itemCount: state.remoteAssets.length,
      itemBuilder: (context, index) {
        final asset = state.remoteAssets[index];
        if (asset.remoteUrl == null) return const SizedBox();

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: asset.remoteUrl!,
              fit: BoxFit.cover,
              cacheKey: asset.id,
              placeholder: (context, url) => Container(
                color: cs.surfaceContainer,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: cs.surfaceContainer,
                child: Icon(Icons.broken_image, color: cs.error),
              ),
              memCacheWidth: 200,
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionTab(BuildContext context, SyncState state) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Pairing Code Field
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.85),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              color: cs.surface,
            ),
            child: TextField(
              controller: _tokenController,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.9),
                fontFamily: 'Courier',
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                labelText: "PAIRING CODE (MUST MATCH PEER)",
                labelStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
                border: InputBorder.none,
                hintText: "e.g. 123456",
                hintStyle: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.35),
                  fontFamily: 'Courier',
                ),
              ),
              onChanged: (v) => context.read<SyncCubit>().setPairingToken(v),
            ),
          ),
          const SizedBox(height: 16),
          // IP Connection Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: cs.surface,
                  ),
                  child: TextField(
                    controller: _ipController,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.9),
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: "CONNECT TO PEER IP",
                      labelStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.7),
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                      border: InputBorder.none,
                      hintText: "192.168.x.x",
                      hintStyle: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.35),
                        fontFamily: 'Courier',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: cs.primaryContainer,
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => context.read<SyncCubit>().connectToDevice(
                    _ipController.text,
                  ),
                  icon: Icon(Icons.link, color: cs.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Terminal Logs
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: state.logs.length,
                itemBuilder: (context, index) => Text(
                  state.logs[index],
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.8),
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
