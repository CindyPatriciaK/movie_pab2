import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/movie.dart';

class FavoriteService {
  static const String _key = 'favorites';

  // Get list of favorite movies
  static Future<List<Movie>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key) ?? [];
    return jsonList
        .map((jsonStr) => Movie.fromJson(json.decode(jsonStr)))
        .toList();
  }

  // Add movie to favorites (if not already added)
  static Future<bool> addMovie(Movie movie) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    if (favorites.any((m) => m.id == movie.id)) return false;
    favorites.add(movie);
    final jsonList = favorites.map((m) => json.encode(m.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
    return true;
  }

  // Remove movie from favorites
  static Future<bool> removeMovie(int movieId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();
    final initialLength = favorites.length;
    favorites.removeWhere((m) => m.id == movieId);
    final removed = initialLength != favorites.length;
    if (removed) {
      final jsonList = favorites.map((m) => json.encode(m.toJson())).toList();
      await prefs.setStringList(_key, jsonList);
    }
    return removed;
  }

  // Check if movie is favorite
  static Future<bool> isFavorite(int movieId) async {
    final favorites = await getFavorites();
    return favorites.any((m) => m.id == movieId);
  }
}
