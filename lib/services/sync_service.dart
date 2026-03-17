import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/category.dart';
import 'database_service.dart';

enum SyncProvider {
  local,
  webdav,
  icloud,
}

enum CloudProvider {
  custom,
  nextcloud,
  owncloud,
  syncthing,
  filerun,
  seafile,
}

class CloudProviderPreset {
  final String name;
  final String davPath;
  final bool needsUsernameInUrl;

  const CloudProviderPreset({
    required this.name,
    required this.davPath,
    this.needsUsernameInUrl = false,
  });

  String buildUrl(String serverUrl, String username) {
    final base = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    if (needsUsernameInUrl) {
      return '$base$davPath/$username/';
    }
    return '$base$davPath/';
  }
}

const Map<CloudProvider, CloudProviderPreset> cloudPresets = {
  CloudProvider.nextcloud: CloudProviderPreset(
    name: 'Nextcloud',
    davPath: '/remote.php/dav/files',
    needsUsernameInUrl: true,
  ),
  CloudProvider.owncloud: CloudProviderPreset(
    name: 'ownCloud',
    davPath: '/remote.php/dav/files',
    needsUsernameInUrl: true,
  ),
  CloudProvider.syncthing: CloudProviderPreset(
    name: 'Syncthing',
    davPath: '/',
    needsUsernameInUrl: false,
  ),
  CloudProvider.filerun: CloudProviderPreset(
    name: 'FileRun',
    davPath: '/dav/files',
    needsUsernameInUrl: true,
  ),
  CloudProvider.seafile: CloudProviderPreset(
    name: 'Seafile',
    davPath: '/seafdav',
    needsUsernameInUrl: false,
  ),
};

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _syncProviderKey = 'sync_provider';
  static const String _syncFolderKey = 'sync_folder_path';
  static const String _webdavUrlKey = 'webdav_url';
  static const String _webdavUserKey = 'webdav_user';
  static const String _webdavPassKey = 'webdav_pass';
  static const String _autoSyncKey = 'auto_sync_enabled';
  
  SyncProvider _provider = SyncProvider.local;
  String? _customSyncPath;
  String? _webdavUrl;
  String? _webdavUser;
  String? _webdavPass;
  bool _autoSyncEnabled = false;
  DateTime? _lastExportTime;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _customSyncPath = prefs.getString(_syncFolderKey);
    _webdavUrl = prefs.getString(_webdavUrlKey);
    _webdavUser = prefs.getString(_webdavUserKey);
    _webdavPass = prefs.getString(_webdavPassKey);
    _autoSyncEnabled = prefs.getBool(_autoSyncKey) ?? false;
    
    final providerIndex = prefs.getInt(_syncProviderKey) ?? 0;
    _provider = SyncProvider.values[providerIndex];
  }

  SyncProvider get provider => _provider;
  bool get autoSyncEnabled => _autoSyncEnabled;

  Future<void> setProvider(SyncProvider provider) async {
    _provider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncProviderKey, provider.index);
  }

  Future<void> setAutoSync(bool enabled) async {
    _autoSyncEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSyncKey, enabled);
  }

  Future<void> setSyncFolder(String path) async {
    _customSyncPath = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_syncFolderKey, path);
  }

  Future<void> configureWebdav({
    required String url,
    required String username,
    required String password,
  }) async {
    _webdavUrl = url;
    _webdavUser = username;
    _webdavPass = password;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webdavUrlKey, url);
    await prefs.setString(_webdavUserKey, username);
    await prefs.setString(_webdavPassKey, password);
  }

  Future<void> configureWithPreset({
    required CloudProvider preset,
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final presetConfig = cloudPresets[preset];
    if (presetConfig == null) return;

    final url = presetConfig.buildUrl(serverUrl, username);
    await configureWebdav(url: url, username: username, password: password);
  }

  Future<bool> testWebdavConnection() async {
    if (_webdavUrl == null || _webdavUser == null || _webdavPass == null) {
      return false;
    }

    try {
      final uri = Uri.parse(_webdavUrl!);
      final request = await HttpClient().headUrl(uri);
      request.headers.set('Authorization', 'Basic ${base64Encode(utf8.encode('$_webdavUser:$_webdavPass'))}');
      final response = await request.close();
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('WebDAV connection test failed: $e');
      return false;
    }
  }

  Future<String> get _defaultPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<String> get syncPath async {
    if (_provider == SyncProvider.local) {
      if (_customSyncPath != null && _customSyncPath!.isNotEmpty) {
        return _customSyncPath!;
      }
      return await _defaultPath;
    }
    // For cloud providers, use local cache
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/sync_cache';
  }

  Future<void> setCustomSyncPath(String? path) async {
    _customSyncPath = path;
    final prefs = await SharedPreferences.getInstance();
    if (path != null && path.isNotEmpty) {
      await prefs.setString(_syncFolderKey, path);
    } else {
      await prefs.remove(_syncFolderKey);
    }
  }

  Future<bool> shouldAutoSync() async {
    if (!_autoSyncEnabled) return false;
    if (_lastExportTime != null) {
      final diff = DateTime.now().difference(_lastExportTime!);
      if (diff.inSeconds < 5) return false;
    }
    return true;
  }

  Future<void> exportData(List<Task> tasks, List<Category> categories) async {
    final path = await syncPath;
    final tasksJson = jsonEncode(tasks.map((t) => t.toMap()).toList());
    final categoriesJson = jsonEncode(categories.map((c) => c.toMap()).toList());

    // Save locally first
    final tasksFile = File('$path/life_plans_tasks.json');
    final categoriesFile = File('$path/life_plans_categories.json');
    await tasksFile.writeAsString(tasksJson);
    await categoriesFile.writeAsString(categoriesJson);

    // Upload to cloud if configured
    if (_provider == SyncProvider.webdav && _webdavUrl != null) {
      await _uploadToWebdav('life_plans_tasks.json', tasksJson);
      await _uploadToWebdav('life_plans_categories.json', categoriesJson);
    }
    
    _lastExportTime = DateTime.now();
  }

  Future<void> _uploadToWebdav(String filename, String content) async {
    if (_webdavUrl == null || _webdavUser == null || _webdavPass == null) return;
    
    try {
      final uri = Uri.parse('$_webdavUrl/$filename');
      final request = await HttpClient().putUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('Authorization', 'Basic ${base64Encode(utf8.encode('$_webdavUser:$_webdavPass'))}');
      request.write(content);
      await request.close();
    } catch (e) {
      debugPrint('WebDAV upload error: $e');
    }
  }

  Future<void> _downloadFromWebdav(String filename) async {
    if (_webdavUrl == null || _webdavUser == null || _webdavPass == null) return;
    
    try {
      final path = await syncPath;
      final uri = Uri.parse('$_webdavUrl/$filename');
      final request = await HttpClient().getUrl(uri);
      request.headers.set('Authorization', 'Basic ${base64Encode(utf8.encode('$_webdavUser:$_webdavPass'))}');
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final content = await response.transform(utf8.decoder).join();
        final file = File('$path/$filename');
        await file.writeAsString(content);
      }
    } catch (e) {
      debugPrint('WebDAV download error: $e');
    }
  }

  Future<bool> hasNewDataToImport() async {
    try {
      // Download from WebDAV if configured
      if (_provider == SyncProvider.webdav && _webdavUrl != null) {
        await _downloadFromWebdav('life_plans_tasks.json');
        await _downloadFromWebdav('life_plans_categories.json');
      }
      
      final path = await syncPath;
      final tasksFile = File('$path/life_plans_tasks.json');
      final categoriesFile = File('$path/life_plans_categories.json');
      
      if (!await tasksFile.exists() && !await categoriesFile.exists()) {
        return false;
      }
      
      final tasksModified = await tasksFile.lastModified();
      final categoriesModified = await categoriesFile.lastModified();
      
      final latest = tasksModified.isAfter(categoriesModified) ? tasksModified : categoriesModified;
      
      if (_lastExportTime == null) return true;
      return latest.isAfter(_lastExportTime!);
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> importTasks() async {
    try {
      final path = await syncPath;
      final file = File('$path/life_plans_tasks.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(contents);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error importing tasks: $e');
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> importCategories() async {
    try {
      final path = await syncPath;
      final file = File('$path/life_plans_categories.json');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(contents);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error importing categories: $e');
    }
    return [];
  }

  Future<String> getFullExportJson(List<Task> tasks, List<Category> categories) async {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
    };
    return jsonEncode(data);
  }
}
