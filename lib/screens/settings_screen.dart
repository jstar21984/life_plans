import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import '../services/sync_service.dart';

const String _appNameKey = 'app_name';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildAppNameSection(context),
                  const Divider(),
                  _buildThemeSection(context),
                  const Divider(),
                  _buildSyncSection(context),
                  const Divider(),
                  _buildNotificationSection(context),
                  const Divider(),
                  _buildAboutSection(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppNameSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'App',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        FutureBuilder<String>(
          future: _getAppName(),
          builder: (context, snapshot) {
            final name = snapshot.data ?? 'Life Plans';
            return ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('App Name'),
              subtitle: Text(name),
              onTap: () => _showRenameDialog(context, name),
            );
          },
        ),
      ],
    );
  }

  Future<String> _getAppName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appNameKey) ?? 'Life Plans';
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename App'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'App Name',
            hintText: 'Enter new name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(_appNameKey, newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('App renamed to "$newName"')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Appearance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme'),
              subtitle: Text(_getThemeLabel(themeProvider.themeMode)),
              onTap: () => _showThemeDialog(context, themeProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSyncSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sync',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('Local Folder'),
          subtitle: const Text('Sync to a local folder'),
          onTap: () => _showLocalSyncDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.cloud),
          title: const Text('WebDAV'),
          subtitle: const Text('Nextcloud, ownCloud, Syncthing'),
          onTap: () => _showSyncSetupWizard(context),
        ),
        FutureBuilder<bool>(
          future: SyncService().testWebdavConnection(),
          builder: (context, snapshot) {
            final connected = snapshot.data ?? false;
            return ListTile(
              leading: Icon(connected ? Icons.cloud_done : Icons.cloud_off),
              title: const Text('Auto Sync'),
              subtitle: Text(connected ? 'Connected' : 'Not connected'),
              trailing: Switch(
                value: SyncService().autoSyncEnabled,
                onChanged: connected ? (v) => SyncService().setAutoSync(v) : null,
              ),
            );
          },
        ),
      ],
    );
  }

  void _showLocalSyncDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Local Folder Sync'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Path',
            hintText: '/path/to/sync/folder',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await SyncService().setSyncFolder(controller.text);
              await SyncService().setProvider(SyncProvider.local);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Local sync configured!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSyncSetupWizard(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _SyncSetupWizard(),
    );
  }

  Widget _buildNotificationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Enable Notifications'),
          subtitle: const Text('Get reminders for your tasks'),
          trailing: FutureBuilder<bool>(
            future: Future.value(NotificationService().isEnabled),
            builder: (context, snapshot) {
              final enabled = snapshot.data ?? true;
              return Switch(
                value: enabled,
                onChanged: (value) async {
                  if (value) {
                    await NotificationService().requestPermissions();
                  }
                  await NotificationService().setEnabled(value);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'Notifications enabled' : 'Notifications disabled',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'About',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Life Plans'),
          subtitle: const Text('Version 1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('Open Source'),
          subtitle: const Text('Free and open source software'),
        ),
        const ListTile(
          leading: Icon(Icons.gavel),
          title: Text('License'),
          subtitle: Text('GNU General Public License v3.0'),
        ),
        const ListTile(
          leading: Icon(Icons.description),
          title: Text('GPL v3 Details'),
          subtitle: Text('This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License.'),
        ),
        const ListTile(
          leading: Icon(Icons.privacy_tip),
          title: Text('Privacy'),
          subtitle: Text('No data collection - all data stored locally'),
        ),
      ],
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeProvider.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                themeProvider.setThemeMode(selection.first);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncSetupWizard extends StatefulWidget {
  const _SyncSetupWizard();

  @override
  State<_SyncSetupWizard> createState() => _SyncSetupWizardState();
}

class _SyncSetupWizardState extends State<_SyncSetupWizard> {
  int _step = 0;
  CloudProvider _selectedProvider = CloudProvider.nextcloud;
  final _serverController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _isCustomUrl = false;
  final _customUrlController = TextEditingController();
  bool _isLoading = false;
  bool? _connectionSuccess;

  @override
  void dispose() {
    _serverController.dispose();
    _userController.dispose();
    _passController.dispose();
    _customUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_step == 0 ? 'Cloud Setup' : _step == 1 ? 'Server Details' : 'Connect'),
      content: SizedBox(
        width: 400,
        child: _step == 0 ? _buildProviderSelection() : _buildServerDetails(),
      ),
      actions: [
        if (_step > 0)
          TextButton(
            onPressed: () => setState(() => _step--),
            child: const Text('Back'),
          ),
        if (_step < 2)
          FilledButton(
            onPressed: _isLoading ? null : () => setState(() => _step++),
            child: const Text('Next'),
          ),
        if (_step == 2)
          FilledButton(
            onPressed: _isLoading ? null : _testAndSave,
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Connect'),
          ),
      ],
    );
  }

  Widget _buildProviderSelection() {
    final providers = [
      (CloudProvider.nextcloud, 'Nextcloud', 'https://nextcloud.com', Icons.cloud),
      (CloudProvider.owncloud, 'ownCloud', 'https://owncloud.com', Icons.cloud),
      (CloudProvider.syncthing, 'Syncthing', 'https://syncthing.net', Icons.sync),
      (CloudProvider.filerun, 'FileRun', 'https://filerun.com', Icons.folder),
      (CloudProvider.seafile, 'Seafile', 'https://www.seafile.com', Icons.storage),
      (CloudProvider.custom, 'Custom WebDAV', null, Icons.link),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select your cloud provider:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 16),
        ...providers.map((p) => RadioListTile<CloudProvider>(
          value: p.$1,
          groupValue: _selectedProvider,
          onChanged: (v) => setState(() {
            _selectedProvider = v!;
            _isCustomUrl = v == CloudProvider.custom;
          }),
          title: Text(p.$2),
          subtitle: p.$3 != null ? Text(p.$3!, style: const TextStyle(fontSize: 12)) : null,
          secondary: Icon(p.$4),
          contentPadding: EdgeInsets.zero,
        )),
      ],
    );
  }

  Widget _buildServerDetails() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isCustomUrl)
          TextField(
            controller: _customUrlController,
            decoration: const InputDecoration(
              labelText: 'WebDAV URL',
              hintText: 'https://your-server.com/webdav/',
            ),
          )
        else ...[
          TextField(
            controller: _serverController,
            decoration: InputDecoration(
              labelText: '${cloudPresets[_selectedProvider]?.name ?? 'Server'} URL',
              hintText: _selectedProvider == CloudProvider.nextcloud 
                  ? 'https://cloud.example.com'
                  : 'https://your-server.com',
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _userController,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        if (_connectionSuccess != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _connectionSuccess! ? Icons.check_circle : Icons.error,
                color: _connectionSuccess! ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _connectionSuccess! ? 'Connection successful!' : 'Connection failed',
                style: TextStyle(color: _connectionSuccess! ? Colors.green : Colors.red),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _testAndSave() async {
    setState(() {
      _isLoading = true;
      _connectionSuccess = null;
    });

    String url;
    if (_isCustomUrl) {
      url = _customUrlController.text;
    } else {
      final preset = cloudPresets[_selectedProvider];
      final server = _serverController.text.endsWith('/') 
          ? _serverController.text.substring(0, _serverController.text.length - 1)
          : _serverController.text;
      url = preset?.buildUrl(server, _userController.text) ?? server;
    }

    await SyncService().configureWebdav(
      url: url,
      username: _userController.text,
      password: _passController.text,
    );

    final success = await SyncService().testWebdavConnection();
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _connectionSuccess = success;
      });

      if (success) {
        await SyncService().setProvider(SyncProvider.webdav);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${_isCustomUrl ? "WebDAV" : cloudPresets[_selectedProvider]?.name}!')),
          );
        }
      }
    }
  }
}
