import 'dart:math';

import 'package:dio/dio.dart';
import 'package:f65_app/service/model/movie.dart';

class MovieService {
  final Dio _dio = Dio();
  final String apiKey = '9bd4a9d583d1040c286b13b5eb6281fe';
  final String baseUrl = 'https://api.themoviedb.org/3/movie/top_rated';
  final String language = 'en-US';

  Future<Movie> getRandomMovie() async {
    try {
      final int totalPages = await _getTotalPages();
      final int randomPage = Random().nextInt(totalPages) + 1;
      final response = await _dio.get(
        baseUrl,
        queryParameters: {
          'api_key': apiKey,
          'language': language,
          'page': randomPage.toString(),
        },
      );

      final results = List<Map<String, dynamic>>.from(response.data['results']);
      final randomIndex = Random().nextInt(results.length);
      final randomMovieData = results[randomIndex];
      final movie = Movie(
        id: randomMovieData['id'],
        title: randomMovieData['title'],
        overview: randomMovieData['overview'],
        voteAverage: randomMovieData['vote_average'].toDouble(),
        posterPath: randomMovieData['poster_path'],
      );

      return movie;
    } catch (error) {
      throw Exception('Failed to fetch random movie');
    }
  }

  Future<int> _getTotalPages() async {
    try {
      final response = await _dio.get(
        baseUrl,
        queryParameters: {
          'api_key': apiKey,
          'language': language,
          'page': '1',
        },
      );
      return response.data['total_pages'];
    } catch (error) {
      throw Exception('Failed to fetch total pages');
    }
  }
}
