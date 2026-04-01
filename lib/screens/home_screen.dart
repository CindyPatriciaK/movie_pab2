import 'package:flutter/material.dart';
import 'package:flutter_daftar_movie/models/movie.dart';
import 'package:flutter_daftar_movie/screens/detail_screen.dart';
import 'package:flutter_daftar_movie/services/api_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<Movie> _allMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _searchResults = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  void _scrollHorizontally(ScrollController ctrl, double offset) {
    final max = ctrl.position.maxScrollExtent;
    final min = ctrl.position.minScrollExtent;
    final target = (ctrl.offset + offset).clamp(min, max);
    ctrl.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    final all = await _apiService.getAllMovies();
    final trending = await _apiService.getTrendingMovies();
    final popular = await _apiService.getPopularMovies();

    setState(() {
      _allMovies = all.map((e) => Movie.fromJson(e)).toList();
      _trendingMovies = trending.map((e) => Movie.fromJson(e)).toList();
      _popularMovies = popular.map((e) => Movie.fromJson(e)).toList();
      _loading = false;
    });
  }

  void _onSearchChanged(String q) {
    if (q.trim().isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _searchResults = _allMovies
          .where((m) => m.title.toLowerCase().contains(lower))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // APPBAR SUDAH DIPERBAIKI (tanpa icon love)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Daftar Film',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari judul film...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchResults.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                if (_searchResults.isNotEmpty) ...[
                  _buildSection('Search results', _searchResults),
                ] else ...[
                  _buildSection('Trending', _trendingMovies),
                  _buildSection('Popular', _popularMovies),
                  _buildSection('All Movies', _allMovies),
                ],

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  SliverToBoxAdapter _buildSection(String title, List<Movie> movies) {
    if (movies.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final ctrl = ScrollController();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                ListView.builder(
                  controller: ctrl,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: movies.length,
                  itemBuilder: (context, idx) {
                    final m = movies[idx];
                    return _movieCard(m);
                  },
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _scrollHorizontally(ctrl, -200),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _scrollHorizontally(ctrl, 200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _movieCard(Movie movie) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => DetailScreen(movie: movie))),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 210,
                child: Card(
                  clipBehavior: Clip.hardEdge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.movie, size: 50),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
