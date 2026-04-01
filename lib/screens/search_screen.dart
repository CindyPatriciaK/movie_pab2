import 'package:flutter/material.dart';
import 'package:flutter_daftar_movie/models/movie.dart';
import 'package:flutter_daftar_movie/services/api_services.dart';
import 'package:flutter_daftar_movie/screens/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Movie> _movies = [];
  bool _loading = false;

  Future<void> searchMovie(String query) async {
    if (query.isEmpty) {
      setState(() {
        _movies = [];
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    final result = await _apiService.searchMovies(query);

    setState(() {
      _movies = result.map((e) => Movie.fromJson(e)).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Movie")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: searchMovie,
              decoration: InputDecoration(
                hintText: "Cari film...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 10),

            _loading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _movies.length,
                      itemBuilder: (context, index) {
                        final movie = _movies[index];

                        return ListTile(
                          leading: Image.network(
                            "https://image.tmdb.org/t/p/w200${movie.posterPath}",
                            width: 50,
                            fit: BoxFit.cover,
                          ),

                          title: Text(movie.title),

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailScreen(movie: movie),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
