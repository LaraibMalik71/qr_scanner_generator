import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<PermissionStatus>? _cameraPermissionFuture;

  @override
  void initState() {
    super.initState();
    _cameraPermissionFuture = Permission.camera.status;
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isPermanentlyDenied || status.isRestricted) {
      await openAppSettings();
    }

    if (!mounted) return;

    setState(() {
      _cameraPermissionFuture = Permission.camera.status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Enable dark theme throughout the app'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.setDarkMode(value);
                  },
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Consumer<ThemeProvider>(
                  builder: (context, provider, child) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.flashlight_on_outlined),
                      title: const Text('Flashlight'),
                      subtitle: const Text('Keep flashlight on while scanning'),
                      value: provider.isFlashlightOn,
                      onChanged: (value) {
                        provider.setFlashlight(value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Consumer<ThemeProvider>(
                  builder: (context, provider, child) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.vibration),
                      title: const Text('Vibration'),
                      subtitle: const Text(
                        'Vibrate when a QR code is scanned successfully',
                      ),
                      value: provider.isVibrationEnabled,
                      onChanged: (value) {
                        provider.setVibration(value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Consumer<ThemeProvider>(
                  builder: (context, provider, child) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.volume_up_outlined),
                      title: const Text('Scan Sound'),
                      subtitle: const Text(
                        'Play a sound when a QR code is scanned successfully',
                      ),
                      value: provider.isScanSoundEnabled,
                      onChanged: (value) {
                        provider.setScanSound(value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security_outlined),
                          SizedBox(width: 10),
                          Text(
                            'Manage Permissions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<PermissionStatus>(
                        future: _cameraPermissionFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ListTile(
                              title: Text('Camera Permission'),
                              subtitle: Text('Checking permission...'),
                            );
                          }

                          final status = snapshot.data;

                          final permissionText = status?.isGranted == true
                              ? 'Granted'
                              : status?.isPermanentlyDenied == true
                              ? 'Permanently denied'
                              : status?.isRestricted == true
                              ? 'Restricted'
                              : 'Not granted';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.camera_alt_outlined),
                            title: const Text('Camera Permission'),
                            subtitle: Text(permissionText),
                            trailing: TextButton(
                              onPressed: _requestCameraPermission,
                              child: Text(
                                status?.isGranted == true
                                    ? 'Granted'
                                    : 'Enable',
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
