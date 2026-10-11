import 'package:flutter/material.dart';
import '../models/connection_model.dart';
import '../models/user_model.dart';
import '../services/culture_connect_service.dart';
import 'youth_story_detail_page.dart';

class MyConnectionsPage extends StatefulWidget {
  const MyConnectionsPage({super.key, required this.isElder});
  final bool isElder;
  @override
  State<MyConnectionsPage> createState() => _MyConnectionsPageState();
}

class _MyConnectionsPageState extends State<MyConnectionsPage>
    with SingleTickerProviderStateMixin {
  final _service = CultureConnectService();
  late final TabController _tabs = TabController(length: 3, vsync: this)
    ..addListener(() {
      if (mounted) setState(() {});
    });
  List<Connection> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getConnections();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic>? _peer(Connection c) =>
      widget.isElder ? c.requester : c.receiver;
  List<Connection> get _filtered {
    final state = ['all', 'pending', 'accepted'][_tabs.index];
    return _items
        .where(
          (c) =>
              (widget.isElder ? c.receiverId : c.requesterId).isNotEmpty &&
              (state == 'all' || c.status == state),
        )
        .toList();
  }

  void _openChat(Connection c) {
    final peer = _peer(c);
    if (peer == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(connection: c, peer: User.fromJson(peer)),
      ),
    ).then((_) => _load());
  }

  void _openWorkspace(Connection c) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WorkspacePage(connection: c)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F3EA),
    appBar: AppBar(
      title: const Text('My Connections'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Pending'),
          Tab(text: 'Connected'),
        ],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: _filtered.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No connections here yet.')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = _filtered[i];
                      final peer = _peer(c) ?? {};
                      final name = peer['name']?.toString() ?? 'YATHRA member';
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEADCC9),
                            child: Icon(
                              Icons.person_outline,
                              color: Color(0xFF4A2C1A),
                            ),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            c.status == 'accepted'
                                ? (c.communityName.isEmpty
                                      ? 'Connected'
                                      : c.communityName)
                                : c.status == 'rejected'
                                ? 'Request declined'
                                : 'Pending',
                          ),
                          trailing: c.status == 'accepted'
                              ? Wrap(
                                  spacing: 0,
                                  children: [
                                    IconButton(
                                      tooltip: 'Message',
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                      ),
                                      onPressed: () => _openChat(c),
                                    ),
                                    IconButton(
                                      tooltip: 'Workspace',
                                      icon: const Icon(Icons.edit_note),
                                      onPressed: () => _openWorkspace(c),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
  );
}

class ConnectionNotificationsPage extends StatefulWidget {
  const ConnectionNotificationsPage({super.key});
  @override
  State<ConnectionNotificationsPage> createState() =>
      _ConnectionNotificationsPageState();
}

