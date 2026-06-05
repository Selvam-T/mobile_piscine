import 'dart:convert';

import 'package:geocoding/geocoding.dart';
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

class HourlyForecast {
  const HourlyForecast({
    required this.hour,
    required this.temperature,
    required this.windSpeed,
    required this.description,
  });

  final String hour;
  final double temperature;
  final double windSpeed;
  final String description;
}

class CurrentForecast {
  const CurrentForecast({
    required this.temperature,
    required this.windSpeed,
    required this.description,
  });

  final double temperature;
  final double windSpeed;
  final String description;
}

class DailyForecast {
  const DailyForecast({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.windSpeed,
    required this.description,
  });

  final String date;
  final double minTemperature;
  final double maxTemperature;
  final double windSpeed;
  final String description;
}

class _BottomBarState extends State<BottomBar>
    with SingleTickerProviderStateMixin {
  static const String geolocationUnavailableMessage =
      'Geolocation is not available. Please enable that in your App settings.';
  static const String invalidCityMessage =
      'could not find any result for the supplied coordinates';
  static const String connectionLostMessage =
      'The service connection is lost, please check your internet connection or try again later.';
  static const String weatherNotFoundMessage = 'Weather data not available.';

  final TextEditingController searchController = TextEditingController();
  final ScrollController todayHorizontalController = ScrollController();
  final ScrollController weeklyHorizontalController = ScrollController();
  late final TabController tabController;
  List<CitySuggestion> citySuggestions = [];
  List<HourlyForecast> todayForecast = [];
  List<DailyForecast> weeklyForecast = [];
  CurrentForecast? currentForecast;
  double? lastLatitude;
  double? lastLongitude;
  String errorMessage = '';
  String selectedLocationText = '';
  bool isSearchingCities = false;
  int searchRequestId = 0;
  int weatherRequestId = 0;

  String cityLabel(CitySuggestion suggestion) {
    final String region = suggestion.region.isEmpty ? '-' : suggestion.region;
    final String country = suggestion.country.isEmpty
        ? '-'
        : suggestion.country;

    return '${suggestion.name}\n$region\n$country';
  }

  TextSpan highlightedMatchSpan(String text, String searchText) {
    final String trimmedSearchText = searchText.trim();

    if (trimmedSearchText.isEmpty) {
      return TextSpan(text: text);
    }

    final String lowerText = text.toLowerCase();
    final String lowerSearchText = trimmedSearchText.toLowerCase();
    final List<TextSpan> spans = [];
    int searchStart = 0;

    while (searchStart < text.length) {
      final int matchIndex = lowerText.indexOf(lowerSearchText, searchStart);

      if (matchIndex == -1) {
        spans.add(TextSpan(text: text.substring(searchStart)));
        break;
      }

      if (matchIndex > searchStart) {
        spans.add(TextSpan(text: text.substring(searchStart, matchIndex)));
      }

      final int matchEnd = matchIndex + trimmedSearchText.length;
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchEnd),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      searchStart = matchEnd;
    }

    return TextSpan(children: spans);
  }

  Widget suggestionTextRow({
    required IconData icon,
    required String text,
    required String searchText,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: highlightedMatchSpan(text, searchText),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String placemarkLabel(Placemark placemark) {
    final String city = placemark.locality?.isNotEmpty == true
        ? placemark.locality!
        : placemark.subAdministrativeArea ?? '-';
    final String region = placemark.administrativeArea?.isNotEmpty == true
        ? placemark.administrativeArea!
        : '-';
    final String country = placemark.country?.isNotEmpty == true
        ? placemark.country!
        : '-';

    return '$city\n$region\n$country';
  }

  String weatherDescription(num weatherCode) {
    switch (weatherCode.toInt()) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 56:
      case 57:
        return 'Freezing drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 66:
      case 67:
        return 'Freezing rain';
      case 71:
      case 73:
      case 75:
        return 'Snow fall';
      case 77:
        return 'Snow grains';
      case 80:
      case 81:
      case 82:
        return 'Rain showers';
      case 85:
      case 86:
        return 'Snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
      case 99:
        return 'Thunderstorm with hail';
      default:
        return 'Unknown';
    }
  }

  IconData weatherIcon(String description) {
    switch (description) {
      case 'Clear sky':
      case 'Mainly clear':
        return Icons.wb_sunny_outlined;
      case 'Partly cloudy':
      case 'Overcast':
        return Icons.cloud_outlined;
      case 'Fog':
        return Icons.blur_on_outlined;
      case 'Drizzle':
      case 'Freezing drizzle':
      case 'Rain':
      case 'Freezing rain':
      case 'Rain showers':
        return Icons.water_drop_outlined;
      case 'Snow fall':
      case 'Snow grains':
      case 'Snow showers':
        return Icons.ac_unit_outlined;
      case 'Thunderstorm':
      case 'Thunderstorm with hail':
        return Icons.thunderstorm_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color weatherIconColor(String description) {
    switch (description) {
      case 'Clear sky':
      case 'Mainly clear':
        return Colors.orange;
      case 'Partly cloudy':
      case 'Overcast':
      case 'Fog':
        return Colors.blueGrey;
      case 'Drizzle':
      case 'Freezing drizzle':
      case 'Rain':
      case 'Freezing rain':
      case 'Rain showers':
        return Colors.blue;
      case 'Snow fall':
      case 'Snow grains':
      case 'Snow showers':
        return Colors.lightBlue;
      case 'Thunderstorm':
      case 'Thunderstorm with hail':
        return Colors.deepPurple;
      default:
        return Colors.black;
    }
  }

  Widget styledLocationText(String locationText) {
    final List<String> lines = locationText.split('\n');
    final String city = lines.isEmpty ? locationText : lines.first;
    final String rest = lines.length > 1 ? lines.skip(1).join(', ') : '';

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: city,
            style: const TextStyle(color: Colors.red),
          ),
          if (rest.isNotEmpty)
            TextSpan(
              text: '\n$rest',
              style: const TextStyle(color: Colors.black),
            ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    todayHorizontalController.dispose();
    weeklyHorizontalController.dispose();
    tabController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void updateTodayForecast(
    String locationLabel,
    List<HourlyForecast> forecast,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      selectedLocationText = locationLabel;
      todayForecast = forecast;
    });
  }

  void updateWeeklyForecast(
    String locationLabel,
    List<DailyForecast> forecast,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      selectedLocationText = locationLabel;
      weeklyForecast = forecast;
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

  void showErrorMessage(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      errorMessage = message;
    });
  }

  void clearErrorMessage() {
    if (!mounted || errorMessage.isEmpty) {
      return;
    }

    setState(() {
      errorMessage = '';
    });
  }

  void rememberCoordinates(double latitude, double longitude) {
    lastLatitude = latitude;
    lastLongitude = longitude;
  }

  void applySearchedLocation({
    required double latitude,
    required double longitude,
    required String locationLabel,
  }) {
    if (!mounted) {
      return;
    }

    rememberCoordinates(latitude, longitude);

    setState(() {
      selectedLocationText = locationLabel;
      currentForecast = null;
      todayForecast = const [];
      weeklyForecast = const [];
    });
  }

  int beginWeatherRequest() {
    return ++weatherRequestId;
  }

  bool isCurrentWeatherRequest(int requestId) {
    return mounted && requestId == weatherRequestId;
  }

  Future<void> selectCitySuggestion(CitySuggestion suggestion) async {
    // Selected suggestions already include Open-Meteo coordinates.
    final String coordinates =
        '${suggestion.latitude.toStringAsFixed(4)}, '
        '${suggestion.longitude.toStringAsFixed(4)}';

    searchController.text = suggestion.name;
    final int currentWeatherRequestId = beginWeatherRequest();
    // Prevent any in-flight search response from reopening the list.
    searchRequestId++;

    if (!mounted) {
      return;
    }

    setState(() {
      citySuggestions = const [];
      isSearchingCities = false;
    });
    applySearchedLocation(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      locationLabel: cityLabel(suggestion),
    );

    await loadWeatherForLocation(
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      fallbackText: coordinates,
      locationLabel: cityLabel(suggestion),
      requestId: currentWeatherRequestId,
    );
  }

  Future<void> fetchCurrentWeather({
    required double latitude,
    required double longitude,
    required String fallbackText,
    required int requestId,
    String? locationLabel,
  }) async {
    try {
      // Forecast API uses coordinates from search or device GPS.
      final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current': 'temperature_2m,weather_code,wind_speed_10m',
      });
      final http.Response response = await http.get(uri);

      if (!isCurrentWeatherRequest(requestId)) {
        return;
      }

      if (response.statusCode != 200) {
        if (isCurrentWeatherRequest(requestId)) {
          setState(() {
            selectedLocationText = locationLabel ?? fallbackText;
            currentForecast = null;
          });
        }
        return;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> current =
          body['current'] as Map<String, dynamic>;
      // Keep this first weather view small: condition, temperature, and wind.
      final num temperature = current['temperature_2m'] as num;
      final num weatherCode = current['weather_code'] as num;
      final num windSpeed = current['wind_speed_10m'] as num;
      final String displayLocation = locationLabel ?? fallbackText;

      if (!isCurrentWeatherRequest(requestId)) {
        return;
      }

      setState(() {
        selectedLocationText = displayLocation;
        currentForecast = CurrentForecast(
          temperature: temperature.toDouble(),
          windSpeed: windSpeed.toDouble(),
          description: weatherDescription(weatherCode),
        );
      });
    } on Exception {
      // Keep coordinates visible even if weather retrieval fails.
      if (isCurrentWeatherRequest(requestId)) {
        setState(() {
          selectedLocationText = locationLabel ?? fallbackText;
          currentForecast = null;
        });
      }
    }
  }

  Future<void> fetchTodayWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
    required int requestId,
  }) async {
    try {
      // forecast_days=1 returns the local 00:00-23:00 hourly forecast.
      final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'hourly': 'temperature_2m,weather_code,wind_speed_10m',
        'forecast_days': '1',
        'timezone': 'auto',
      });
      final http.Response response = await http.get(uri);

      if (!isCurrentWeatherRequest(requestId)) {
        return;
      }

      if (response.statusCode != 200) {
        updateTodayForecast(locationLabel, const []);
        return;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> hourly =
          body['hourly'] as Map<String, dynamic>;
      final List<dynamic> times = hourly['time'] as List<dynamic>;
      final List<dynamic> temperatures =
          hourly['temperature_2m'] as List<dynamic>;
      final List<dynamic> weatherCodes =
          hourly['weather_code'] as List<dynamic>;
      final List<dynamic> windSpeeds =
          hourly['wind_speed_10m'] as List<dynamic>;
      final int rowCount = times.length < 24 ? times.length : 24;
      final List<HourlyForecast> forecast = List<HourlyForecast>.generate(
        rowCount,
        (int index) {
          final String time = times[index] as String;
          final num temperature = temperatures[index] as num;
          final num weatherCode = weatherCodes[index] as num;
          final num windSpeed = windSpeeds[index] as num;

          return HourlyForecast(
            hour: time.substring(time.length - 5),
            temperature: temperature.toDouble(),
            windSpeed: windSpeed.toDouble(),
            description: weatherDescription(weatherCode),
          );
        },
      );

      updateTodayForecast(locationLabel, forecast);
    } on Exception {
      if (isCurrentWeatherRequest(requestId)) {
        updateTodayForecast(locationLabel, const []);
      }
    }
  }

  Future<void> fetchWeeklyWeather({
    required double latitude,
    required double longitude,
    required String locationLabel,
    required int requestId,
  }) async {
    try {
      // Daily forecast gives seven local-day rows for the Weekly tab.
      final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'daily':
            'temperature_2m_min,temperature_2m_max,weather_code,wind_speed_10m_max',
        'forecast_days': '7',
        'timezone': 'auto',
      });
      final http.Response response = await http.get(uri);

      if (!isCurrentWeatherRequest(requestId)) {
        return;
      }

      if (response.statusCode != 200) {
        updateWeeklyForecast(locationLabel, const []);
        return;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> daily = body['daily'] as Map<String, dynamic>;
      final List<dynamic> dates = daily['time'] as List<dynamic>;
      final List<dynamic> minTemperatures =
          daily['temperature_2m_min'] as List<dynamic>;
      final List<dynamic> maxTemperatures =
          daily['temperature_2m_max'] as List<dynamic>;
      final List<dynamic> weatherCodes = daily['weather_code'] as List<dynamic>;
      final List<dynamic> windSpeeds =
          daily['wind_speed_10m_max'] as List<dynamic>;
      final int rowCount = dates.length < 7 ? dates.length : 7;
      final List<DailyForecast> forecast = List<DailyForecast>.generate(
        rowCount,
        (int index) {
          final String date = dates[index] as String;
          final num minTemperature = minTemperatures[index] as num;
          final num maxTemperature = maxTemperatures[index] as num;
          final num weatherCode = weatherCodes[index] as num;
          final num windSpeed = windSpeeds[index] as num;

          return DailyForecast(
            date: date,
            minTemperature: minTemperature.toDouble(),
            maxTemperature: maxTemperature.toDouble(),
            windSpeed: windSpeed.toDouble(),
            description: weatherDescription(weatherCode),
          );
        },
      );

      updateWeeklyForecast(locationLabel, forecast);
    } on Exception {
      if (isCurrentWeatherRequest(requestId)) {
        updateWeeklyForecast(locationLabel, const []);
      }
    }
  }

  Future<CurrentForecast?> readCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'temperature_2m,weather_code,wind_speed_10m',
    });
    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      return null;
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> current =
        body['current'] as Map<String, dynamic>;
    final num temperature = current['temperature_2m'] as num;
    final num weatherCode = current['weather_code'] as num;
    final num windSpeed = current['wind_speed_10m'] as num;

    return CurrentForecast(
      temperature: temperature.toDouble(),
      windSpeed: windSpeed.toDouble(),
      description: weatherDescription(weatherCode),
    );
  }

  Future<List<HourlyForecast>> readTodayWeather({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'hourly': 'temperature_2m,weather_code,wind_speed_10m',
      'forecast_days': '1',
      'timezone': 'auto',
    });
    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      return const [];
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> hourly = body['hourly'] as Map<String, dynamic>;
    final List<dynamic> times = hourly['time'] as List<dynamic>;
    final List<dynamic> temperatures =
        hourly['temperature_2m'] as List<dynamic>;
    final List<dynamic> weatherCodes = hourly['weather_code'] as List<dynamic>;
    final List<dynamic> windSpeeds = hourly['wind_speed_10m'] as List<dynamic>;
    final int rowCount = times.length < 24 ? times.length : 24;

    return List<HourlyForecast>.generate(rowCount, (int index) {
      final String time = times[index] as String;
      final num temperature = temperatures[index] as num;
      final num weatherCode = weatherCodes[index] as num;
      final num windSpeed = windSpeeds[index] as num;

      return HourlyForecast(
        hour: time.substring(time.length - 5),
        temperature: temperature.toDouble(),
        windSpeed: windSpeed.toDouble(),
        description: weatherDescription(weatherCode),
      );
    });
  }

  Future<List<DailyForecast>> readWeeklyWeather({
    required double latitude,
    required double longitude,
  }) async {
    final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'daily':
          'temperature_2m_min,temperature_2m_max,weather_code,wind_speed_10m_max',
      'forecast_days': '7',
      'timezone': 'auto',
    });
    final http.Response response = await http.get(uri);

    if (response.statusCode != 200) {
      return const [];
    }

    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    final Map<String, dynamic> daily = body['daily'] as Map<String, dynamic>;
    final List<dynamic> dates = daily['time'] as List<dynamic>;
    final List<dynamic> minTemperatures =
        daily['temperature_2m_min'] as List<dynamic>;
    final List<dynamic> maxTemperatures =
        daily['temperature_2m_max'] as List<dynamic>;
    final List<dynamic> weatherCodes = daily['weather_code'] as List<dynamic>;
    final List<dynamic> windSpeeds =
        daily['wind_speed_10m_max'] as List<dynamic>;
    final int rowCount = dates.length < 7 ? dates.length : 7;

    return List<DailyForecast>.generate(rowCount, (int index) {
      final String date = dates[index] as String;
      final num minTemperature = minTemperatures[index] as num;
      final num maxTemperature = maxTemperatures[index] as num;
      final num weatherCode = weatherCodes[index] as num;
      final num windSpeed = windSpeeds[index] as num;

      return DailyForecast(
        date: date,
        minTemperature: minTemperature.toDouble(),
        maxTemperature: maxTemperature.toDouble(),
        windSpeed: windSpeed.toDouble(),
        description: weatherDescription(weatherCode),
      );
    });
  }

  Future<void> loadWeatherForLocation({
    required double latitude,
    required double longitude,
    required String fallbackText,
    required String locationLabel,
    required int requestId,
  }) async {
    try {
      final CurrentForecast? current = await readCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
      final List<HourlyForecast> today = await readTodayWeather(
        latitude: latitude,
        longitude: longitude,
      );
      final List<DailyForecast> weekly = await readWeeklyWeather(
        latitude: latitude,
        longitude: longitude,
      );

      if (!isCurrentWeatherRequest(requestId)) {
        return;
      }

      setState(() {
        selectedLocationText = locationLabel;
        currentForecast = current;
        todayForecast = today;
        weeklyForecast = weekly;
        errorMessage = '';
      });
    } on Exception {
      if (isCurrentWeatherRequest(requestId)) {
        showErrorMessage(connectionLostMessage);
      }
    }
  }

  Future<String> reverseGeocodeLocation({
    required double latitude,
    required double longitude,
    required String fallbackText,
  }) async {
    try {
      // Device GPS gives coordinates; reverse geocoding gives display names.
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return fallbackText;
      }

      return placemarkLabel(placemarks.first);
    } on Exception {
      return fallbackText;
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
        'count': '5',
        'language': 'en',
        'format': 'json',
      });
      final http.Response response = await http.get(uri);

      // Ignore older responses when the user keeps typing.
      if (currentRequestId != searchRequestId) {
        return;
      }

      if (response.statusCode != 200) {
        showErrorMessage(connectionLostMessage);
        updateCitySuggestions(const [], isSearching: false);
        return;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic>? results = body['results'] as List<dynamic>?;
      // Convert API rows into the city data the UI will display.
      final List<CitySuggestion> suggestions = results == null
          ? const []
          : results
                .map((result) {
                  return CitySuggestion.fromJson(
                    result as Map<String, dynamic>,
                  );
                })
                .take(5)
                .toList();

      updateCitySuggestions(suggestions, isSearching: false);
    } on Exception {
      // Keep failed searches quiet so the user can keep typing.
      if (currentRequestId == searchRequestId) {
        showErrorMessage(connectionLostMessage);
        updateCitySuggestions(const [], isSearching: false);
      }
    }
  }

  Future<void> searchLocation(String placeName) async {
    final String trimmedPlaceName = placeName.trim();

    // Empty search returns the tab to its default label.
    if (trimmedPlaceName.isEmpty) {
      updateCitySuggestions(const [], isSearching: false);
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
        showErrorMessage(connectionLostMessage);
        updateCitySuggestions(const [], isSearching: false);
        return;
      }

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic>? results = body['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        showErrorMessage(invalidCityMessage);
        updateCitySuggestions(const [], isSearching: false);
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
      final int currentWeatherRequestId = beginWeatherRequest();
      searchRequestId++;
      applySearchedLocation(
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
        locationLabel: cityLabel(suggestion),
      );

      await loadWeatherForLocation(
        latitude: suggestion.latitude,
        longitude: suggestion.longitude,
        fallbackText: coordinates,
        locationLabel: cityLabel(suggestion),
        requestId: currentWeatherRequestId,
      );
    } on Exception {
      // Network, JSON, and unexpected API shapes share one user message.
      showErrorMessage(connectionLostMessage);
      updateCitySuggestions(const [], isSearching: false);
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
      if (mounted) {
        setState(() {
          selectedLocationText = geolocationUnavailableMessage;
          currentForecast = null;
          todayForecast = const [];
          weeklyForecast = const [];
        });
      }
      return;
    }

    final bool isLocationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();

    // Permission is separate from the phone's location service switch.
    if (!isLocationServiceEnabled) {
      if (mounted) {
        setState(() {
          selectedLocationText = geolocationUnavailableMessage;
          currentForecast = null;
          todayForecast = const [];
          weeklyForecast = const [];
        });
      }
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
      final String locationLabel = await reverseGeocodeLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        fallbackText: coordinates,
      );
      final int currentWeatherRequestId = beginWeatherRequest();
      applySearchedLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        locationLabel: locationLabel,
      );

      await loadWeatherForLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        fallbackText: coordinates,
        locationLabel: locationLabel,
        requestId: currentWeatherRequestId,
      );
    } on Exception {
      // Keep the UI requirement the same for any geolocation failure.
      if (mounted) {
        setState(() {
          selectedLocationText = geolocationUnavailableMessage;
          currentForecast = null;
          todayForecast = const [];
          weeklyForecast = const [];
        });
      }
    }
  }

  Widget buildTabContent(String tabName) {
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage, textAlign: TextAlign.center));
    }

    if (selectedLocationText.isEmpty || currentForecast == null) {
      return Center(child: Text(tabName, textAlign: TextAlign.center));
    }

    final CurrentForecast forecast = currentForecast!;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          styledLocationText(selectedLocationText),
          const SizedBox(height: 16),
          Text(
            '${forecast.temperature.toStringAsFixed(1)} C',
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 40,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            forecast.description,
            style: const TextStyle(color: Colors.black, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Icon(
            weatherIcon(forecast.description),
            color: weatherIconColor(forecast.description),
            size: 32,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.air, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                '${forecast.windSpeed.toStringAsFixed(1)} km/h',
                style: const TextStyle(color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTodayContent() {
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage, textAlign: TextAlign.center));
    }

    if (selectedLocationText.isEmpty) {
      return const Center(child: Text('Today'));
    }

    if (todayForecast.isEmpty) {
      return Center(
        child: Text(
          'Today\n$selectedLocationText\n$weatherNotFoundMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          styledLocationText(selectedLocationText),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              controller: todayHorizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: todayHorizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 520,
                  child: ListView(
                    children: [
                      for (final HourlyForecast forecast in todayForecast)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 64, child: Text(forecast.hour)),
                              SizedBox(
                                width: 88,
                                child: Text(
                                  '${forecast.temperature.toStringAsFixed(1)} C',
                                ),
                              ),
                              SizedBox(
                                width: 112,
                                child: Text(
                                  '${forecast.windSpeed.toStringAsFixed(1)} km/h',
                                ),
                              ),
                              SizedBox(
                                width: 256,
                                child: Text(forecast.description),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWeeklyContent() {
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage, textAlign: TextAlign.center));
    }

    if (selectedLocationText.isEmpty) {
      return const Center(child: Text('Weekly'));
    }

    if (weeklyForecast.isEmpty) {
      return Center(
        child: Text(
          '$selectedLocationText\n$weatherNotFoundMessage',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          styledLocationText(selectedLocationText),
          const SizedBox(height: 16),
          Expanded(
            child: Scrollbar(
              controller: weeklyHorizontalController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: weeklyHorizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 620,
                  child: ListView(
                    children: [
                      for (final DailyForecast forecast in weeklyForecast)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(width: 104, child: Text(forecast.date)),
                              SizedBox(
                                width: 88,
                                child: Text(
                                  '${forecast.minTemperature.toStringAsFixed(1)} C',
                                ),
                              ),
                              SizedBox(
                                width: 88,
                                child: Text(
                                  '${forecast.maxTemperature.toStringAsFixed(1)} C',
                                ),
                              ),
                              SizedBox(
                                width: 112,
                                child: Text(
                                  '${forecast.windSpeed.toStringAsFixed(1)} km/h',
                                ),
                              ),
                              SizedBox(
                                width: 228,
                                child: Text(forecast.description),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
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
                  final String searchText = searchController.text;

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    title: suggestionTextRow(
                      icon: Icons.location_city,
                      text: '${suggestion.name} $region, $country',
                      searchText: searchText,
                    ),
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
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 8,
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Search location',
                          style: TextStyle(fontSize: 14),
                        ),
                        TextField(
                          controller: searchController,
                          onChanged: (String value) {
                            searchCitySuggestions(value);
                          },
                          onSubmitted: searchLocation,
                          style: const TextStyle(fontSize: 20),
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ],
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
            const SizedBox(width: 48),
          ],
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/weather.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withValues(alpha: 0.45)),
          ),
          Column(
            children: [
              buildCitySuggestions(),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    buildTabContent('Currently'),
                    buildTodayContent(),
                    buildWeeklyContent(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      bottomNavigationBar: BottomAppBar(
        child: TabBar(
          controller: tabController,
          tabs: [
            Tab(icon: Icon(Icons.settings), text: 'Currently'),
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.view_week_outlined), text: 'Weekly'),
          ],
        ),
      ),
    );
  }
}
