import 'package:flutter/material.dart';
import '../config/api_config.dart';

class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({
    super.key,
    required this.name,
    this.image,
    this.radius = 22,
  });
  final String name;
  final String? image;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        name.trim().isEmpty ? 'Y' : name.trim().substring(0, 1).toUpperCase(),
        style: TextStyle(
          fontSize: radius * .85,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF4A2C1A),
        ),
      ),
    );
    final path = image?.trim() ?? '';
    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFFEAD9C6),
          child: path.isEmpty
              ? fallback
              : Image.network(
                  path.startsWith('/') ? '${ApiConfig.baseUrl}$path' : path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}
