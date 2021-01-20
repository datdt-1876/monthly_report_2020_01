import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bloc_base/src/bloc/blocs.dart';
import 'package:flutter_bloc_base/src/bloc/movie_bloc/movie_event.dart';
import 'package:flutter_bloc_base/src/bloc/movie_bloc/movie_state.dart';
import 'package:flutter_bloc_base/src/data/repository/movie_repository_impl.dart';
import 'package:flutter_bloc_base/src/models/movie.dart';
import 'package:flutter_bloc_base/src/ui/detail/detail_screen.dart';
import 'package:flutter_bloc_base/src/ui/widget/error_page.dart';

class CustomSearchDelegate extends SearchDelegate {
  final List<Movie> _movieList = [];
  final ScrollController _scrollController = ScrollController();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        _scrollController.dispose();
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Text('');
  }

  @override
  Widget buildResults(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return MovieBloc(MovieRepositoryImpl())
          ..add(
            FetchMoviesByQueryString(query),
          );
      },
      child: _createMovieResult(context),
    );
  }

  Widget _createMovieResult(BuildContext context) {
    return BlocBuilder<MovieBloc, MovieState>(
      builder: (context, state) {
        if (state is MovieInit) {
          return Center(child: const CircularProgressIndicator());
        } else if (state is MovieFetchError) {
          return ErrorPage(
            message: state.message,
            retry: () {
              context.watch<MovieBloc>()..add(FetchMoviesByQueryString(query));
            },
          );
        } else if (state is MoviesByQueryFetched) {
          _movieList.addAll(state.movies);
          return _movieListResult(context, _movieList);
        } else {
          return Text('Not supported');
        }
      },
    );
  }

  // @override
  // List<Widget> buildActions(BuildContext context) => [];

  Widget _movieListResult(BuildContext context, movies) {
    return ListView.builder(
      controller: _scrollController
        ..addListener(() {
          if (_scrollController.offset ==
                  _scrollController.position.maxScrollExtent &&
              !BlocProvider.of<MovieBloc>(context).isEnd) {
            BlocProvider.of<MovieBloc>(context)
              ..add(FetchMoviesByQueryString(query));
          }
        }),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        var movie = movies[index];
        return ListTile(
          // leading: ConstrainedBox(
          //   constraints: BoxConstraints(
          //     minWidth: 44,
          //     minHeight: 44,
          //     maxWidth: 64,
          //     maxHeight: 64,
          //   ),
          //   child: CachedNetworkImage(
          //     placeholder: (context, url) => Center(
          //       child: CircularProgressIndicator(),
          //     ),
          //     imageUrl: 'https://image.tmdb.org/t/p/w500${movie.backdropPath}',
          //     width: double.infinity,
          //     height: double.infinity,
          //     fit: BoxFit.cover,
          //   ),
          // ),
          title: Text('$index ${movie.title}'),
          onTap: () async {
            print(movie.id);
            print(movie.title);
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) {
                return DetailScreen(movie: movie);
              }),
            );
            // close(context, null);
          },
        );
      },
    );
  }
}
