import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_outfit.dart';

class VaultService {
  static const _key = 'wardrobe_vault';
  static VaultService? _instance;
  static VaultService get instance => _instance ??= VaultService._();
  VaultService._();

  Future<List<SavedOutfit>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw.map((s) => SavedOutfit.fromJsonString(s)).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> save(SavedOutfit outfit) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(_key) ?? [];
    all.removeWhere((s) {
      try {
        return SavedOutfit.fromJsonString(s).id == outfit.id;
      } catch (_) {
        return false;
      }
    });
    all.add(outfit.toJsonString());
    await prefs.setStringList(_key, all);
  }

  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getStringList(_key) ?? [];
    all.removeWhere((s) {
      try {
        return SavedOutfit.fromJsonString(s).id == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key, all);
  }

  Future<void> toggleFavorite(String id) async {
    final all = await loadAll();
    final idx = all.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    final updated = all[idx].copyWith(isFavorite: !all[idx].isFavorite);
    await save(updated);
  }

  Future<void> updateTags(String id, List<String> tags) async {
    final all = await loadAll();
    final idx = all.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    await save(all[idx].copyWith(tags: tags));
  }

  Future<int> count() async => (await loadAll()).length;

  Future<double> averageScore() async {
    final all = await loadAll();
    if (all.isEmpty) return 0;
    return all.map((o) => o.analysis.styleScore).reduce((a, b) => a + b) /
        all.length;
  }
}
