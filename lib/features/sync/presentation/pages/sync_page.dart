import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../gallery/presentation/widgets/custom_title_bar.dart';
import '../cubit/sync_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../cubit/sync_state.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final TextEditingController _ipController = TextEditingController();
  final bool _isDesktop = !Platform.isAndroid && !Platform.isIOS;

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.black,
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
                            const Text(
                              "Infinity Sync",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${state.remoteAssets.length} Files",
                              style: TextStyle(
                                color: Colors.blueAccent.shade100,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tabs
                      const TabBar(
                        indicatorColor: Colors.blueAccent,
                        labelColor: Colors.blueAccent,
                        unselectedLabelColor: Colors.white54,
                        tabs: [
                          Tab(
                            text: "Remote Gallery",
                            icon: Icon(Icons.photo_library),
                          ),
                          Tab(text: "Terminal", icon: Icon(Icons.terminal)),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildStatusCard(state, context),

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildRemoteGalleryTab(state),
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
    return Container(
      color: state.isServerRunning
          ? Colors.green.shade900.withOpacity(0.2)
          : Colors.red.shade900.withOpacity(0.2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            state.isServerRunning ? Icons.wifi : Icons.wifi_off,
            size: 16,
            color: state.isServerRunning
                ? Colors.greenAccent
                : Colors.redAccent,
          ),
          const SizedBox(width: 10),
          Text(
            state.isServerRunning ? "Server Online: " : "Server Offline",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          if (state.isServerRunning)
            SelectableText(
              state.myIp,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          const Spacer(),
          Switch(
            value: state.isServerRunning,
            onChanged: (val) => context.read<SyncCubit>().toggleServer(),
            activeColor: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteGalleryTab(SyncState state) {
    if (state.remoteAssets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.white12),
            const SizedBox(height: 10),
            const Text(
              "No files received.",
              style: TextStyle(color: Colors.white54),
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

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: asset.remoteUrl!,
            fit: BoxFit.cover,
            cacheKey: asset.id,

            placeholder: (context, url) => Container(
              color: Colors.grey[900],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.broken_image, color: Colors.white24),
            ),

            memCacheWidth: 200,
          ),
        );
      },
    );
  }

  Widget _buildConnectionTab(BuildContext context, SyncState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Connect to Peer IP",
                    border: OutlineInputBorder(),
                    hintText: "192.168.x.x",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () => context.read<SyncCubit>().connectToDevice(
                  _ipController.text,
                ),
                icon: const Icon(Icons.link),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: state.logs.length,
                itemBuilder: (context, index) => Text(
                  state.logs[index],
                  style: const TextStyle(
                    color: Colors.greenAccent,
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
