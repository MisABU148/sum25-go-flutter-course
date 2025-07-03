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

                  // We will accumulate messages in a list for display
                  // However, StreamBuilder only has latest event,
                  // so to keep messages we must manage a local list.
                  // But the test expects message text to appear,
                  // so we'll keep it simple: show all messages received so far.

                  // Use a ListView builder fed by snapshot.data in a simple way:
                  // Actually, since we have only one latest message, let's accumulate
                  // messages in a List<String> in state.

                  // We'll fix this by using a List<String> _messages in state.

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
    super.didChangeDependencies();
    // Listen to message stream from nearest ChatScreen widget
    final chatService = (context.findAncestorWidgetOfExactType<ChatScreen>())!
        .chatService;
    chatService.messageStream.listen((msg) {
      setState(() {
        _messages.add(msg);
      });
    }, onError: (e) {
      // ignore errors here for simplicity
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_messages[index]),
        );
      },
    );
  }
}

// Widget for message input and send button
class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageInput({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter message',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
