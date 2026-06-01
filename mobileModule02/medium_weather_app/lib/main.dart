import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: BottomBar());
  }
}

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String region;
  final String country;
  final double latitude;
  final double longitude;

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      name: json['name'] as String? ?? '',
      region: json['admin1'] as String? ?? '',
      country: json['country'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class _BottomBarState extends State<BottomBar> {
  static const String geolocationUnavailableMessage =
      'Geolocation is not available. Please enable that in your App settings.';
  static const String locationNotFoundMessage = 'Location not found.';
  static const String weatherNotFoundMessage = 'Weather data not available.';

  final TextEditingController searchController = TextEditingController();
  List<CitySuggestion> citySuggestions = [];
  String locationText = '';
  bool isSearchingCities = false;
  int searchRequestId = 0;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void updateLocationText(String text) {
    // Async GPS calls may finish after this widget leaves the screen.
    if (!mounted) {
      return;
    }

    setState(() {
      locationText = text;
    });
  }

  void updateCitySuggestions(
    List<CitySuggestion> suggestions, {
    required bool isSearching,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      citySuggestions = suggestions;
      isSearchingCities = isSearching;
    });
  }

  Future<void> selectCitySuggestion(CitySuggestion suggestion) async {
    // Selected suggestions already include Open-Meteo coordinates.
    final String coordinates =
        '${suggestion.latitude.toStringAsFixed(4)}, '
        '${suggestion.longitude.toStringAsFixed(4)}';

    searchController.text = suggestion.name;
    // Prevent any in-flight search response from reopening the list.
    searchRequestId++;

    if (!mounted) {
      return;
    }

    setState(() {
      citySuggestions = const [];
      isSearchingCities = false;
      locationText = coordinates;
    });

    await fetchCurrentWeather(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      coordinates: coordinates,
    );
  }

  Future<void> fetchCurrentWeather({
    required double latitude,
    required double longitude,
    required String coordinates,
  }) async {
    try {
      // Forecast API uses coordinates from search or device GPS.
      final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,wind_speed_10m',
      });
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        updateLocationText('$coordinates\n$weatherNotFoundMessage');
        return;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> current =
          body['current'] as Map<String, dynamic>;
      // Keep this first weather view small: temperature and wind only.
      final num temperature = current['temperature_2m'] as num;
      final num windSpeed = current['wind_speed_10m'] as num;

      updateLocationText(
        '$coordinates\n'
        'Temperature: ${temperature.toDouble().toStringAsFixed(1)} C\n'
        'Wind: ${windSpeed.toDouble().toStringAsFixed(1)} km/h',
      );
    } on Exception {
      // Keep coordinates visible even if weather retrieval fails.
      updateLocationText('$coordinates\n$weatherNotFoundMessage');
    }
  }

  Future<void> searchCitySuggestions(String placeName) async {
    final String trimmedPlaceName = placeName.trim();
    final int currentRequestId = ++searchRequestId;

    // Empty input clears the current suggestion list.
    if (trimmedPlaceName.isEmpty) {
      updateCitySuggestions(const [], isSearching: false);
      return;
    }

    updateCitySuggestions(citySuggestions, isSearching: true);

    try {
      // Ask Open-Meteo for multiple possible city matches.
      final Uri uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': trimmedPlaceName,
        'count': '10',
        'language': 'en',
        'format': 'json',
      });
      final http.Response response = await http.get(uri);

      // Ignore older responses when the user keeps typing.
      if (currentRequestId != searchRequestId) {
        return;
      }

      if (response.statusCode != 200) {
        updateCitySuggestions(const [], isSearching: false);
        return;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic>? results = body['results'] as List<dynamic>?;
      // Convert API rows into the city data the UI will display.
      final List<CitySuggestion> suggestions = results == null
          ? const []
          : results.map((result) {
              return CitySuggestion.fromJson(result as Map<String, dynamic>);
            }).toList();

      updateCitySuggestions(suggestions, isSearching: false);
    } on Exception {
      // Keep failed searches quiet so the user can keep typing.
      if (currentRequestId == searchRequestId) {
        updateCitySuggestions(const [], isSearching: false);
      }
    }
  }

  Future<void> searchLocation(String placeName) async {
    final String trimmedPlaceName = placeName.trim();

    // Empty search returns the tab to its default label.
    if (trimmedPlaceName.isEmpty) {
      updateLocationText('');
      return;
    }

    try {
      // Open-Meteo geocoding converts place names into coordinates.
      final Uri uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': trimmedPlaceName,
        'count': '1',
        'language': 'en',
        'format': 'json',
      });
      final http.Response response = await http.get(uri);

      if (response.statusCode != 200) {
        updateLocationText(locationNotFoundMessage);
        return;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic>? results = body['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        updateLocationText(locationNotFoundMessage);
        return;
      }

      // The first result is the best match for this simple milestone.
      final CitySuggestion suggestion = CitySuggestion.fromJson(
        results.first as Map<String, dynamic>,
      );
      final String coordinates =
          '${suggestion.latitude.toStringAsFixed(4)}, '
          '${suggestion.longitude.toStringAsFixed(4)}';

      updateCitySuggestions(const [], isSearching: false);
      searchController.text = suggestion.name;
      searchRequestId++;

      updateLocationText(coordinates);
      await fetchCurrentWeather(
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
        coordinates: coordinates,
      );
    } on Exception {
      // Network, JSON, and unexpected API shapes share one user message.
      updateLocationText(locationNotFoundMessage);
    }
  }

  Future<void> useGeolocation() async {
    searchController.clear();
    updateCitySuggestions(const [], isSearching: false);

    // Ask Android for runtime location permission when needed.
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Permission denied means GPS coordinates cannot be read.
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      updateLocationText(geolocationUnavailableMessage);
      return;
    }

    final bool isLocationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();

    // Permission is separate from the phone's location service switch.
    if (!isLocationServiceEnabled) {
      updateLocationText(geolocationUnavailableMessage);
      return;
    }

    try {
      // Read the current GPS position and display latitude, longitude.
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final String coordinates =
          '${position.latitude.toStringAsFixed(4)}, '
          '${position.longitude.toStringAsFixed(4)}';

      updateLocationText(coordinates);
      await fetchCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
        coordinates: coordinates,
      );
    } on Exception {
      // Keep the UI requirement the same for any geolocation failure.
      updateLocationText(geolocationUnavailableMessage);
    }
  }

  Widget buildTabContent(String tabName) {
    final String displayText = locationText.isEmpty
        ? tabName
        : '$tabName\n$locationText';

    return Center(child: Text(displayText, textAlign: TextAlign.center));
  }

  Widget buildCitySuggestions() {
    // Hide the panel when there is nothing useful to show.
    if (!isSearchingCities && citySuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSearchingCities) const LinearProgressIndicator(minHeight: 2),
          if (citySuggestions.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: citySuggestions.length,
                separatorBuilder: (BuildContext context, int index) {
                  return const Divider(height: 1);
                },
                itemBuilder: (BuildContext context, int index) {
                  final CitySuggestion suggestion = citySuggestions[index];
                  final String region = suggestion.region.isEmpty
                      ? '-'
                      : suggestion.region;
                  final String country = suggestion.country.isEmpty
                      ? '-'
                      : suggestion.country;

                  return ListTile(
                    dense: true,
                    title: Text('${suggestion.name} $region, $country'),
                    onTap: () {
                      selectCitySuggestion(suggestion);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 8,
          title: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.search),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: (String value) {
                          updateLocationText(value);
                          searchCitySuggestions(value);
                        },
                        onSubmitted: searchLocation,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search location...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32, child: VerticalDivider(thickness: 1)),
              IconButton(
                icon: const Icon(Icons.near_me),
                onPressed: useGeolocation,
              ),
            ],
          ),
        ),

        body: Column(
          children: [
            buildCitySuggestions(),
            Expanded(
              child: TabBarView(
                children: [
                  buildTabContent('Currently'),
                  buildTabContent('Today'),
                  buildTabContent('Weekly'),
                ],
              ),
            ),
          ],
        ),

        bottomNavigationBar: BottomAppBar(
          child: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.settings), text: 'Currently'),
              Tab(icon: Icon(Icons.today), text: 'Today'),
              Tab(icon: Icon(Icons.view_week_outlined), text: 'Weekly'),
            ],
          ),
        ),
      ),
    );
  }
}
