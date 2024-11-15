import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:http/http.dart' as http;

class RickAndMortyCharactersPage extends StatefulWidget {
  const RickAndMortyCharactersPage({super.key});

  @override
  _RickAndMortyCharactersPageState createState() =>
      _RickAndMortyCharactersPageState();
}

class _RickAndMortyCharactersPageState
    extends State<RickAndMortyCharactersPage> {

  final PagingController<int, Map<String, String>> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://rickandmortyaapi.com/api/charaacter?page=$pageKey'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];

        final characters = results.map<Map<String, String>>((character) {
          return {
            'name': character['name'],
            'image': character['image'],
          };
        }).toList();

        final isLastPage = pageKey >= data['info']['pages'];
        if (isLastPage) {
          _pagingController.appendLastPage(characters);
        } else {
          final nextPageKey = pageKey + 1;
          _pagingController.appendPage(characters, nextPageKey);
        }
      } else {
        throw Exception('Failed to load characters');
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rick and Morty Characters'),
      ),
      body: PagedListView<int, Map<String, String>>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Map<String, String>>(
          itemBuilder: (context, item, index) => ListTile(
            leading: Image.network(
              item['image']!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(item['name']!),
          ),
        ),
      ),
    );
  }
}
