import 'package:flutter/material.dart';
import '../widgets/content_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'YATHRA',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 2,
              ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFFD8CAB8),
            ),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stories, folklore, crafts...',
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip(context, 'All', true),
                _buildCategoryChip(context, 'Oral Stories', false),
                _buildCategoryChip(context, 'Traditional Food', false),
                _buildCategoryChip(context, 'Folk Lore', false),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                ContentCard(
                  author: 'Appaiah (Jaffna)',
                  time: '1h ago',
                  title: 'Traditional Palmyra Sweet Treats',
                  description: 'Using the sweet syrup extracted during the dry season...',
                  likes: 142,
                  comments: 18,
                  hasVideo: true,
                ),
                ContentCard(
                  author: 'Gunasekara (Kandy)',
                  time: '3h ago',
                  title: 'Brass Crafting Secrets of Kandy',
                  description: 'The art of metalwork has been in our family for five generations...',
                  likes: 89,
                  comments: 5,
                  hasVideo: false,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
