import 'package:flutter/material.dart';

class ContentCard extends StatelessWidget {
  final String author;
  final String time;
  final String title;
  final String description;
  final int likes;
  final int comments;
  final bool hasVideo;

  const ContentCard({
    super.key,
    required this.author,
    required this.time,
    required this.title,
    required this.description,
    required this.likes,
    required this.comments,
    required this.hasVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFD8CAB8),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EAE0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.image_outlined, size: 50, color: Colors.black12),
                if (hasVideo)
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.play_arrow, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '0:45',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
              const SizedBox(width: 5),
              Text('$likes', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 20),
              const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
              const SizedBox(width: 5),
              Text('$comments', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"$description"',
            style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