class _ConnectionNotificationsPageState
    extends State<ConnectionNotificationsPage> {
  final _service = CultureConnectService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getNotifications();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _respond(String id, String status) async {
    try {
      await _service.respond(id, status);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F3EA),
    appBar: AppBar(title: const Text('Notifications')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: TextButton(onPressed: _load, child: Text('Retry: $_error')),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: _items.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 130),
                      Center(child: Text('No new connection requests.')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, i) {
                      final raw = _items[i];
                      final c = Connection.fromJson(raw);
                      final youth = raw['requester'] as Map? ?? {};
                      final name = youth['name']?.toString() ?? 'A youth';
                      return Card(
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'requested to connect with you${c.communityName.isEmpty ? '.' : ' about ${c.communityName}.'}',
                              ),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () => _respond(c.id, 'accepted'),
                                    child: const Text('Accept'),
                                  ),
                                  TextButton(
                                    onPressed: () => _respond(c.id, 'rejected'),
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.connection, required this.peer});
  final Connection connection;
  final User peer;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _service = CultureConnectService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  String? _error;
  bool _sending = false;
  String? _myId;
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _myId = await _service.currentUserId;
    await _load();
  }

  Future<void> _load() async {
    try {
      final m = await _service.getMessages(widget.connection.id);
      if (mounted) {
        setState(() {
          _messages = m;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.sendMessage(widget.connection.id, text);
      _input.clear();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F3EA),
    appBar: AppBar(
      title: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.person)),
          const SizedBox(width: 10),
          Expanded(child: Text(widget.peer.name)),
        ],
      ),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    body: Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) {
              final m = _messages[i];
              final mine = m['sender']?.toString() == _myId;
              final sentAt = DateTime.tryParse(
                m['createdAt']?.toString() ?? '',
              )?.toLocal();
              final timeLabel = sentAt == null
                  ? ''
                  : '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: mine ? const Color(0xFFEADCC9) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(m['text']?.toString() ?? ''),
                      if (timeLabel.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key, required this.connection});
  final Connection connection;
  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage>
    with SingleTickerProviderStateMixin {
  final _service = CultureConnectService();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _instructions = TextEditingController();
  late final _tabs = TabController(length: 3, vsync: this);
  String _community = '';
  String _youthName = 'Youth';
  String _elderName = 'Elder';
  String? _youthAvatar;
  String? _elderAvatar;
  bool _loading = true;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _title.dispose();
    _content.dispose();
    _instructions.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getWorkspace(widget.connection.id);
      final w = Map<String, dynamic>.from(data['workspace'] as Map);
      final requester = Map<String, dynamic>.from(
        data['requester'] as Map? ?? {},
      );
      final receiver = Map<String, dynamic>.from(
        data['receiver'] as Map? ?? {},
      );
      final requesterProfile = Map<String, dynamic>.from(
        requester['profileInfo'] as Map? ?? {},
      );
      final receiverProfile = Map<String, dynamic>.from(
        receiver['profileInfo'] as Map? ?? {},
      );
      if (!mounted) return;
      setState(() {
        _community = data['communityName']?.toString() ?? '';
        _youthName = requester['name']?.toString() ?? 'Youth';
        _elderName = receiver['name']?.toString() ?? 'Elder';
        _youthAvatar = requesterProfile['avatar']?.toString();
        _elderAvatar = receiverProfile['avatar']?.toString();
        _title.text = w['title']?.toString() ?? '';
        _content.text = w['content']?.toString() ?? '';
        _instructions.text = w['instructions']?.toString() ?? '';
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _save({bool publish = false}) async {
    if (_busy) return;
    if (publish &&
        (_title.text.trim().isEmpty || _content.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a title and cultural content before publishing.'),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _service.saveWorkspace(
        widget.connection.id,
        title: _title.text,
        content: _content.text,
        instructions: _instructions.text,
      );
      if (publish) {
        final result = await _service.publish(widget.connection.id);
        if (!mounted) return;
        final story = Map<String, dynamic>.from(result['story'] as Map);
        final storyId = story['_id']?.toString();
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Story Published!'),
            content: const Text(
              'Your collaborative content has been published and added to the community.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'another'),
                child: const Text('Create Another'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'view'),
                child: const Text('View Story'),
              ),
            ],
          ),
        );
        if (!mounted) return;
        if (action == 'view' && storyId != null) {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => YouthStoryDetailPage(storyId: storyId),
            ),
          );
        } else if (action == 'another') {
          _title.clear();
          _content.clear();
          _instructions.clear();
          await _service.saveWorkspace(
            widget.connection.id,
            title: '',
            content: '',
            instructions: '',
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Draft saved.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F3EA),
    appBar: AppBar(
      title: const Text('Collaborative Workspace'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(text: 'Content'),
          Tab(text: 'Tasks'),
          Tab(text: 'Files'),
        ],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabs,
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    _community.isEmpty ? 'Culture Connect' : _community,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ParticipantChip(name: _youthName, avatar: _youthAvatar),
                      const SizedBox(width: 12),
                      _ParticipantChip(name: _elderName, avatar: _elderAvatar),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _content,
                    minLines: 5,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      labelText: 'Cultural story / content',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _instructions,
                    minLines: 3,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Instructions / description',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _busy ? null : () => _save(),
                        child: const Text('Save Draft'),
                      ),
                      ElevatedButton(
                        onPressed: _busy ? null : () => _save(publish: true),
                        child: Text(_busy ? 'Saving...' : 'Publish'),
                      ),
                    ],
                  ),
                ],
              ),
              const Center(
                child: Text('Add shared tasks here as your project grows.'),
              ),
              const Center(child: Text('No shared files yet.')),
            ],
          ),
  );
}

class _ParticipantChip extends StatelessWidget {
  const _ParticipantChip({required this.name, required this.avatar});
  final String name;
  final String? avatar;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(
        backgroundImage: avatar == null || avatar!.isEmpty
            ? null
            : NetworkImage(avatar!),
        child: avatar == null || avatar!.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      const SizedBox(width: 6),
      Text(name, style: const TextStyle(fontSize: 12)),
    ],
  );
}
