import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/ai_coach_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/widgets/glass_card.dart';

class AICoachScreen extends ConsumerStatefulWidget {
  const AICoachScreen({super.key});

  @override
  ConsumerState<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends ConsumerState<AICoachScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isThinking = false;

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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiCoachProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger auto scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Chat header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppColors.secondary, AppColors.info]),
                      boxShadow: [
                        BoxShadow(color: AppColors.secondary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text("🤖", style: TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI COACH CORE",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          const Text("Online & Analyzing App Data", style: TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderDark),

            // Messages chat list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: messages.length + (_isThinking ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && _isThinking) {
                    return _buildThinkingTile(context);
                  }
                  
                  final msg = messages[index];
                  final isCoach = msg.sender == 'coach';
                  
                  return _buildMessageTile(context, msg, isCoach);
                },
              ),
            ),

            // Suggestions quick tags
            if (messages.length <= 2) _buildSuggestionsRow(context),

            // Input panel
            _buildInputPanel(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(BuildContext context, ChatMessage msg, bool isCoach) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isCoach ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCoach) ...[
            const CircleAvatar(
              backgroundColor: AppColors.cardDark,
              child: Text("🤖", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: isCoach
                  ? AppColors.secondary.withOpacity(isDark ? 0.12 : 0.08)
                  : AppColors.primary.withOpacity(isDark ? 0.12 : 0.08),
              borderColor: isCoach
                  ? AppColors.secondary.withOpacity(0.4)
                  : AppColors.primary.withOpacity(0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                      style: const TextStyle(fontSize: 9, color: AppColors.textSecondaryDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (!isCoach) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: AppColors.cardDark,
              child: Icon(Icons.person, color: AppColors.primary, size: 20),
            ),
          ]
        ],
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildThinkingTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.cardDark,
            child: Text("🤖", style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 8),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.secondary),
                ),
                const SizedBox(width: 10),
                Text("Analyzing app data...", style: TextStyle(fontSize: 12, color: AppColors.secondary.withOpacity(0.8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow(BuildContext context) {
    final list = [
      "What should I eat?",
      "Why is my weight stuck?",
      "How much protein did I consume today?",
      "How many workouts did I miss this month?"
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final text = list[index];
          return GestureDetector(
            onTap: () {
              _textController.text = text;
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              alignment: Alignment.center,
              child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputPanel(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: const Border(top: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ask AI Coach...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                filled: true,
                fillColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: _isThinking ? null : () => _handleSend(),
          ),
        ],
      ),
    );
  }

  void _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    
    setState(() {
      _isThinking = true;
    });

    _scrollToBottom();
    
    // Call notifier to send message
    await ref.read(aiCoachProvider.notifier).sendMessage(text);

    if (mounted) {
      setState(() {
        _isThinking = false;
      });
      _scrollToBottom();
    }
  }
}
