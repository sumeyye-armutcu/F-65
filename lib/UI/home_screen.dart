import 'dart:ui' as ui;
import 'package:f65_app/service/model/movie.dart';
import 'package:f65_app/service/movie_service.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieService _movieService = MovieService();
  Movie? _randomMovie;
  int _characterLimit = 200;
  bool _isExpanded = false;
  Color _textColor = Colors.black;
  Future<ui.Image>? _imageFuture;

  @override
  void initState() {
    super.initState();
    _fetchRandomMovie();
  }

  @override
  void dispose() {
    _imageFuture = null; // Cancel the image loading future
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0.0,
        centerTitle: true,
        title: Text(
          'Movie Recommendation',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: _randomMovie != null
          ? FutureBuilder<ui.Image>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            final posterImage = snapshot.data!;
            return Stack(
              children: [
                Image.network(
                  _randomMovie!.getFullPosterUrl(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          image: DecorationImage(
                            image: NetworkImage(_randomMovie!.getFullPosterUrl()),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        _randomMovie!.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getDescriptionText(),
                            style: TextStyle(
                              fontSize: 16,
                              color: _textColor,
                            ),
                          ),
                          if (_randomMovie!.overview.length > _characterLimit)
                            Container(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isExpanded = !_isExpanded;
                                  });
                                },
                                child: Text(
                                  _isExpanded ? 'Show Less' : 'Show More',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.yellow),
                          SizedBox(width: 8),
                          Text(
                            _randomMovie!.voteAverage.toString(),
                            style: TextStyle(
                              fontSize: 16,
                              color: _textColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      )
          : Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.shuffle),
        onPressed: _fetchRandomMovie,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  String _getDescriptionText() {
    final overview = _randomMovie!.overview;
    if (overview.length <= _characterLimit || _isExpanded) {
      return overview;
    } else {
      return '${overview.substring(0, _characterLimit)}...';
    }
  }

  Future<void> _fetchRandomMovie() async {
    setState(() {
      _randomMovie = null;
      _isExpanded = false;
    });

    try {
      final Movie randomMovie = await _movieService.getRandomMovie();
      setState(() {
        _randomMovie = randomMovie;
        _imageFuture = _getImageFromNetwork(_randomMovie!.getFullPosterUrl());
      });
      _calculateTextColor();
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch a random movie. Please try again.'),
          actions: [
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.pop(context);
                _fetchRandomMovie();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<ui.Image> _getImageFromNetwork(String imageUrl) async {
    final image = NetworkImage(imageUrl);
    final completer = Completer<ui.Image>();
    final stream = image.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((info, _) {
      completer.complete(info.image);
    }));
    return completer.future;
  }

  Future<void> _calculateTextColor() async {
    final image = await _imageFuture;
    if (image != null) {
      final pixelData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final pixels = pixelData!.buffer.asUint8List();
      final dominantColor = _getDominantColor(pixels);
      final brightness = ThemeData.estimateBrightnessForColor(dominantColor);
      setState(() {
        _textColor = brightness == Brightness.light ? Colors.black : Colors.white;
      });
    }
  }

  Color _getDominantColor(List<int> pixels) {
    final colorCounts = Map<int, int>();
    final pixelCount = pixels.length ~/ 4;
    var maxCount = 0;
    var dominantColor = Color(0xFFFFFFFF);

    for (var i = 0; i < pixelCount; i++) {
      final red = pixels[i * 4];
      final green = pixels[i * 4 + 1];
      final blue = pixels[i * 4 + 2];
      final alpha = pixels[i * 4 + 3];
      final colorValue = (alpha << 24) | (red << 16) | (green << 8) | blue;
      final colorCount = colorCounts.containsKey(colorValue) ? colorCounts[colorValue]! + 1 : 1;
      colorCounts[colorValue] = colorCount;

      if (colorCount > maxCount) {
        maxCount = colorCount;
        dominantColor = Color(colorValue);
      }
    }

    return dominantColor;
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Movie Recommendation',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0.0,
        centerTitle: true,
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          },
          child: Icon(
            Icons.movie_creation_outlined,
            size: 100,
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoadingScreen(),
        '/main': (context) => MainScreen(),
      },
    );
  }
}
