// lib/screens/home_screen.dart

import 'dart:async';
import 'package:amanin/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  String _selectedCrimeType = 'All';
  int _selectedSeverity = 0; // 0 means all severities
  bool _isMapLoaded = false;
  PostModel? _selectedPost;

  // Default camera position - can be updated based on user location
  static const CameraPosition _defaultLocation = CameraPosition(
    target: LatLng(-6.2088, 106.8456), // Default to Jakarta, Indonesia
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    // Initialize posts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final user = userProvider.user;
    final posts = postProvider.posts;

    // Update markers whenever posts change
    if (posts.isNotEmpty && _isMapLoaded) {
      _updateMarkers(posts);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crime Tracker'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context, posts);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _defaultLocation,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              setState(() {
                _isMapLoaded = true;
              });
              if (posts.isNotEmpty) {
                _updateMarkers(posts);
                _fitBounds(posts);
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Loading indicator
          if (postProvider.isLoading && posts.isEmpty)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),

          // Bottom card for showing post details when selected
          if (_selectedPost != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedPost!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedPost = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildCrimeInfo(
                        Icons.category,
                        'Type: ${_selectedPost!.crimeType}',
                      ),
                      _buildCrimeInfo(
                        Icons.access_time,
                        'Date: ${DateFormat('MMM dd, yyyy - HH:mm').format(_selectedPost!.timestamp)}',
                      ),
                      _buildCrimeInfo(
                        Icons.location_on,
                        'Location: ${_selectedPost!.location}',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Severity: ',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          ...List.generate(
                            5,
                            (index) => Icon(
                              Icons.circle,
                              size: 12.0,
                              color:
                                  index < _selectedPost!.severity
                                      ? AppTheme.getSeverityColor(
                                        _selectedPost!.severity,
                                      )
                                      : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedPost!.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate to detail screen or show full post
                            _showPostDetailDialog(context, _selectedPost!);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Welcome message and stats overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: AppTheme.cardBackground.withOpacity(0.9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Telah terjadi ${_getFilteredPosts(posts).length} insiden hari ini.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.my_location),
        onPressed: () {
          _repositionMap(posts);
        },
      ),
    );
  }

  Widget _buildCrimeInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[300], fontSize: 14)),
        ],
      ),
    );
  }

  void _updateMarkers(List<PostModel> posts) {
    final filteredPosts = _getFilteredPosts(posts);

    // Create markers for each post with coordinates
    setState(() {
      _markers =
          filteredPosts.where((post) => post.coordinates != null).map((post) {
            final latLng = LatLng(
              post.coordinates!.latitude,
              post.coordinates!.longitude,
            );

            return Marker(
              markerId: MarkerId(post.id),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(post.severity),
              ),
              infoWindow: InfoWindow(
                title: post.title,
                snippet: post.crimeType,
              ),
              onTap: () {
                setState(() {
                  _selectedPost = post;
                });
              },
            );
          }).toSet();
    });
  }

  double _getMarkerColor(int severity) {
    switch (severity) {
      case 1:
        return BitmapDescriptor.hueGreen;
      case 2:
        return BitmapDescriptor.hueAzure;
      case 3:
        return BitmapDescriptor.hueYellow;
      case 4:
        return BitmapDescriptor.hueOrange;
      case 5:
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueViolet;
    }
  }

  Future<void> _fitBounds(List<PostModel> posts) async {
    if (posts.isEmpty || !_isMapLoaded) return;

    final filteredPosts =
        _getFilteredPosts(
          posts,
        ).where((post) => post.coordinates != null).toList();

    if (filteredPosts.isEmpty) return;

    // If there's only one post, zoom to it
    if (filteredPosts.length == 1) {
      final post = filteredPosts.first;
      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(post.coordinates!.latitude, post.coordinates!.longitude),
          15, // Zoom level
        ),
      );
      return;
    }

    // Find bounds for all posts
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;

    for (final post in filteredPosts) {
      final lat = post.coordinates!.latitude;
      final lng = post.coordinates!.longitude;

      minLat = minLat > lat ? lat : minLat;
      maxLat = maxLat < lat ? lat : maxLat;
      minLng = minLng > lng ? lng : minLng;
      maxLng = maxLng < lng ? lng : maxLng;
    }

    // Add padding to bounds
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.01, minLng - 0.01),
      northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
    );

    final controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _repositionMap(List<PostModel> posts) async {
    await _fitBounds(posts);
  }

  List<PostModel> _getFilteredPosts(List<PostModel> allPosts) {
    return allPosts.where((post) {
      // Filter by crime type
      final typeMatch =
          _selectedCrimeType == 'All' || post.crimeType == _selectedCrimeType;

      // Filter by severity
      final severityMatch =
          _selectedSeverity == 0 || post.severity == _selectedSeverity;

      return typeMatch && severityMatch;
    }).toList();
  }

  void _showFilterDialog(BuildContext context, List<PostModel> posts) {
    // Get unique crime types
    final crimeTypes = [
      'All',
      ...{...posts.map((p) => p.crimeType)},
    ];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Filter Incidents'),
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
                      items:
                          crimeTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCrimeType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Severity'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedSeverity,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text('All'),
                        ),
                        ...List.generate(5, (index) {
                          return DropdownMenuItem<int>(
                            value: index + 1,
                            child: Row(
                              children: [
                                Text('Level ${index + 1}'),
                                const SizedBox(width: 8),
                                ...List.generate(
                                  index + 1,
                                  (_) => Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: AppTheme.getSeverityColor(index + 1),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSeverity = value!;
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
                      // Update the map with the filtered results
                      if (_isMapLoaded) {
                        _updateMarkers(posts);
                        _fitBounds(posts);
                      }
                    },
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showPostDetailDialog(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Incident Details Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.getSeverityColor(post.severity),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Severity: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              ...List.generate(
                                5,
                                (index) => Icon(
                                  Icons.circle,
                                  size: 10,
                                  color:
                                      index < post.severity
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Type:', post.crimeType, Icons.category),
                  _buildDetailItem(
                    'Date:',
                    DateFormat('MMM dd, yyyy - HH:mm').format(post.timestamp),
                    Icons.access_time,
                  ),
                  _buildDetailItem(
                    'Location:',
                    post.location,
                    Icons.location_on,
                  ),
                  _buildDetailItem(
                    'Reported by:',
                    post.authorName,
                    Icons.person,
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(post.description),
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Image:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.imageUrl!,
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[800],
                                  child: const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.white,
                                      size: 50,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$label ',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
