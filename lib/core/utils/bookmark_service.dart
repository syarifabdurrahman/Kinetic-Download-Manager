import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final String url;
  final String title;
  final DateTime addedAt;

  Bookmark({required this.url, required this.title, DateTime? addedAt})
      : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'url': url,
    'title': title,
    'addedAt': addedAt.toIso8601String(),
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    url: json['url'],
    title: json['title'],
    addedAt: DateTime.parse(json['addedAt']),
  );
}

class BookmarkService {
  static const _key = 'bookmarks';

  static Future<List<Bookmark>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final list = jsonDecode(data) as List;
    return list.map((e) => Bookmark.fromJson(e)).toList();
  }

  static Future<void> add(Bookmark b) async {
    final list = await getAll();
    list.removeWhere((x) => x.url == b.url);
    list.insert(0, b);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> remove(String url) async {
    final list = await getAll();
    list.removeWhere((x) => x.url == url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<bool> exists(String url) async {
    final list = await getAll();
    return list.any((x) => x.url == url);
  }
}
