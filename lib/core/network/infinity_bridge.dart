import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/foundation.dart';
import '../../features/gallery/domain/unified_asset.dart';

class InfinityBridge {
  //---------*Variables*---------
  HttpServer? _server;
  final bool isMobile = Platform.isAndroid || Platform.isIOS;
  String? _hostedIp;
  final String pairingToken;

  Map<String, String> _allowedDesktopFiles = {};
  Set<String> _allowedMobileIds = {};

  //---------*Callbacks*---------
  final Function(String log) onLog;
  final Function(String deviceName, String ip) onConnection;
  final Function(List<UnifiedAsset> remoteAssets) onNewAssetsReceived;
  final List<UnifiedAsset> Function() getLocalAssets;

  InfinityBridge({
    required this.pairingToken,
    required this.onLog,
    required this.onConnection,
    required this.onNewAssetsReceived,
    required this.getLocalAssets,
  });

  //---------*Server Management*---------
  void stop() {
    if (_server != null) {
      _server!.close(force: true);
      _server = null;
      onLog("Server stopped");
    }
  }

  Future<String> start() async {
    String myIp = await _getUiSafeIp();
    _hostedIp = myIp;

    try {
      final app = Router();

      // Define API Routes
      _configureRoutes(app);

      final handler = const Pipeline()
          .addMiddleware(logRequests())
          .addHandler(app.call);

      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 4545);
      return myIp;
    } catch (e) {
      onLog("Server Error: $e");
      return "127.0.0.1";
    }
  }

  //---------*Route Logic*---------
  void _configureRoutes(Router app) {
    // Serve the list of local assets (Manifest)
    app.get('/manifest', (Request req) {
      if (!_isAuthorized(req)) {
        return Response(401, body: 'Unauthorized');
      }
      final assets = getLocalAssets();

      _rebuildAllowLists(assets);

      final manifest = assets.map((e) {
        // Encode file paths for desktop security
        String safeId = e.id;
        if (!isMobile) safeId = _generateSafeId(e.id);

        return {
          'id': safeId,
          'date': e.dateModified.millisecondsSinceEpoch,
          'type': isMobile ? 'mobile_asset' : 'file_path',
        };
      }).toList();

      return Response.ok(
        jsonEncode(manifest),
        headers: {'content-type': 'application/json'},
      );
    });

    // Serve specific media files
    app.get('/media/<fileId>', (Request request, String fileId) async {
      if (!_isAuthorized(request)) {
        return Response(401, body: 'Unauthorized');
      }

      File? fileToServe;

      if (isMobile) {
        if (!_allowedMobileIds.contains(fileId)) {
          // If allow-list isn't built yet, build it on demand.
          _rebuildAllowLists(getLocalAssets());
          if (!_allowedMobileIds.contains(fileId)) {
            return Response.forbidden('Forbidden');
          }
        }
        final asset = await AssetEntity.fromId(fileId);
        fileToServe = await asset?.file;
      } else {
        // Only serve files that were advertised in /manifest.
        if (_allowedDesktopFiles.isEmpty) {
          _rebuildAllowLists(getLocalAssets());
        }
        final systemPath = _allowedDesktopFiles[fileId];
        if (systemPath == null) {
          return Response.forbidden('Forbidden');
        }
        fileToServe = File(systemPath);
      }

      if (fileToServe != null && await fileToServe.exists()) {
        return Response.ok(
          fileToServe.openRead(),
          headers: {
            'Content-Type': _contentTypeForPath(fileToServe.path),
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
      return Response.notFound('File not found');
    });

    // Handle connection requests from other devices
    app.post('/handshake', (Request request) async {
      if (!_isAuthorized(request)) {
        return Response(401, body: '{"status": "Unauthorized"}');
      }
      final payload = await request.readAsString();
      final data = jsonDecode(payload);

      String remoteIp = data['ip'];
      String deviceName = data['name'];

      // Prevent connecting to self
      if (remoteIp == _hostedIp) {
        return Response.ok('{"status": "Ignored Self"}');
      }

      onLog("Handshake received from $deviceName");
      onConnection(deviceName, remoteIp);

      // Establish bidirectional connection
      connectToDevice(remoteIp, pairingToken: pairingToken, silent: true);

      return Response.ok('{"status": "Welcome"}');
    });
  }

  //---------*Client Connection Logic*---------
  Future<void> connectToDevice(
    String ip, {
    required String pairingToken,
    bool silent = false,
    bool sendHandshake = false,
  }) async {
    // Validate IP format
    if (!_isValidIp(ip)) {
      if (!silent) onLog("Invalid IP address format: $ip");
      return;
    }

    // Sanitize IP address (remove ports if present)
    String cleanIp = ip.contains(':') ? ip.split(':')[0] : ip;

    // Prevent loopback connections
    if (cleanIp == _hostedIp ||
        cleanIp == '127.0.0.1' ||
        cleanIp == 'localhost') {
      if (!silent) onLog("Skipped connection to self ($cleanIp)");
      return;
    }

    if (!silent) onLog("Connecting to $cleanIp...");

    try {
      final url = Uri.parse(
        "http://$cleanIp:4545/manifest?t=${Uri.encodeComponent(pairingToken)}",
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        if (sendHandshake) _sendHandshakeTo(cleanIp);

        final List<dynamic> data = jsonDecode(response.body);
        List<UnifiedAsset> newRemoteAssets = data.map((item) {
          final id = item['id'];
          return UnifiedAsset(
            id: id,
            isLocal: false,
            remoteUrl:
                "http://$cleanIp:4545/media/$id?t=${Uri.encodeComponent(pairingToken)}",
            dateModified: DateTime.fromMillisecondsSinceEpoch(item['date']),
          );
        }).toList();

        onNewAssetsReceived(newRemoteAssets);
        if (!silent) onLog("Connected! Found ${newRemoteAssets.length} items.");
      }
    } catch (e) {
      if (!silent) onLog("Connection Failed: $e");
    }
  }

  Future<void> _sendHandshakeTo(String targetIp) async {
    String myIp = await _getUiSafeIp();
    final body = jsonEncode({
      "ip": myIp,
      "port": 4545,
      "name": Platform.localHostname,
    });

    try {
      await http.post(
        Uri.parse(
          'http://$targetIp:4545/handshake?t=${Uri.encodeComponent(pairingToken)}',
        ),
        body: body,
      );
    } catch (e) {
      // Handshake failures are expected if the target is not ready
    }
  }

  //---------*Helpers*---------
  Future<String> _getUiSafeIp() async {
    // Desktop: Filter out virtual interfaces (VMs, WSL, etc.)
    if (!kIsWeb && Platform.isWindows) {
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
        );
        for (var interface in interfaces) {
          String name = interface.name.toLowerCase();
          if (name.contains('veth') ||
              name.contains('virtual') ||
              name.contains('wsl')) {
            continue;
          }
          for (var addr in interface.addresses) {
            if (!addr.isLoopback && addr.address.contains('.')) {
              return addr.address;
            }
          }
        }
      } catch (e) {
        // Fallback to default behavior on error
      }
    } else {
      // Mobile: Use NetworkInfo plugin
      return await NetworkInfo().getWifiIP() ?? "127.0.0.1";
    }
    return "127.0.0.1";
  }

  // Encodes file paths to URL-safe strings
  String _generateSafeId(String path) {
    List<int> bytes = utf8.encode(path);
    return base64Url.encode(bytes);
  }

  bool _isAuthorized(Request req) {
    final headerToken = req.headers['x-anas-token'];
    final queryToken = req.url.queryParameters['t'];
    final token = (headerToken ?? queryToken ?? '').trim();
    return token.isNotEmpty && token == pairingToken;
  }

  void _rebuildAllowLists(List<UnifiedAsset> assets) {
    if (isMobile) {
      _allowedMobileIds = assets.map((e) => e.id).toSet();
      _allowedDesktopFiles = {};
    } else {
      final map = <String, String>{};
      for (final a in assets) {
        final safeId = _generateSafeId(a.id);
        map[safeId] = a.id;
      }
      _allowedDesktopFiles = map;
      _allowedMobileIds = {};
    }
  }

  String _contentTypeForPath(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.gif')) return 'image/gif';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.mp4')) return 'video/mp4';
    if (p.endsWith('.mov')) return 'video/quicktime';
    if (p.endsWith('.mkv')) return 'video/x-matroska';
    if (p.endsWith('.3gp')) return 'video/3gpp';
    return 'application/octet-stream';
  }

  // Validates IPv4 address format
  bool _isValidIp(String ip) {
    // Remove port if present
    String cleanIp = ip.contains(':') ? ip.split(':')[0] : ip;

    final ipv4Regex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');

    if (!ipv4Regex.hasMatch(cleanIp)) {
      return false;
    }

    // Validate each octet is 0-255
    final octets = cleanIp.split('.');
    for (final octet in octets) {
      final num = int.tryParse(octet);
      if (num == null || num < 0 || num > 255) {
        return false;
      }
    }

    return true;
  }
}
