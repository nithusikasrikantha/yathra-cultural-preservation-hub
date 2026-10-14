import 'package:flutter/material.dart';
import 'author_avatar.dart';
import '../pages/culture_connect_pages.dart';
import '../services/culture_connect_service.dart';
import '../models/connection_model.dart';

class HomeTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTopBar({
    super.key,
    required this.isElder,
    this.onProfile,
    this.avatar,
    this.userName = '',
  });
  final bool isElder;
  final String? avatar;
  final String userName;
  final VoidCallback? onProfile;
  static const _brown = Color(0xFF4A2C1A);
  @override
  Size get preferredSize => const Size.fromHeight(60);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    centerTitle: false,
    elevation: 0,
    backgroundColor: const Color(0xFFF9F5EC),
    titleSpacing: 20,
    title: const Text(
      'YATHRA',
      style: TextStyle(
        fontFamily: 'Serif',
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: _brown,
      ),
    ),
    actions: [
      IconButton(
        tooltip: 'Notifications',
        icon: const Icon(Icons.notifications_none_rounded, color: _brown),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isElder
                ? const ConnectionNotificationsPage()
                : const _YouthUpdatesPage(),
          ),
        ),
      ),
      PopupMenuButton<String>(
        tooltip: 'My connections and projects',
        icon: const Icon(Icons.people_alt_outlined, color: _brown),
        color: const Color(0xFFFFFDF8),
        position: PopupMenuPosition.under,
        onSelected: (value) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => value == 'projects'
                ? WorkspacePage(isElder: isElder)
                : MyConnectionsPage(isElder: isElder),
          ),
        ),
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'projects',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.folder_outlined),
              title: Text('My Projects'),
            ),
          ),
          PopupMenuItem(
            value: 'connections',
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.people_alt_outlined),
              title: Text('My Connections'),
            ),
          ),
        ],
      ),
      IconButton(
        tooltip: 'Profile',
        onPressed: onProfile,
        icon: AuthorAvatar(name: userName, image: avatar, radius: 17),
      ),
      const SizedBox(width: 8),
    ],
  );
}

class DiscoveryHeading extends StatelessWidget {
  const DiscoveryHeading({super.key, required this.onSearch});
  final ValueChanged<String> onSearch;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Discover your roots',
        style: TextStyle(
          fontFamily: 'Serif',
          fontSize: 30,
          height: 1.15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A2C1A),
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'Stories that connect generations.',
        style: TextStyle(fontSize: 15, color: Color(0xFF75675B)),
      ),
      const SizedBox(height: 16),
      TextField(
        onChanged: onSearch,
        decoration: InputDecoration(
          hintText: 'Search stories, traditions and places',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF88796D)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF75675B)),
          filled: true,
          fillColor: const Color(0xFFFFFDF8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2D6C5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2D6C5)),
          ),
        ),
      ),
    ],
  );
}

class _YouthUpdatesPage extends StatefulWidget {
  const _YouthUpdatesPage();
  @override
  State<_YouthUpdatesPage> createState() => _YouthUpdatesPageState();
}

class _YouthUpdatesPageState extends State<_YouthUpdatesPage> {
  late Future<List<Connection>> _updates = CultureConnectService()
      .getConnections();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9F5EC),
    appBar: AppBar(title: const Text('Notifications')),
    body: FutureBuilder<List<Connection>>(
      future: _updates,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(
            child: TextButton(
              onPressed: () => setState(
                () => _updates = CultureConnectService().getConnections(),
              ),
              child: const Text('Retry loading connection updates'),
            ),
          );
        final items = snapshot.data ?? [];
        if (items.isEmpty)
          return const Center(child: Text('No connection updates yet.'));
        return ListView(
          children: items
              .map(
                (connection) => ListTile(
                  leading: const Icon(Icons.people_alt_outlined),
                  title: Text(
                    connection.receiver?['name']?.toString() ??
                        'Elder connection',
                  ),
                  subtitle: Text(
                    'Connection ${connection.status}${connection.communityName.isEmpty ? '' : ' · ${connection.communityName}'}',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyConnectionsPage(isElder: false),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}
