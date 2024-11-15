import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pagination_example/web_socket/live_score.dart';

class Country {
  final String id;
  final String name;
  final String logo;

  Country({
    required this.id,
    required this.name,
    required this.logo,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['country_id'],
      name: json['country_name'],
      logo: json['country_logo'],
    );
  }
}

class CountryListWidget extends StatefulWidget {
  const CountryListWidget({super.key});

  @override
  _CountryListWidgetState createState() => _CountryListWidgetState();
}

class _CountryListWidgetState extends State<CountryListWidget> {
  List<Country> countries = [];
  bool isLoading = true;
  String? error;
  final String apiKey = '12e247bda0d087114957894c9b50f2417c5c51bdd248642fa3a8c60e7adeea8e';

  @override
  void initState() {
    super.initState();
    fetchCountries();
  }

  Future<void> fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('https://apiv3.apifootball.com/?action=get_countries&APIkey=$apiKey'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          countries = jsonData.map((data) => Country.fromJson(data)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load countries: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Error loading countries: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshCountries() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    await fetchCountries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Football Countries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sports_soccer),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LiveScoreWidget(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshCountries,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshCountries,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : countries.isEmpty
                    ? const Center(child: Text('No countries available'))
                    : ListView.builder(
                        itemCount: countries.length,
                        itemBuilder: (context, index) {
                          final country = countries[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            elevation: 2,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  country.logo,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.flag,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                country.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('ID: ${country.id}'),
                              onTap: () {
                                // Navigate to country-specific live scores
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Loading matches for ${country.name}...'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                                // You can add navigation to country-specific scores here
                              },
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}