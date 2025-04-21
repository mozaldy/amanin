// lib/screens/news_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({Key? key}) : super(key: key);

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final String _apiKey = "2f735fe900444826a039327990ea391e";
  final List<String> _crimeTypes = [
    'Maling',
    'Jambret',
    'Kekerasan',
    'Perusakan',
    'Pembohongan',
    'Kecelakaan',
    'Narkoba',
  ];

  List<dynamic> _newsArticles = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCrimeType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Build query based on selected crime type
      String query = 'DPR';
      // if (_selectedCrimeType != 'All') {
      //   query += ' ${_selectedCrimeType}';
      // } else {
      //   // If "All" is selected, include all crime types in the query
      //   query += ' (${_crimeTypes.join(' OR ')})';
      // }

      // Build the API URL
      final url = Uri.parse(
        'https://newsapi.org/v2/everything?'
        'q=$query&'
        'language=id&'
        'sortBy=publishedAt&'
        'apiKey=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'ok') {
          setState(() {
            _newsArticles = data['articles'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to fetch news';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openArticle(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open article: $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita Surabaya hari ini'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchNews),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading news',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchNews, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_newsArticles.isEmpty) {
      return const Center(
        child: Text('No news articles found', style: TextStyle(fontSize: 18.0)),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Showing news about ${_selectedCrimeType == 'All' ? 'all crimes' : _selectedCrimeType} in Surabaya',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchNews,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _newsArticles.length,
              itemBuilder: (context, index) {
                final article = _newsArticles[index];
                return _buildNewsCard(article);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(dynamic article) {
    // Format the publication date
    DateTime? publishedAt;
    try {
      publishedAt = DateTime.parse(article['publishedAt']);
    } catch (e) {
      publishedAt = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0, left: 8.0, right: 8.0),
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          if (article['url'] != null) {
            _openArticle(article['url']);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article['urlToImage'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4.0),
                ),
                child: Image.network(
                  article['urlToImage'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? 'No title',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    article['description'] ?? 'No description available',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          article['source']['name'] ?? 'Unknown source',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      if (publishedAt != null)
                        Text(
                          DateFormat(
                            'MMM dd, yyyy - HH:mm',
                          ).format(publishedAt),
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.0,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter News'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Crime Type'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCrimeType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'All',
                      child: Text('All'),
                    ),
                    ..._crimeTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCrimeType = value!;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchNews();
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }
}
