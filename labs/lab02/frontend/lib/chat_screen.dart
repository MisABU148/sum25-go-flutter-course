import 'package:flutter/material.dart';
import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatService chatService;
  const ChatScreen({super.key, required this.chatService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late Future<void> _connectFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connectFuture = _connect();
  }

  Future<void> _connect() async {
    try {
      await widget.chatService.connect();
      setState(() {
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Connection error: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      await widget.chatService.sendMessage(text);
      _controller.clear();
      setState(() {}); // Update UI after clearing input
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _connectFuture,
      builder: (context, snapshot) {
        if (_error != null) {
          // Show error state if connection failed
          return Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          // Show loading spinner while connecting
          return const Center(child: CircularProgressIndicator());
        }

        // Connected - show chat UI with message list and input
        return Column(
          children: [
            Expanded(
              child: StreamBuilder<String>(
                stream: widget.chatService.messageStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Stream error: ${snapshot.error}',
                        style:
                            const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    // Show placeholder if no messages yet
                    return const Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return _MessagesList();
                },
              ),
            ),
            _MessageInput(
              controller: _controller,
              onSend: _sendMessage,
            ),
          ],
        );
      },
    );
  }
}

// Helper widget to manage and display message list inside StreamBuilder
class _MessagesList extends StatefulWidget {
  @override
  State<_MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<_MessagesList> {
  final List<String> _messages = [];

  @override
  void didChangeDependencies() {
    super.didCh
