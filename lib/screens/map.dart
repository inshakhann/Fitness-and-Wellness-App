import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapTilerCustomMap extends StatefulWidget {
  @override
  _MapTilerCustomMapState createState() => _MapTilerCustomMapState();
}

class _MapTilerCustomMapState extends State<MapTilerCustomMap> {
  final String mapTilerApiKey = 'm70LDWbNw82mlNSwgRoI'; // Replace with your MapTiler API key
  final String baseUrl = 'https://api.maptiler.com/maps/streets-v2'; // MapTiler base URL
  double zoom = 16.0; // Default zoom level
  double lat = 33.6844; // Latitude for Islamabad
  double lng = 73.0479; // Longitude for Islamabad

  final MapController _mapController = MapController();
  int _selectedIndex = 4; // Set the initial index to 4 for the Map screen

  void _zoomIn() {
    setState(() {
      if (zoom < 18.0) {
        zoom += 1.0;
        _mapController.move(LatLng(lat, lng), zoom);
      }
    });
  }

  void _zoomOut() {
    setState(() {
      if (zoom > 1.0) {
        zoom -= 1.0;
        _mapController.move(LatLng(lat, lng), zoom);
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/workout');
        break;
      case 2:
        Navigator.pushNamed(context, '/progress');
        break;
      case 3:
        Navigator.pushNamed(context, '/nutrition');
        break;
      case 4:
        Navigator.pushNamed(context, '/map');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Map',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1A32),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/home'); // Navigate to home screen
          },
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: zoom,
              maxZoom: 18.0,
              minZoom: 1.0,
            ),
            children: [
              TileLayer(
                urlTemplate: '$baseUrl/{z}/{x}/{y}.png?key=$mapTilerApiKey',
                additionalOptions: {
                  'key': mapTilerApiKey,
                },
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  onPressed: _zoomIn,
                  backgroundColor: const Color(0xFF1E1A32),
                  child: const Icon(Icons.zoom_in, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  onPressed: _zoomOut,
                  backgroundColor: const Color(0xFF1E1A32),
                  child: const Icon(Icons.zoom_out, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1A32),
        selectedItemColor: const Color(0xFF000000),
        unselectedItemColor: const Color(0xFF896CFE),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.fastfood), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     theme: ThemeData(primarySwatch: Colors.deepPurple),
//     home: MapTilerCustomMap(),
//   ));
// }