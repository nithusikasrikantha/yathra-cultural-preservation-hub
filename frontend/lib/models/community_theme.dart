class CulturalTheme {
  final String id;
  final String title;
  final String membersCount;
  final String activeEldersCount;
  final String imageUrl;
  final String category;
  final String description;
  bool isJoined;
  final List<ElderKnowledgePost> knowledgePosts;

  CulturalTheme({
    required this.id,
    required this.title,
    required this.membersCount,
    required this.activeEldersCount,
    required this.imageUrl,
    required this.category,
    required this.description,
    this.isJoined = false,
    required this.knowledgePosts,
  });
}

class ElderKnowledgePost {
  final String id;
  final String elderName;
  final String elderRole;
  final String timeAgo;
  final String avatarUrl;
  final String title;
  final String snippet;
  final String? imageUrl;
  int likesCount;
  int commentsCount;
  bool isConnected;
  bool isLiked;

  ElderKnowledgePost({
    required this.id,
    required this.elderName,
    required this.elderRole,
    required this.timeAgo,
    required this.avatarUrl,
    required this.title,
    required this.snippet,
    this.imageUrl,
    required this.likesCount,
    required this.commentsCount,
    this.isConnected = false,
    this.isLiked = false,
  });
}

class CategoryItem {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String categoryKey;

  const CategoryItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.categoryKey,
  });
}

class MockCulturalData {
  static List<CulturalTheme> getPopularThemes() {
    return [
      CulturalTheme(
        id: 'jaffna_cuisine',
        title: 'Traditional Jaffna Cuisine',
        membersCount: '1.2k Members',
        activeEldersCount: '85 Active Elders',
        imageUrl:
            'https://assets.roar.media/Life/2017/04/Jaffna-food1.jpg?w=1200',
        category: 'Food',
        description:
            'Preserving authentic Northern Sri Lankan recipes, palmyra delicacies, and traditional clay-pot cooking secrets passed down through generations.',
        knowledgePosts: [
          ElderKnowledgePost(
            id: 'p1',
            elderName: 'K. Rajalingam',
            elderRole: 'Palmyra traditions specialist • 2h ago',
            timeAgo: '2h ago',
            avatarUrl:
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
            title: 'The correct way to extract Palm Syrup',
            snippet:
                'Step by step method explained by my grandfather for extracting sweet syrup during the dry season without destroying the flower stem.',
            imageUrl:
                'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600',
            likesCount: 42,
            commentsCount: 6,
          ),
          ElderKnowledgePost(
            id: 'p2',
            elderName: 'S. Vimalanathan',
            elderRole: 'Temple cuisine elder • 1d ago',
            timeAgo: '1d ago',
            avatarUrl:
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
            title: 'Traditional spices of Nallur Kovil festival',
            snippet:
                'Unique spice combinations used during the annual temple festival feast, prepared using wood fire in traditional copper vessels.',
            imageUrl:
                'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=600',
            likesCount: 128,
            commentsCount: 17,
          ),
          ElderKnowledgePost(
            id: 'p3',
            elderName: 'Meenachchi Amma',
            elderRole: 'Heritage weaver • 3d ago',
            timeAgo: '3d ago',
            avatarUrl:
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
            title: 'Preserving traditional food packaging with dry leaves',
            snippet:
                'How we used banana leaves and palmyra leaves in traditional food storage and eco-friendly packing before modern plastics.',
            imageUrl:
                'https://images.unsplash.com/photo-1509316975850-ff9c5deb0cd9?w=600',
            likesCount: 95,
            commentsCount: 9,
          ),
          ElderKnowledgePost(
            id: 'p4',
            elderName: 'P. Shanmugam',
            elderRole: 'Seafood culinary master • 4d ago',
            timeAgo: '4d ago',
            avatarUrl:
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
            title: 'Authentic Jaffna Crab Curry in Clay Pots',
            snippet:
                'Slow cooking crab with freshly roasted curry powder and coconut milk over coconut shell embers.',
            imageUrl:
                'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600',
            likesCount: 210,
            commentsCount: 28,
          ),
        ],
      ),
      CulturalTheme(
        id: 'kandyan_dance',
        title: 'Kandyan Dance Traditions',
        membersCount: '980 Members',
        activeEldersCount: '42 Active Elders',
        imageUrl:
            'https://cdn.audleytravel.com/1400/1000/60/352521-kandyan-dancers-kandy.jpg',
        category: 'Performing Arts',
        description:
            'Celebrating Ves dance rituals, drum rhythms, sacred temple dances, and the rich dance heritage of the Hill Country.',
        knowledgePosts: [
          ElderKnowledgePost(
            id: 'k1',
            elderName: 'Guru Bandara',
            elderRole: 'Ves Master • 4h ago',
            timeAgo: '4h ago',
            avatarUrl:
                'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
            title: 'Rhythm of Getaberaya in ceremonial temple dances',
            snippet:
                'The sacred beat patterns passed down through seven generations of drumming masters to open the ceremonial Perahera.',
            imageUrl:
                'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600',
            likesCount: 88,
            commentsCount: 12,
          ),
          ElderKnowledgePost(
            id: 'k2',
            elderName: 'Soma Kumari',
            elderRole: 'Costume heritage specialist • 2d ago',
            timeAgo: '2d ago',
            avatarUrl:
                'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
            title: 'Handcrafted Ves headpieces and silver regalia',
            snippet:
                'Symbolism behind each intricate ornament and silver headpiece worn by classical Kandyan dancers during temple rituals.',
            imageUrl:
                'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600',
            likesCount: 154,
            commentsCount: 21,
          ),
        ],
      ),
      CulturalTheme(
        id: 'village_folk_songs',
        title: 'Village Folk Songs',
        membersCount: '850 Members',
        activeEldersCount: '38 Active Elders',
        imageUrl:
            'https://s3.ap-southeast-1.amazonaws.com/cdn.sannasa.lk/media/3399/conversions/WhatsApp-Image-2024-08-05-at-03.24.57-w_1024.jpg',
        category: 'Traditional Music',
        description:
            'Preserving paddy harvest chants, lullabies, boating songs, and oral folklore melodies sung across rural Sri Lankan villages.',
        knowledgePosts: [
          ElderKnowledgePost(
            id: 'v1',
            elderName: 'Gunasena Rajapaksha',
            elderRole: 'Goyam Chants Elder • 6h ago',
            timeAgo: '6h ago',
            avatarUrl:
                'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
            title: 'Paddy harvesting songs of the Dry Zone',
            snippet:
                'How farmers sang together in harmony to maintain rhythm and high spirits under the hot sun during harvest season.',
            imageUrl:
                'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=600',
            likesCount: 64,
            commentsCount: 8,
          ),
          ElderKnowledgePost(
            id: 'v2',
            elderName: 'Dingiri Menike',
            elderRole: 'Folk story singer • 1d ago',
            timeAgo: '1d ago',
            avatarUrl:
                'https://images.unsplash.com/photo-1567532939604-b6b5b0db2604?w=150',
            title: 'Lullabies sung in ancient hamlets',
            snippet:
                'Soothing melodies telling tales of peacocks, stars, and gentle forest breezes passed down from mothers to daughters.',
            imageUrl:
                'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
            likesCount: 112,
            commentsCount: 15,
          ),
        ],
      ),
      CulturalTheme(
        id: 'northern_heritage_history',
        title: 'Northern Heritage & Living History',
        membersCount: '720 Members',
        activeEldersCount: '31 Active Elders',
        imageUrl:
            'https://media-cdn.tripadvisor.com/media/attractions-splice-spp-720x480/0a/4c/7b/2a.jpg',
        category: 'History',
        description:
            'Explore Jaffna temples, historic homes, inscriptions, local landmarks and the memories elders carry about how their communities changed over time.',
        knowledgePosts: const [],
      ),
      CulturalTheme(
        id: 'tamil_dialects',
        title: 'Tamil Dialects & Oral Expressions',
        membersCount: '540 Members',
        activeEldersCount: '24 Active Elders',
        imageUrl:
            'https://specials-images.forbesimg.com/imageserve/677ec972d1d7c86cf65676f3/A-woman-and-her-elderly-relative-engaging-in-an-intimate-chat-/960x0.jpg?fit=scale',
        category: 'Local Dialects',
        description:
            'Collect regional words, sayings, pronunciation and everyday expressions, with elders explaining when and where each phrase is used.',
        knowledgePosts: const [],
      ),
      CulturalTheme(
        id: 'home_garden_healing',
        title: 'Home Gardens & Traditional Healing',
        membersCount: '460 Members',
        activeEldersCount: '19 Active Elders',
        imageUrl:
            'https://www.botanicgardens.gov.lk/wp-content/uploads/2021/10/3A8A0475.jpg',
        category: 'Ayurveda & Healing',
        description:
            'Document traditional home-garden plants, preparation customs and family knowledge. Shared knowledge is for cultural learning, not medical advice.',
        knowledgePosts: const [],
      ),
    ];
  }

