// ==============================================================================
// Storage Service (Local Persistence via Hive)
// File: lib/data/services/storage_service.dart
//
// Handles offline-first persistence for all Qayds and subject folders.
// Stores serialized JSON maps without needing complicated code generation.
// ==============================================================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/qayd_model.dart';
import '../models/folder_model.dart';

class StorageService {
  static const String _qaydsBoxName = 'qayds_box';
  static const String _foldersBoxName = 'folders_box';

  late Box<Map> _qaydsBox;
  late Box<Map> _foldersBox;

  /// Initializes Hive database and opens the necessary boxes
  Future<void> init() async {
    await Hive.initFlutter();
    _qaydsBox = await Hive.openBox<Map>(_qaydsBoxName);
    _foldersBox = await Hive.openBox<Map>(_foldersBoxName);
  }

  // ---------------------------------------------------------------------------
  // Qayd Operations (FR6, NFR9)
  // ---------------------------------------------------------------------------

  /// Saves or updates a Qayd in local storage
  Future<void> saveQayd(Qayd qayd) async {
    await _qaydsBox.put(qayd.id, qayd.toMap());
  }

  /// Retrieves a specific Qayd by its unique ID
  Qayd? getQayd(String id) {
    final map = _qaydsBox.get(id);
    if (map == null) return null;
    return Qayd.fromMap(Map<String, dynamic>.from(map));
  }

  /// Returns all saved Qayds sorted newest-first (FR6)
  List<Qayd> getAllQayds() {
    final qayds = <Qayd>[];
    for (final raw in _qaydsBox.values) {
      try {
        qayds.add(Qayd.fromMap(Map<String, dynamic>.from(raw)));
      } catch (e) {
        debugPrint('Error parsing Qayd from storage: $e');
      }
    }
    // Sort descending by creation date (newest first)
    qayds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return qayds;
  }

  /// Deletes a Qayd and removes its local audio file to prevent orphan files (NFR9)
  Future<void> deleteQayd(String id) async {
    final qayd = getQayd(id);
    if (qayd != null && qayd.audioPath.isNotEmpty) {
      try {
        final file = File(qayd.audioPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Could not delete audio file: $e');
      }
    }
    await _qaydsBox.delete(id);
  }

  /// Filters Qayds by subject folder
  List<Qayd> getQaydsByFolder(String? folderId) {
    return getAllQayds().where((q) => q.folderId == folderId).toList();
  }

  // ---------------------------------------------------------------------------
  // Folder Operations (NFR10)
  // ---------------------------------------------------------------------------

  /// Saves a subject folder
  Future<void> saveFolder(QaydFolder folder) async {
    await _foldersBox.put(folder.id, folder.toMap());
  }

  /// Returns all folders sorted alphabetically by name
  List<QaydFolder> getAllFolders() {
    final folders = <QaydFolder>[];
    for (final raw in _foldersBox.values) {
      try {
        folders.add(QaydFolder.fromMap(Map<String, dynamic>.from(raw)));
      } catch (e) {
        debugPrint('Error parsing folder: $e');
      }
    }
    folders.sort((a, b) => a.name.compareTo(b.name));
    return folders;
  }

  /// Deletes a folder and unfiles all its Qayds safely
  Future<void> deleteFolder(String folderId) async {
    // Unassign all Qayds in this folder before deleting it
    for (final qayd in getQaydsByFolder(folderId)) {
      final updated = qayd.copyWith(folderId: null);
      await saveQayd(updated);
    }
    await _foldersBox.delete(folderId);
  }
}
