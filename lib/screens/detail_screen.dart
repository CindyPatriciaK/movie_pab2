import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_daftar_movie/models/movie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailScreen extends StatefulWidget {
  final Movie movie;

  const DetailScreen({Key? key, required this.movie}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isRotated = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _loadFavoriteStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_movies') ?? [];
    setState(() {
      _isFavorite = favoriteIds.contains(widget.movie.id.toString());
    });
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_movies') ?? [];
    final movieId = widget.movie.id.toString();

    if (_isFavorite) {
      favoriteIds.remove(movieId);
    } else {
      favoriteIds.add(movieId);
    }

    await prefs.setStringList('favorite_movies', favoriteIds);
    setState(() => _isFavorite = !_isFavorite);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? '♥ Added to favorites' : 'Removed from favorites',
        ),
        backgroundColor: _isFavorite ? Colors.red : Colors.grey[700],
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  void _toggleRotation() {
    if (_isRotated) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isRotated = !_isRotated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backdrop = widget.movie.backdropPath ?? widget.movie.posterPath;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Shared 🚀'))),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://image.tmdb.org/t/p/w1280$backdrop',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) =>
                        Container(color: Colors.grey.shade800),
                  ),
                  Container(color: Colors.black45),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Hero(
                        tag: 'poster-${widget.movie.title}',
                        child: GestureDetector(
                          onTap: _toggleRotation,
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Container(
                                width: 180,
                                height: 270,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Transform(
                                    transform: Matrix4.rotationY(
                                      _animation.value * pi,
                                    ),
                                    alignment: Alignment.center,
                                    child: Image.network(
                                      'https://image.tmdb.org/t/p/w500${widget.movie.posterPath}',
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.movie,
                                          size: 50,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.redAccent : Colors.white,
                        size: 32,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(
              top: 100,
              left: 16,
              right: 16,
              bottom: 24,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  widget.movie.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.movie.releaseDate != null)
                      Chip(
                        label: Text(widget.movie.releaseDate!.substring(0, 4)),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            widget.movie.voteAverage != null
                                ? widget.movie.voteAverage!.toStringAsFixed(1)
                                : 'N/A',
                          ),
                        ],
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Synopsis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.movie.overview ?? 'No description available.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to watchlist!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('Watchlist'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Shared!')),
                          );
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.black54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Cast',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (c, i) => Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade300,
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
