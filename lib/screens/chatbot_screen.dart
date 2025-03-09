import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:halalapp/config/app_config.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessage {
  final String text;
  final bool isQuestion;

  ChatMessage({required this.text, required this.isQuestion});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final question = _messageController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: question, isQuestion: true));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final model = GenerativeModel(
        model: AppConfig.geminiVersion,
        apiKey: AppConfig.geminiApiKey,
      );

      final prompt = '''
You are an AI assistant specialized in Islamic knowledge. Please provide accurate information about Islam based on the following question. 
If the question is not related to Islam, kindly inform that you can only answer questions about Islam.
Please format your response using markdown for better readability.

Question: $question
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      final responseText = response.text;
      if (responseText == null || responseText.isEmpty) {
        throw Exception('Received empty response from AI');
      }
      
      setState(() {
        _messages.add(ChatMessage(text: responseText, isQuestion: false));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Sorry, I encountered an error while processing your question. Please try again.',
          isQuestion: false,
        ));
        _isLoading = false;
      });
      debugPrint('Error in chatbot: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Card(
      margin: EdgeInsets.only(
        left: message.isQuestion ? 32 : 8,
        right: message.isQuestion ? 8 : 32,
        bottom: 8,
      ),
      color: message.isQuestion 
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: message.isQuestion 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.green,
                  child: Icon(
                    message.isQuestion ? Icons.person : Icons.assistant,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  message.isQuestion ? 'You' : 'Islamic Assistant',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            message.isQuestion
                ? Text(message.text)
                : MarkdownBody(
                    data: message.text,
                    selectable: true,
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                ..._messages.map(_buildMessageBubble),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask a question about Islam...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 