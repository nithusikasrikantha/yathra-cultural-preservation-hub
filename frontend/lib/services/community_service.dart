import '../config/api_config.dart';
import '../models/community_theme.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CommunityService {
  final _api = ApiService(baseUrl: ApiConfig.baseUrl);
  Future<List<CulturalTheme>> list() async {
    final result = await _api
        .get(
          '/api/communities',
          headers: await AuthService.authenticatedHeaders(),
        )
        .timeout(const Duration(seconds: 15));
    return (result['items'] as List)
        .map(
          (item) => CulturalTheme(
            id: item['id'],
            title: item['title'],
            imageUrl: item['imageUrl'],
            category: item['category'],
            description: item['description'],
            membersCount: '${item['membersCount']} members',
            activeEldersCount: '',
            isFollowing: item['isFollowing'] == true,
            knowledgePosts: [],
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> follow(String id, bool follow) async {
    return Map<String, dynamic>.from(
      await _api
          .put(
            '/api/communities/${Uri.encodeComponent(id)}/follow',
            headers: await AuthService.authenticatedHeaders(),
            body: {'follow': follow},
          )
          .timeout(const Duration(seconds: 15)),
    );
  }
}
