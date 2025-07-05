import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiService>(context, listen: false);
    _loadMessages();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await _apiService.getMessages();
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final username = _usernameController.text.trim();
    final content = _messageController.text.trim();
    if (username.isEmpty || content.isEmpty) return;

    final request = CreateMessageRequest(username: username, content: content);
    try {
      final message = await _apiService.createMessage(request);
      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _editMessage(Message message) async {
    final controller = TextEditingController(text: message.content);
    final newContent = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (newContent != null && newContent.isNotEmpty) {
      try {
        final updated = await _apiService.updateMessage(message.id, UpdateMessageRequest(content: newContent));
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) _messages[index] = updated;
        });
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteMessage(message.id);
        setState(() => _messages.removeWhere((m) => m.id == message.id));
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
  }

  Future<void> _showHTTPStatus(int statusCode) async {
    try {
      final response = await _apiService.getHTTPStatus(statusCode);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${response.statusCode} - ${response.description}'),
          content: Image.network('https://http.cat/${response.statusCode}', errorBuilder: (_, __, ___) => const Icon(Icons.error)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  Widget _buildMessageTile(Message message) {
    return ListTile(
      leading: CircleAvatar(child: Text(message.username[0].toUpperCase())),
      title: Text('${message.username} • ${message.timestamp}'),
      subtitle: Text(message.content),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') _editMessage(message);
          if (value == 'delete') _deleteMessage(message);
        },
        itemBuilder: (ctx) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: () => _showHTTPStatus([200, 404, 500][Random().nextInt(3)]),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [200, 404, 500].map((code) => ElevatedButton(
              onPressed: () => _showHTTPStatus(code),
              child: Text('$code'),
            )).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 8),
          Text(_error ?? 'Unknown error', style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _loadMessages, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API Chat'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMessages)],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) => _buildMessageTile(_messages[i]),
                ),
      bottomSheet: _buildMessageInput(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMessages,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class HTTPStatusDemo {
  static void showRandomStatus(BuildContext context, ApiService apiService) {
    final statusCodes = [200, 201, 400, 404, 418, 500];
    final code = statusCodes[Random().nextInt(statusCodes.length)];
    _ChatScreenState()._showHTTPStatus(code); // workaround, ideally restructure
  }

  static void showStatusPicker(BuildContext context, ApiService apiService) {
    final codes = [100, 200, 201, 400, 401, 403, 404, 418, 500, 503];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Choose HTTP Status'),
        children: codes
            .map((code) => SimpleDialogOption(
                  child: Text('$code'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _ChatScreenState()._showHTTPStatus(code); // workaround
                  },
                ))
            .toList(),
      ),
    );
  }
}