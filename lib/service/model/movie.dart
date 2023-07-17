class Movie {
  final int id;
  final String title;
  final String overview;
  final double voteAverage;
  final String posterPath;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.voteAverage,
    required this.posterPath,
  });

  String getFullPosterUrl() {
    const String baseUrl = 'https://image.tmdb.org/t/p/w500';
    return baseUrl + posterPath;
  }
}
