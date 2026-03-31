import 'package:flutter/material.dart';
import 'package:flutter_daftar_movie/models/movie.dart';
import 'package:flutter_daftar_movie/screens/detail_screen.dart';
import 'package:flutter_daftar_movie/services/favorite_service.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  List<Movie> _favorites = [];
  bool _loading = true;

  final Gradient _purpleGradient = const LinearGradient(
    colors: [Color(0xFF5E35B1), Color(0xFF3949AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    try {
      _favorites = await FavoriteService.getFavorites();
    } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _removeFavorite(Movie movie) async {
    await FavoriteService.removeMovie(movie.id);
    setState(() => _favorites.remove(movie));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${movie.title} dihapus dari favorit')),
    );
  }

  bool get _showScrollToTop =>
      _scrollCtrl.hasClients && _scrollCtrl.offset > 300;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              backgroundColor: Colors.deepPurple,
              onPressed: () => _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ),
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Favorites',
                  style: TextStyle(letterSpacing: 1),
                ),
                background: Container(
                  decoration: BoxDecoration(gradient: _purpleGradient),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(gradient: _purpleGradient),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Center(
                  child: Text(
                    '💖 Film Favorit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_favorites.isEmpty && !_loading)
              SliverFillRemaining(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada film favorit',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.movie),
                      label: const Text('Lihat Film'),
                    ),
                  ],
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, idx) {
                  final m = _favorites[idx];
                  return TweenAnimationBuilder(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + idx * 50),
                    builder: (_, double opacity, __) => Opacity(
                      opacity: opacity,
                      child: Dismissible(
                        key: ValueKey(m.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          color: Colors.red,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        confirmDismiss: (_) => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Hapus Favorit?'),
                            content: Text(
                              '${m.title} akan dihapus dari favorit.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (_) => _removeFavorite(m),
                        child: _movieTile(m),
                      ),
                    ),
                  );
                }, childCount: _favorites.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _movieTile(Movie m) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => DetailScreen(movie: m))),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'poster_${m.id}',
                child: Image.network(
                  'https://image.tmdb.org/t/p/w500${m.posterPath}',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (c, e, st) => Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.movie,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                m.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
