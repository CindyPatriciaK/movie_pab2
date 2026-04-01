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

  bool _loading = true;

  final ScrollController _trendingController = ScrollController();
  final ScrollController _popularController = ScrollController();
  final ScrollController _allController = ScrollController();

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
    _trendingController.dispose();
    _popularController.dispose();
    _allController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Daftar Film',
          style: TextStyle(color: Colors.black87),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSection('Trending', _trendingMovies, _trendingController),

                _buildSection('Popular', _popularMovies, _popularController),

                _buildSection('All Movies', _allMovies, _allController),

                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
    );
  }

  SliverToBoxAdapter _buildSection(
    String title,
    List<Movie> movies,
    ScrollController controller,
  ) {
    if (movies.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

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
                  controller: controller,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: movies.length,
                  itemBuilder: (context, index) {
                    final movie = movies[index];

                    return _movieCard(movie);
                  },
                ),

                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _scrollHorizontally(controller, -200),
                  ),
                ),

                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _scrollHorizontally(controller, 200),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DetailScreen(movie: movie)),
          );
        },

        child: SizedBox(
          width: 140,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              SizedBox(
                height: 210,

                child: Card(
                  clipBehavior: Clip.hardEdge,
                  elevation: 4,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: Image.network(
                    'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                    fit: BoxFit.cover,

                    errorBuilder: (c, e, s) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, size: 50),
                      );
                    },
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