  static List<CategoryItem> getCategories() {
    return const [
      CategoryItem(
        title: 'History',
        subtitle: 'Ancient Archives',
        imageUrl:
            'https://media-cdn.tripadvisor.com/media/attractions-splice-spp-720x480/0a/4c/7b/2a.jpg',
        categoryKey: 'history',
      ),
      CategoryItem(
        title: 'Food',
        subtitle: 'Heritage Recipes',
        imageUrl:
            'https://assets.roar.media/Life/2017/04/Jaffna-food1.jpg?w=1200',
        categoryKey: 'food',
      ),
      CategoryItem(
        title: 'Performing Arts',
        subtitle: 'Traditional Dance',
        imageUrl:
            'https://cdn.audleytravel.com/1400/1000/60/352521-kandyan-dancers-kandy.jpg',
        categoryKey: 'performing_arts',
      ),
      CategoryItem(
        title: 'Traditional Music',
        subtitle: 'Rhythm & Verse',
        imageUrl:
            'https://s3.ap-southeast-1.amazonaws.com/cdn.sannasa.lk/media/3399/conversions/WhatsApp-Image-2024-08-05-at-03.24.57-w_1024.jpg',
        categoryKey: 'music',
      ),
      CategoryItem(
        title: 'Local Dialects',
        subtitle: 'Idioms & Tongue',
        imageUrl:
            'https://feeds.abplive.com/onecms/images/uploaded-images/2021/05/18/33a07e341974b3174cb1063913df3ffc_original.jpg',
        categoryKey: 'dialects',
      ),
      CategoryItem(
        title: 'Ayurveda & Healing',
        subtitle: 'Medicinal Lore',
        imageUrl:
            'https://www.botanicgardens.gov.lk/wp-content/uploads/2021/10/3A8A0475.jpg',
        categoryKey: 'ayurveda',
      ),
    ];
  }
}
