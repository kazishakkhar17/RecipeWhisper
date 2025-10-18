import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/ai_suggestion_provider.dart';
import '../../../recipes/domain/entities/recipe.dart';
import '../../../recipes/presentation/screens/recipe_detail_screen.dart';

class AiSuggestionScreen extends ConsumerStatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  ConsumerState<AiSuggestionScreen> createState() =>
      _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends ConsumerState<AiSuggestionScreen> {
  bool _showChatInterface = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  /// Map from chat message index -> parsed Recipe (so we can display a preview card under that AI message)
  final Map<int, Recipe> _messageRecipes = {};

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startConversation(String prompt) {
    setState(() {
      _showChatInterface = true;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      _messageController.text = prompt;
      _sendMessage();
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    // send message to provider (which will update messages & persist recipe if present)
    final recipe =
        await ref.read(aiChatProvider.notifier).sendMessage(message);

    if (recipe != null) {
      // Find the last AI message index (we'll attach the preview to it)
      final messages = ref.read(aiChatProvider).messages;
      int foundIndex = -1;
      for (int i = messages.length - 1; i >= 0; i--) {
        if (!messages[i].isUser) {
          foundIndex = i;
          break;
        }
      }
      if (foundIndex != -1) {
        setState(() {
          _messageRecipes[foundIndex] = recipe;
        });
      }
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _showChatInterface
            ? _buildChatInterface(chatState)
            : _buildSuggestionsInterface(),
      ),
    );
  }

  // Suggestions UI
  Widget _buildSuggestionsInterface() {
    return Container(
      key: const ValueKey('suggestions'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('✨', style: TextStyle(fontSize: 45)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('ai_suggestions'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('personalized_recommendations'),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSuggestionCard(
                    icon: '🍳',
                    title: context.tr('create_new_recipe'),
                    description: context.tr('create_new_recipe_desc'),
                    onTap: () => _startConversation('I want to add a recipe'),
                  ),
                  const SizedBox(height: 15),
                  _buildSuggestionCard(
                    icon: '🥑',
                    title: context.tr('low_carb_dinner'),
                    description: context.tr('low_carb_dinner_desc'),
                    onTap: () => _startConversation('Suggest low-carb dinner ideas'),
                  ),
                  const SizedBox(height: 15),
                  _buildSuggestionCard(
                    icon: '🍞',
                    title: context.tr('quick_breakfast'),
                    description: context.tr('quick_breakfast_desc'),
                    onTap: () => _startConversation('Give me quick breakfast ideas'),
                  ),
                  const SizedBox(height: 15),
                  _buildSuggestionCard(
                    icon: '📦',
                    title: context.tr('meal_prep'),
                    description: context.tr('meal_prep_desc'),
                    onTap: () => _startConversation('Help me plan meal prep'),
                  ),
                  const SizedBox(height: 15),
                  _buildSuggestionCard(
                    icon: '🌮',
                    title: context.tr('mexican_cuisine'),
                    description: context.tr('mexican_cuisine_desc'),
                    onTap: () => _startConversation('Suggest Mexican recipes'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Start chatting button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showChatInterface = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFFF6B6B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('start_chatting'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard({
    required String icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Color(0xFFCBD5E0)),
          ],
        ),
      ),
    );
  }

  // Chat Interface
  Widget _buildChatInterface(AiChatState chatState) {
    return Scaffold(
      key: const ValueKey('chat'),
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🤖 '),
            Text(context.tr('ai_assistant')),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _showChatInterface = false;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearChat();
              setState(() {
                _messageRecipes.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('chat_cleared')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            tooltip: context.tr('clear_chat'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('ℹ️ ${context.tr('how_to_use')}'),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('1. Ensure you have an active internet connection'),
                        SizedBox(height: 8),
                        Text('2. Your Groq API key must be set in the .env file'),
                        SizedBox(height: 8),
                        Text('3. Ask the AI about dishes or meal ideas—it will create full recipes'),
                        SizedBox(height: 8),
                        Text('4. Recipes are automatically saved to your collection.'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(context.tr('got_it')),
                    ),
                  ],
                ),
              );
            },
            tooltip: context.tr('help'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🤖', style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        Text(context.tr('start_chatting'),
                            style: TextStyle(
                                fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      final recipe = _messageRecipes[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ChatBubble(message: message),
                          if (recipe != null)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 12),
                              child: _RecipePreviewCard(recipe: recipe),
                            ),
                        ],
                      );
                    },
                  ),
          ),

          // Loading
          if (chatState.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[800]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '🤔 ${context.tr('ai_thinking')}',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),

          // Error
          if (chatState.error != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(chatState.error!,
                          style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),

          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr('type_message'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[50],
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !chatState.isLoading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: chatState.isLoading
                          ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[400]!])
                          : const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: chatState.isLoading ? null : _sendMessage,
                    ),
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

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)])
              : null,
          color: isUser 
              ? null 
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
        ),
        child: Text(message.text,
            style: TextStyle(
                color: isUser 
                    ? Colors.white 
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: 15,
                height: 1.4)),
      ),
    );
  }
}

class _RecipePreviewCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipePreviewCard({required this.recipe});

  String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('breakfast')) return '🍳';
    if (lower.contains('lunch')) return '🍱';
    if (lower.contains('dinner')) return '🍽️';
    if (lower.contains('dessert')) return '🍰';
    return '🍲';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient:
                    LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)]),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15)),
              ),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(recipe.category),
                      style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.name,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            maxLines: 2),
                        const SizedBox(height: 4),
                        Text(recipe.category,
                            style:
                                const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(recipe.description,
                      style:
                          const TextStyle(fontSize: 14, color: Color(0xFF718096)),
                      maxLines: 2),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoChip(
                          icon: Icons.timer_outlined,
                          label: '${recipe.cookingTimeMinutes} ${context.tr('minutes')}'),
                      const SizedBox(width: 12),
                      _InfoChip(
                          icon: Icons.local_fire_department,
                          label: '${recipe.calories} ${context.tr('calories')}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(context.tr('recipe_saved_tap'),
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFF6B6B)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}