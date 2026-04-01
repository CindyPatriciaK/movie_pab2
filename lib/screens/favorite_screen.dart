import 'package:flutter/material.dart';
import 'package:flutter_daftar_movie/models/movie.dart';
import 'package:flutter_daftar_movie/screens/detail_screen.dart';
import 'package:flutter_daftar_movie/services/api_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final ApiService _apiService = ApiService();
  List<Movie> _favoriteMovies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_movies') ?? [];
    if (favoriteIds.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // Asumsi API bisa fetch by ID, atau load dari all movies
    final allMovies = await _apiService.getAllMovies();
    final favorites = allMovies
        .map((e) => Movie.fromJson(e))
        .where((m) => favoriteIds.contains(m.id.toString()))
        .toList();

    setState(() {
      _favoriteMovies = favorites;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Film Favorit',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteMovies.isEmpty
          ? const Center(child: Text('Belum ada film favorit'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _favoriteMovies.length,
              itemBuilder: (context, index) {
                final movie = _favoriteMovies[index];
                return _movieCard(movie);
              },
            ),
    );
  }

  Widget _movieCard(Movie movie) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => DetailScreen(movie: movie))),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                height: 150,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.movie,
                        color: Colors.white54,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movie.overview ?? 'No description',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
