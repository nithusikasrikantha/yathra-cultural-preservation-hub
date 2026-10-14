import 'package:flutter/material.dart';
import '../models/connection_model.dart';
import '../models/user_model.dart';
import '../services/culture_connect_service.dart';
import '../services/culture_assistant_fallback.dart';
import '../services/published_content_signal.dart';
import 'youth_story_detail_page.dart';
import 'elder/share_story_page.dart';
import 'elder/story_details_page.dart';
import '../services/story_service.dart';

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

  String _workspaceStatusLabel(Connection connection) {
    final status = connection.workspaceItems.isNotEmpty
        ? connection.workspaceItems.last['status']?.toString() ??
              connection.workspaceStatus
        : connection.workspaceStatus;
    return switch (status) {
      'under_review' => 'Under Review',
      'changes_requested' => 'Changes Requested',
      'approved' => 'Approved',
      'published' => 'Published',
      _ => 'Workspace Draft',
    };
  }

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

  Future<void> _respondToRequest(Connection connection, String status) async {
    try {
      await _service.respond(connection.id, status);
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
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
      MaterialPageRoute(
        builder: (_) => WorkspacePage(connection: c, isElder: widget.isElder),
      ),
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
                      final profile = peer['profileInfo'] is Map
                          ? Map<String, dynamic>.from(
                              peer['profileInfo'] as Map,
                            )
                          : <String, dynamic>{};
                      final avatar = profile['avatar']?.toString();
                      final name = peer['name']?.toString() ?? 'YATHRA member';
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFEADCC9),
                            backgroundImage: avatar == null || avatar.isEmpty
                                ? null
                                : NetworkImage(avatar),
                            child: avatar == null || avatar.isEmpty
                                ? const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF4A2C1A),
                                  )
                                : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            c.status == 'accepted'
                                ? '${c.communityName.isEmpty ? 'Connected' : c.communityName} • ${_workspaceStatusLabel(c)}'
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
                                      tooltip: 'My Workspace',
                                      icon: const Icon(Icons.edit_note),
                                      onPressed: () => _openWorkspace(c),
                                    ),
                                  ],
                                )
                              : widget.isElder && c.status == 'pending'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Accept request',
                                      color: const Color(0xFF3D7A43),
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      onPressed: () =>
                                          _respondToRequest(c, 'accepted'),
                                    ),
                                    IconButton(
                                      tooltip: 'Reject request',
                                      color: const Color(0xFF9D3D20),
                                      icon: const Icon(Icons.cancel_outlined),
                                      onPressed: () =>
                                          _respondToRequest(c, 'rejected'),
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
  List<String> _suggestedQuestions = [];
  String? _error;
  bool _sending = false;
  bool _assistantBusy = false;
  bool _usingQuestionFallback = false;
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

  Future<void> _suggestQuestions({required bool followUp}) async {
    if (_assistantBusy) return;
    if (followUp && _messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start chatting first to get follow-up questions.'),
        ),
      );
      return;
    }

    setState(() {
      _assistantBusy = true;
      _suggestedQuestions = [];
    });
    var usingFallback = false;
    try {
      List<String> questions;
      try {
        final response = await _service.askAssistant(
          followUp ? 'follow-up-questions' : 'conversation-starters',
          widget.connection.id,
          topic: widget.connection.communityName.isNotEmpty
              ? widget.connection.communityName
              : widget.peer.profileInfo.interests.join(', '),
        );
        final result = Map<String, dynamic>.from(response['result'] as Map);
        questions = (result['questions'] as List? ?? [])
            .map((question) => question.toString().trim())
            .where((question) => question.isNotEmpty)
            .toList();
        if (questions.isEmpty) throw Exception('No questions returned.');
      } catch (_) {
        usingFallback = true;
        final latestElderMessage = _messages.lastWhere(
          (message) => message['sender']?.toString() != _myId,
          orElse: () => <String, dynamic>{},
        );
        questions = CultureAssistantFallback.questions(
          topic: widget.connection.communityName.isNotEmpty
              ? widget.connection.communityName
              : widget.peer.profileInfo.interests.join(', '),
          answer: followUp ? latestElderMessage['text']?.toString() ?? '' : '',
        );
      }
      if (!mounted) return;
      setState(() {
        _suggestedQuestions = questions;
        _usingQuestionFallback = usingFallback;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _assistantBusy = false);
    }
  }

  void _useSuggestedQuestion(String question) {
    _input
      ..text = question
      ..selection = TextSelection.collapsed(offset: question.length);
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
          child: Material(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _assistantBusy
                            ? null
                            : () => _suggestQuestions(followUp: false),
                        icon: const Icon(Icons.lightbulb_outline, size: 18),
                        label: const Text('Suggest Questions'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _assistantBusy || _messages.isEmpty
                            ? null
                            : () => _suggestQuestions(followUp: true),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Follow-up Questions'),
                      ),
                    ],
                  ),
                  if (_assistantBusy)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (_suggestedQuestions.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _usingQuestionFallback
                                ? 'Sample questions'
                                : 'AI suggested questions',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B4226),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Close suggestions',
                          onPressed: () => setState(() {
                            _suggestedQuestions = [];
                          }),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestedQuestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => ActionChip(
                          label: Text(
                            _suggestedQuestions[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () =>
                              _useSuggestedQuestion(_suggestedQuestions[index]),
                        ),
                      ),
                    ),
                  ],
                  Row(
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
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key, this.connection, this.isElder = false});
  final Connection? connection;
  final bool isElder;
  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  final _service = CultureConnectService();
  List<Connection> _projects = [];
  bool _loading = true;
  String? _error;

  String _statusFilter = 'all';
  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (mounted)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final connections = await _service.getConnections();
      final projects = connections
          .where(
            (c) =>
                c.status == 'accepted' &&
                (widget.connection == null || c.id == widget.connection!.id),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _statusLabel(String status) => switch (status) {
    'under_review' => 'Under Review',
    'changes_requested' => 'Changes Requested',
    'approved' => 'Approved',
    'published' => 'Published',
    _ => 'Draft',
  };

  String _actionLabel(String status) => switch (status) {
    'under_review' => widget.isElder ? 'Review' : 'View Project',
    'approved' => widget.isElder ? 'Publish' : 'View Project',
    'published' => 'View Project',
    'changes_requested' =>
      widget.isElder ? 'View Requested Changes' : 'Revise Contribution',
    _ => 'Continue Draft',
  };

  List<Map<String, dynamic>> _entries(Connection connection) {
    final entries = [...connection.workspaceItems];
    final legacy = connection.workspace;
    final legacyStatus = legacy['status']?.toString() ?? 'draft';
    if (connection.workspaceTitle.trim().isNotEmpty ||
        legacy['content']?.toString().trim().isNotEmpty == true ||
        legacyStatus != 'draft') {
      entries.add({...legacy, '_id': 'legacy'});
    }
    entries.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['updatedAt']?.toString() ?? '') ?? DateTime(2000);
      final bDate =
          DateTime.tryParse(b['updatedAt']?.toString() ?? '') ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return entries;
  }

  String _connectionName(Connection connection) {
    final peer = widget.isElder ? connection.requester : connection.receiver;
    return peer?['name']?.toString() ??
        (widget.isElder ? 'Connected youth' : 'Connected elder');
  }

  Future<void> _openEditor(
    Connection project, {
    String? workspaceItemId,
  }) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => WorkspaceEditorPage(
          connection: project,
          isElder: widget.isElder,
          workspaceItemId: workspaceItemId,
        ),
      ),
    );
    if (mounted) _loadProjects();
  }

  Future<void> _addContent(Connection project) async {
    try {
      final result = await _service.createWorkspaceItem(project.id);
      final item = Map<String, dynamic>.from(result['item'] as Map);
      if (!mounted) return;
      await _openEditor(project, workspaceItemId: item['_id']?.toString());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F3EA),
    appBar: AppBar(title: const Text('My Projects')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(
                  onPressed: _loadProjects,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadProjects,
            child: _projects.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 130),
                      Center(
                        child: Text(
                          widget.connection == null
                              ? 'Accept or make a connection to start a project.'
                              : 'No content yet. Add Content to start working together.',
                        ),
                      ),
                      if (widget.connection != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: FilledButton.icon(
                            onPressed: () => _addContent(widget.connection!),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Content'),
                          ),
                        ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        widget.connection == null
                            ? (widget.isElder
                                  ? 'Contributions from your connected youth'
                                  : 'Your cultural contributions with elders')
                            : 'Workspace with ${_connectionName(_projects.first)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final status in [
                              'all',
                              'draft',
                              'under_review',
                              'changes_requested',
                              'approved',
                              'published',
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    status == 'all'
                                        ? 'All'
                                        : _statusLabel(status),
                                  ),
                                  selected: _statusFilter == status,
                                  selectedColor: const Color(0xFFEAD9C6),
                                  onSelected: (_) =>
                                      setState(() => _statusFilter = status),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_statusFilter != 'all' &&
                          !_projects.any(
                            (project) => _entries(project).any(
                              (entry) =>
                                  (entry['status'] ?? 'draft') == _statusFilter,
                            ),
                          ))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No ${_statusLabel(_statusFilter).toLowerCase()} contributions yet.',
                          ),
                        ),
                      for (final project in _projects.where(
                        (project) =>
                            _statusFilter == 'all' ||
                            _entries(project).any(
                              (entry) =>
                                  (entry['status'] ?? 'draft') == _statusFilter,
                            ),
                      )) ...[
                        Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      color: Color(0xFF6B321D),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _connectionName(project),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (project.communityName.isNotEmpty)
                                      Flexible(
                                        child: Text(
                                          project.communityName,
                                          textAlign: TextAlign.end,
                                          style: const TextStyle(
                                            color: Color(0xFF75675C),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () => _addContent(project),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Add Content'),
                                  ),
                                ),
                                for (final entry in _entries(project).where(
                                  (entry) =>
                                      _statusFilter == 'all' ||
                                      (entry['status'] ?? 'draft') ==
                                          _statusFilter,
                                )) ...[
                                  const Divider(height: 22),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_stories_outlined,
                                        color: Color(0xFF6B321D),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          entry['title']
                                                      ?.toString()
                                                      .trim()
                                                      .isNotEmpty ==
                                                  true
                                              ? entry['title'].toString()
                                              : 'Untitled contribution',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      _ProjectStatusChip(
                                        label: _statusLabel(
                                          entry['status']?.toString() ??
                                              'draft',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: FilledButton.icon(
                                      onPressed: () => _openEditor(
                                        project,
                                        workspaceItemId: entry['_id']
                                            ?.toString(),
                                      ),
                                      icon: Icon(
                                        ['draft', 'changes_requested'].contains(
                                              entry['status']?.toString(),
                                            )
                                            ? Icons.edit_outlined
                                            : Icons.open_in_new,
                                      ),
                                      label: Text(
                                        _actionLabel(
                                          entry['status']?.toString() ??
                                              'draft',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
  );
}

class _ProjectStatusChip extends StatelessWidget {
  const _ProjectStatusChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Published' => const Color(0xFF2B765B),
      'Approved' => const Color(0xFF39745D),
      'Under Review' => const Color(0xFFC17A1A),
      'Changes Requested' => const Color(0xFF9D3D20),
      _ => const Color(0xFF6B4226),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class WorkspaceEditorPage extends StatefulWidget {
  const WorkspaceEditorPage({
    super.key,
    required this.connection,
    this.isElder = false,
    this.workspaceItemId,
  });
  final Connection connection;
  final bool isElder;
  final String? workspaceItemId;
  @override
  State<WorkspaceEditorPage> createState() => _WorkspaceEditorPageState();
}

class _WorkspaceEditorPageState extends State<WorkspaceEditorPage> {
  Map<String, dynamic> _initialStory = {};
  Map<String, dynamic> Function()? _getStoryFields;
  final _service = CultureConnectService();
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _instructions = TextEditingController();
  final _tags = TextEditingController();
  final _category = TextEditingController();
  final _significance = TextEditingController();
  final _reviewNote = TextEditingController();
  String _community = '';
  String _youthName = 'Youth';
  String _elderName = 'Elder';
  String _contentType = 'Story';
  String _language = 'Tamil';
  String _status = 'draft';
  String? _youthAvatar;
  String? _elderAvatar;
  String? _storyId;
  String _imageDataUri = '';
  bool _loading = true;
  bool _busy = false;

  bool get _youthCanEdit =>
      !widget.isElder && ['draft', 'changes_requested'].contains(_status);
  bool get _elderCanReview => widget.isElder && _status == 'under_review';
  bool get _elderCanDraft => widget.isElder && _status == 'draft';
  bool get _canEdit => _youthCanEdit || _elderCanReview || _elderCanDraft;

  String get _statusLabel => switch (_status) {
    'under_review' => 'Under Review',
    'changes_requested' => 'Changes Requested',
    'approved' => 'Approved',
    'published' => 'Published',
    _ => 'Draft',
  };
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _instructions.dispose();
    _tags.dispose();
    _category.dispose();
    _significance.dispose();
    _reviewNote.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _service.getWorkspace(
        widget.connection.id,
        workspaceItemId: widget.workspaceItemId,
      );
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
        _initialStory = {
          ...w,
          'storyText': w['content'] ?? '',
          'category': (w['category']?.toString().isNotEmpty ?? false)
              ? w['category']
              : 'Traditional Story',
          'communityId': data['communityId'] ?? widget.connection.communityId,
          'communityName': data['communityName'] ?? '',
        };
        _title.text = w['title']?.toString() ?? '';
        _content.text = w['content']?.toString() ?? '';
        _instructions.text = w['instructions']?.toString() ?? '';
        _contentType = w['contentType']?.toString() ?? 'Story';
        _language = w['language']?.toString() ?? 'Tamil';
        _status = w['status']?.toString() ?? 'draft';
        _tags.text = (w['tags'] as List? ?? []).join(', ');
        _category.text = w['category']?.toString() ?? '';
        _significance.text = w['culturalSignificance']?.toString() ?? '';
        _imageDataUri = w['imageDataUri']?.toString() ?? '';
        _reviewNote.text = w['reviewNote']?.toString() ?? '';
        _storyId = w['storyId']?.toString();
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

  Future<void> _persistWorkspace() async {
    final fields = _getStoryFields?.call() ?? _initialStory;
    if (fields['_uploading'] == true)
      throw StateError('Wait for your photos to finish uploading.');
    _title.text = fields['title']?.toString() ?? '';
    _content.text = fields['storyText']?.toString() ?? '';
    _category.text = fields['category']?.toString() ?? '';
    _language = fields['language']?.toString() ?? 'Tamil';
    await _service.saveWorkspace(
      widget.connection.id,
      workspaceItemId: widget.workspaceItemId,
      title: _title.text,
      content: _content.text,
      instructions: _instructions.text,
      contentType: _contentType,
      language: _language,
      tags: _tags.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      culturalSignificance: _significance.text,
      category: _category.text,
      imageDataUri: _imageDataUri,
      storyFields: fields,
    );
  }

  Future<void> _saveDraft() async {
    if (_busy || !(_youthCanEdit || _elderCanDraft)) return;
    setState(() => _busy = true);
    try {
      await _persistWorkspace();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved in My Workspace.')),
      );
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitForReview() async {
    final fields = _getStoryFields?.call();
    if (fields != null) {
      _title.text = fields['title']?.toString() ?? '';
      _content.text = fields['storyText']?.toString() ?? '';
    }
    if (_busy || !_youthCanEdit) return;
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add a title and contribution before sending for review.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await _persistWorkspace();
      await _service.submitForReview(
        widget.connection.id,
        workspaceItemId: widget.workspaceItemId,
      );
      if (!mounted) return;
      setState(() => _status = 'under_review');
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contribution Sent'),
          content: Text(
            'Your contribution was sent to $_elderName for review.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _saveElderEdits() async {
    if (_busy || !_elderCanReview) return;
    setState(() => _busy = true);
    try {
      await _persistWorkspace();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Review changes saved.')));
      }
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestChanges() async {
    if (_busy || !_elderCanReview) return;
    setState(() => _busy = true);
    try {
      await _persistWorkspace();
      await _service.requestChanges(
        widget.connection.id,
        note: _reviewNote.text,
        workspaceItemId: widget.workspaceItemId,
      );
      if (mounted) {
        setState(() => _status = 'changes_requested');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Changes requested from $_youthName.')),
        );
      }
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    final fields = _getStoryFields?.call();
    if (fields != null) {
      _title.text = fields['title']?.toString() ?? '';
      _content.text = fields['storyText']?.toString() ?? '';
    }
    if (_busy || !_elderCanReview) return;
    setState(() => _busy = true);
    try {
      await _persistWorkspace();
      await _service.approveContribution(
        widget.connection.id,
        workspaceItemId: widget.workspaceItemId,
      );
      if (mounted) setState(() => _status = 'approved');
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _publish() async {
    final fields = _getStoryFields?.call();
    if (fields != null) {
      _title.text = fields['title']?.toString() ?? '';
      _content.text = fields['storyText']?.toString() ?? '';
    }
    if (_busy || !widget.isElder || _status != 'approved') return;
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a title and content before publishing.'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm and publish'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _title.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _content.text,
                style: const TextStyle(fontSize: 17, height: 1.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'This approved contribution will appear in the shared feed and its linked community.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await _service.publish(
        widget.connection.id,
        workspaceItemId: widget.workspaceItemId,
      );
      final story = Map<String, dynamic>.from(result['story'] as Map);
      _storyId = story['_id']?.toString();
      if (!mounted) return;
      setState(() => _status = 'published');
      PublishedContentSignal.notify();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Published to YATHRA'),
          content: const Text(
            'The contribution is now available in the shared feed, category, and linked community.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPublishedStory() async {
    if (_storyId == null) return;
    try {
      if (widget.isElder) {
        final story = await const StoryService().fetchStoryById(_storyId!);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoryDetailsPage(story: story)),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YouthStoryDetailPage(storyId: _storyId!),
          ),
        );
      }
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F3EA),
    appBar: AppBar(
      title: Text(
        _youthCanEdit || _elderCanDraft ? 'Add Content' : 'Project Review',
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WorkspaceStatusCard(
                status: _statusLabel,
                note: _status == 'changes_requested' ? _reviewNote.text : '',
                isElder: widget.isElder,
              ),
              const SizedBox(height: 14),
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
              ShareStoryPage(
                embedded: true,
                collaborationId: widget.connection.id,
                readOnly: !_canEdit,
                storyToEdit: _initialStory,
                onFieldsReady: (getter) => _getStoryFields = getter,
              ),
              if (widget.isElder && _status == 'under_review') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewNote,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note for youth (optional)',
                    hintText: 'Explain what needs to be changed',
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (_youthCanEdit || _elderCanDraft)
                    ? [
                        OutlinedButton(
                          onPressed: _busy ? null : _saveDraft,
                          child: const Text('Save Draft'),
                        ),
                        if (_youthCanEdit)
                          ElevatedButton(
                            onPressed: _busy ? null : _submitForReview,
                            child: Text(
                              _busy ? 'Sending...' : 'Send for Review',
                            ),
                          ),
                      ]
                    : _elderCanReview
                    ? [
                        OutlinedButton(
                          onPressed: _busy ? null : _saveElderEdits,
                          child: const Text('Save Changes'),
                        ),
                        OutlinedButton(
                          onPressed: _busy ? null : _requestChanges,
                          child: const Text('Request Changes'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _busy ? null : _approve,
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(_busy ? 'Approving...' : 'Approve'),
                        ),
                      ]
                    : [
                        if (widget.isElder && _status == 'approved')
                          ElevatedButton.icon(
                            onPressed: _busy ? null : _publish,
                            icon: const Icon(Icons.publish_rounded),
                            label: Text(
                              _busy ? 'Publishing...' : 'Review and Publish',
                            ),
                          ),
                        if (_status == 'published' && _storyId != null)
                          OutlinedButton(
                            onPressed: _openPublishedStory,
                            child: const Text('View Published Story'),
                          ),
                        if (_status == 'under_review' && !widget.isElder)
                          const Text(
                            'Waiting for the elder to review this contribution.',
                          ),
                        if (_status == 'approved' && !widget.isElder)
                          const Text(
                            'The elder approved this contribution. It will appear in Explore after publishing.',
                          ),
                        if (_status == 'changes_requested' && widget.isElder)
                          const Text(
                            'Waiting for the youth to update this contribution.',
                          ),
                      ],
              ),
            ],
          ),
  );
}

class _WorkspaceStatusCard extends StatelessWidget {
  const _WorkspaceStatusCard({
    required this.status,
    required this.note,
    required this.isElder,
  });

  final String status;
  final String note;
  final bool isElder;

  @override
  Widget build(BuildContext context) {
    final color = status == 'Published'
        ? const Color(0xFF2B765B)
        : status == 'Approved'
        ? const Color(0xFF39745D)
        : status == 'Under Review'
        ? const Color(0xFFC17A1A)
        : status == 'Changes Requested'
        ? const Color(0xFF9D3D20)
        : const Color(0xFF6B4226);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            status == 'Published' || status == 'Approved'
                ? Icons.check_circle
                : Icons.pending_actions,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 3),
                Text(
                  status == 'Under Review'
                      ? (isElder
                            ? 'Review, edit, request changes, or approve this youth contribution.'
                            : 'The elder will review this contribution. You cannot publish it.')
                      : status == 'Approved'
                      ? (isElder
                            ? 'This contribution is approved and ready to publish.'
                            : 'The elder approved this contribution. It will appear in Explore after publishing.')
                      : status == 'Changes Requested'
                      ? 'Review the elder note, update your content, and send it again.'
                      : status == 'Published'
                      ? 'This contribution is available to the YATHRA community.'
                      : 'Your draft is visible only to you and your connected elder.',
                  style: const TextStyle(fontSize: 12.5, height: 1.35),
                ),
                if (note.isNotEmpty && status == 'Changes Requested') ...[
                  const SizedBox(height: 6),
                  Text(
                    'Elder note: $note',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
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
