// lib/screens/add_edit_post_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart' as geo;
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/user_provider.dart';
import '../app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditPostScreen extends StatefulWidget {
  final PostModel? post;

  const AddEditPostScreen({Key? key, this.post}) : super(key: key);

  @override
  _AddEditPostScreenState createState() => _AddEditPostScreenState();
}

class _AddEditPostScreenState extends State<AddEditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _crimeType = 'Maling';
  int _severity = 3;

  // Location variables
  final loc.Location _locationService = loc.Location();
  LatLng? _selectedLocation;
  bool _mapInitialized = false;
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  final List<String> _crimeTypes = [
    'Maling',
    'Jambret',
    'Kekerasan',
    'Perusakan',
    'Pembohongan',
    'Kecelakaan',
    'Narkoba',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _descriptionController.text = widget.post!.description;
      _locationController.text = widget.post!.location;
      _crimeType = widget.post!.crimeType;
      _severity = widget.post!.severity;

      // Set selected location if post has coordinates
      if (widget.post!.coordinates != null) {
        _selectedLocation = LatLng(
          widget.post!.coordinates!.latitude,
          widget.post!.coordinates!.longitude,
        );
      }
    }

    // Request location permissions
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await _locationService.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationService.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    loc.PermissionStatus permissionStatus =
        await _locationService.hasPermission();
    if (permissionStatus == loc.PermissionStatus.denied) {
      permissionStatus = await _locationService.requestPermission();
      if (permissionStatus != loc.PermissionStatus.granted) {
        return;
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _locationService.getLocation();
      setState(() {
        _selectedLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _updateMarkers();
      });

      // Move camera to the current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );

      // Get address for the location
      _getAddressFromLatLng(_selectedLocation!);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}, ${place.country}';
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to get address: $e, ${position.latitude} ${position.longitude}',
          ),
        ),
      );
    }
  }

  void _updateMarkers() {
    if (_selectedLocation == null) return;

    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selectedLocation'),
          position: _selectedLocation!,
          infoWindow: const InfoWindow(title: 'Selected Location'),
        ),
      );
    });
  }

  Future<void> _searchLocation() async {
    if (_searchController.text.isEmpty) return;

    try {
      List<geo.Location> locations = await geo.locationFromAddress(
        _searchController.text,
      );
      if (locations.isNotEmpty) {
        setState(() {
          _selectedLocation = LatLng(
            locations[0].latitude,
            locations[0].longitude,
          );
          _updateMarkers();
        });

        // Move camera to the searched location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
        );

        // Get formatted address
        _getAddressFromLatLng(_selectedLocation!);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Location not found: $e')));
    }
  }

  void _savePost() async {
    if (_formKey.currentState!.validate()) {
      // Check if location is selected
      if (_selectedLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final user = userProvider.user;

      if (user == null) return;

      final isEditing = widget.post != null;

      final PostModel post = PostModel(
        id: isEditing ? widget.post!.id : '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        timestamp: isEditing ? widget.post!.timestamp : DateTime.now(),
        authorId: isEditing ? widget.post!.authorId : user.uid,
        authorName: isEditing ? widget.post!.authorName : user.fullName,
        crimeType: _crimeType,
        severity: _severity,
        coordinates: GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        ),
      );

      bool success;
      if (isEditing) {
        success = await postProvider.updatePost(post);
      } else {
        success = await postProvider.createPost(post);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);
    final isEditing = widget.post != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Post' : 'Add New Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Select Location on Map',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),

              // Search location field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search location',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  ElevatedButton(
                    onPressed: _searchLocation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Map area
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target:
                            _selectedLocation ??
                            const LatLng(-6.2088, 106.8456), // Default Jakarta
                        zoom: 12,
                      ),
                      markers: _markers,
                      onMapCreated: (GoogleMapController controller) {
                        setState(() {
                          _mapController = controller;
                          _mapInitialized = true;
                        });
                        if (_selectedLocation != null) {
                          _updateMarkers();
                        }
                      },
                      onTap: (LatLng position) {
                        setState(() {
                          _selectedLocation = position;
                          _updateMarkers();
                        });
                        _getAddressFromLatLng(position);
                      },
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                    ),

                    // Current location button
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        heroTag: 'getCurrentLocation',
                        mini: true,
                        backgroundColor: AppTheme.primaryColor,
                        onPressed: _getCurrentLocation,
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 16.0),

              DropdownButtonFormField<String>(
                value: _crimeType,
                decoration: const InputDecoration(
                  labelText: 'Crime Type',
                  border: OutlineInputBorder(),
                ),
                items:
                    _crimeTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _crimeType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Severity',
                style: TextStyle(fontSize: 16.0, color: Colors.grey),
              ),
              const SizedBox(height: 8.0),
              Slider(
                value: _severity.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: 'Level $_severity',
                onChanged: (double value) {
                  setState(() {
                    _severity = value.round();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Low', style: TextStyle(color: Colors.grey)),
                  Text('Medium', style: TextStyle(color: Colors.grey)),
                  Text('High', style: TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 24.0),
              if (postProvider.error != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.red.withOpacity(0.1),
                  child: Text(
                    postProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: postProvider.isLoading ? null : _savePost,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child:
                      postProvider.isLoading
                          ? const CircularProgressIndicator()
                          : Text(isEditing ? 'Update' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
