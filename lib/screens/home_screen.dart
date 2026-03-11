import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_daftar_movie/models/movie.dart';
import 'package:flutter_daftar_movie/services/api_services.dart';
import 'package:flutter_daftar_movie/screens/detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _search = TextEditingController();
  late final PageController _pageCtrl;
  late final ScrollController _scrollCtrl;

  List<Movie> _movies = [];
  List<Movie> _trending = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  // gradien yang dipakai berulang‑ulang
  final Gradient _purpleGradient = const LinearGradient(
    colors: [Color(0xFF5E35B1), Color(0xFF3949AB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.7);
    _scrollCtrl = ScrollController();
    _search.addListener(() => setState(() => _query = _search.text));
    _fetch();
  }

  @override
  void dispose() {
    _search.dispose();
    _pageCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _api.getAllMovies();
      final tr = await _api.getTrendingMovies();
      _movies = all.map((e) => Movie.fromJson(e)).toList();
      _trending = tr.map((e) => Movie.fromJson(e)).toList();
    } catch (e) {
      _error = e.toString();
    }
    setState(() => _loading = false);
  }

  List<Movie> get _filtered {
    if (_query.isEmpty) return _movies;
    return _movies
        .where((m) => m.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  bool get _showScrollToTop =>
      _scrollCtrl.hasClients && _scrollCtrl.offset > 300;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              mini: true,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.arrow_upward),
              onPressed: () => _scrollCtrl.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              ),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // appbar dengan gradasi, tidak hitam polos
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Movie', style: TextStyle(letterSpacing: 1)),
                background: Container(
                  decoration: BoxDecoration(gradient: _purpleGradient),
                ),
              ),
            ),

            // label “List Film” dengan gradasi dan ikon
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(gradient: _purpleGradient),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Center(
                  child: Text(
                    '🎬  List Movie',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // search bar nempel
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchHeader(controller: _search),
            ),

            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && _error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetch,
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),

            // poster trending dengan tombol kiri‑kanan
            if (!_loading && _error == null && _trending.isNotEmpty)
              SliverToBoxAdapter(child: _buildTrendingSlider()),

            // judul daftar
            if (!_loading && _error == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    _query.isEmpty ? 'Semua Film' : 'Hasil pencarian',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // grid film
            if (!_loading && _error == null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, idx) {
                    final m = _filtered[idx];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + idx * 50),
                      builder: (context, op, child) =>
                          Opacity(opacity: op, child: child),
                      child: _movieTile(m),
                    );
                  }, childCount: _filtered.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.62,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSlider() {
    return SizedBox(
      height: 160,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: _trending.length,
            itemBuilder: (context, i) {
              final m = _trending[i];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(movie: m)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://image.tmdb.org/t/p/w500${m.posterPath}',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
          // tombol kiri
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: () {
                  if (_pageCtrl.hasClients) {
                    final prev = (_pageCtrl.page ?? 0).round() - 1;
                    _pageCtrl.animateToPage(
                      prev.clamp(0, _trending.length - 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ),
          // tombol kanan
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: () {
                  if (_pageCtrl.hasClients) {
                    final next = (_pageCtrl.page ?? 0).round() + 1;
                    _pageCtrl.animateToPage(
                      next.clamp(0, _trending.length - 1),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _movieTile(Movie m) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(movie: m)),
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: m.posterPath ?? m.id.toString(),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w500${m.posterPath}',
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                m.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchHeader extends SliverPersistentHeaderDelegate {
  final TextEditingController controller;
  _SearchHeader({required this.controller});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Cari film...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 60;
  @override
  double get minExtent => 60;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}
