import '../config/api_config.dart';
import '../models/cultural_place.dart';
import 'api_service.dart';

class CulturalPlaceService {
  CulturalPlaceService({ApiService? apiService})
    : _apiService = apiService ?? ApiService(baseUrl: ApiConfig.baseUrl);

  final ApiService _apiService;

  Future<CulturalPlacePage> fetchPlaces({
    int page = 1,
    int limit = 100,
    String? category,
    String? province,
    String? district,
    String? language,
    String? region,
    String? search,
    bool? hasStories,
  }) async {
    final query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (category?.trim().isNotEmpty == true) {
      query['category'] = category!.trim();
    }
    if (province?.trim().isNotEmpty == true) {
      query['province'] = province!.trim();
    }
    if (district?.trim().isNotEmpty == true) {
      query['district'] = district!.trim();
    }
    if (language?.trim().isNotEmpty == true) {
      query['language'] = language!.trim();
    }
    if (region?.trim().isNotEmpty == true) {
      query['region'] = region!.trim();
    }
    if (search?.trim().isNotEmpty == true) {
      query['search'] = search!.trim();
    }
    if (hasStories != null) {
      query['hasStories'] = '$hasStories';
    }

    final response = await _apiService.get(
      '/api/cultural-places?${Uri(queryParameters: query).query}',
    );
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Invalid cultural places response.');
    }
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Invalid cultural places response.');
    }
    final pagination = response['pagination'];
    return CulturalPlacePage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(CulturalPlace.fromJson)
          .toList(growable: false),
      pagination: CulturalPlacePagination.fromJson(
        pagination is Map<String, dynamic> ? pagination : const {},
      ),
    );
  }

  Future<CulturalPlace> fetchPlaceById(String id) async {
    final response = await _apiService.get(
      '/api/cultural-places/${Uri.encodeComponent(id)}',
    );
    if (response is! Map<String, dynamic> ||
        response['place'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid cultural place response.');
    }
    return CulturalPlace.fromJson(response['place'] as Map<String, dynamic>);
  }
}

class CulturalPlacePage {
  const CulturalPlacePage({required this.items, required this.pagination});

  final List<CulturalPlace> items;
  final CulturalPlacePagination pagination;
}

class CulturalPlacePagination {
  const CulturalPlacePagination({
    required this.currentPage,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  });

  factory CulturalPlacePagination.fromJson(Map<String, dynamic> json) {
    int value(String key, int fallback) {
      final raw = json[key];
      return raw is num ? raw.toInt() : int.tryParse('$raw') ?? fallback;
    }

    return CulturalPlacePagination(
      currentPage: value('currentPage', 1),
      pageSize: value('pageSize', 100),
      totalItems: value('totalItems', 0),
      totalPages: value('totalPages', 0),
    );
  }

  final int currentPage;
  final int pageSize;
  final int totalItems;
  final int totalPages;
}
