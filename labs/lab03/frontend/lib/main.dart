import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/chat_screen.dart';
import 'services/api_service.dart';
import 'models/message.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<ChatProvider>(
          create: (context) => ChatProvider(context.read<ApiService>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lab 03 REST API Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(secondary: Colors.orange),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;

  ChatProvider(this._apiService);

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMessages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedMessages = await _apiService.getMessages();
      _messages = fetchedMessages;
    } catch (e) {
      _error = 'Failed to load messages';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMessage(CreateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return;
    }

    try {
      final newMessage = await _apiService.createMessage(request);
      _messages.add(newMessage);
      _error = null;
    } catch (e) {
      _error = 'Failed to create message';
    }
    notifyListeners();
  }

  Future<void> updateMessage(int id, UpdateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      _error = validationError;
      notifyListeners();
      return;
    }

    try {
      final updatedMessage = await _apiService.updateMessage(id, request);
      final index = _messages.indexWhere((m) => m.id == id);
      if (index != -1) {
        _messages[index] = updatedMessage;
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to update message';
    }
    notifyListeners();
  }

  Future<void> deleteMessage(int id) async {
    try {
      await _apiService.deleteMessage(id);
      _messages.removeWhere((m) => m.id == id);
      _error = null;
    } catch (e) {
      _error = 'Failed to delete message';
    }
    notifyListeners();
  }

  Future<void> refreshMessages() async {
    _messages.clear();
    await loadMessages();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
