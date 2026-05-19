import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../models/outfit_analysis.dart';
import '../services/gemini_service.dart';

class StyleChatScreen extends StatefulWidget {
  final File image;
  final OutfitAnalysis analysis;

  const StyleChatScreen({
    super.key,
    required this.image,
    required this.analysis,
  });

  @override
  State<StyleChatScreen> createState() => _StyleChatScreenState();
}

class _StyleChatScreenState extends State<StyleChatScreen>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _thinking = false;
  late AnimationController _dotCtrl;

  // Build the initial system context from the analysis
  String get _systemContext =>
      '''
You are StyleAI, an expert fashion stylist. You already analyzed this outfit:

Style Persona: ${widget.analysis.stylePersona}
Overall Style: ${widget.analysis.overallStyle}
Color Palette: ${widget.analysis.colorPalette}
Best For: ${widget.analysis.occasion}
Fit Assessment: ${widget.analysis.fitAssessment}
Style Score: ${widget.analysis.styleScore}/100
Strengths: ${widget.analysis.strengths.join(', ')}
Improvements: ${widget.analysis.improvements.join(', ')}
Accessory Ideas: ${widget.analysis.accessorySuggestions.join(', ')}
Seasonal Advice: ${widget.analysis.seasonalAdvice}

Answer the user's follow-up questions about this outfit. Be specific, helpful, 
conversational and concise. Keep responses under 3 sentences unless detail is needed.
''';

  // Build full conversation history for multi-turn
  List<Map<String, dynamic>> get _conversationHistory {
    final history = <Map<String, dynamic>>[];
    // Seed with context as first user message
    history.add({
      'role': 'user',
      'parts': [
        {'text': _systemContext},
      ],
    });
    history.add({
      'role': 'model',
      'parts': [
        {
          'text':
              'Got it! I\'ve reviewed your outfit analysis. What would you like to know?',
        },
      ],
    });
    // Add actual conversation
    for (final msg in _messages) {
      history.add({
        'role': msg.isUser ? 'user' : 'model',
        'parts': [
          {'text': msg.text},
        ],
      });
    }
    return history;
  }

  final _suggestions = [
    'How can I style this for winter?',
    'What shoes go with this?',
    'How to dress this up for a date?',
    'What colors should I avoid?',
    'How to make this more casual?',
    'What bag complements this?',
  ];

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Initial greeting
    _messages.add(
      _ChatMessage(
        text:
            'Hi! I\'ve analyzed your outfit. Ask me anything about it — '
            'how to style it differently, what to add, or how to adapt it for any occasion.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _thinking) return;
    HapticFeedback.lightImpact();

    final userMsg = text.trim();
    _textCtrl.clear();

    setState(() {
      _messages.add(_ChatMessage(text: userMsg, isUser: true));
      _thinking = true;
    });

    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GeminiService.apiKey}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': _conversationHistory,
              'generationConfig': {
                'temperature': 0.8,
                'maxOutputTokens': 400,
                'thinkingConfig': {'thinkingBudget': 0},
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String? ??
            'Sorry, I couldn\'t generate a response. Try again.';

        if (mounted) {
          setState(() {
            _messages.add(_ChatMessage(text: reply.trim(), isUser: false));
            _thinking = false;
          });
          _scrollToBottom();
        }
      } else {
        throw Exception('API error ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              text: 'Something went wrong. Please try again.',
              isUser: false,
              isError: true,
            ),
          );
          _thinking = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildOutfitContext(),
            Expanded(child: _buildMessageList()),
            if (_messages.length <= 2) _buildSuggestions(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: AppTheme.inkMid,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Style Chat',
                style: GoogleFonts.outfit(
                  color: AppTheme.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Ask anything about your outfit',
                style: GoogleFonts.outfit(
                  color: AppTheme.inkHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Thinking indicator
          AnimatedBuilder(
            animation: _dotCtrl,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _thinking
                    ? AppTheme.ice.withOpacity(0.08 + _dotCtrl.value * 0.06)
                    : AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _thinking
                      ? AppTheme.ice.withOpacity(0.3)
                      : AppTheme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _thinking
                          ? AppTheme.ice.withOpacity(0.5 + _dotCtrl.value * 0.5)
                          : AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _thinking ? 'Thinking' : 'Ready',
                    style: GoogleFonts.outfit(
                      color: _thinking ? AppTheme.iceDeep : AppTheme.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildOutfitContext() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: AppTheme.bgSecondary,
      child: Row(
        children: [
          // Outfit thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              widget.image,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.analysis.stylePersona,
                  style: GoogleFonts.outfit(
                    color: AppTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Score ${widget.analysis.styleScore}/100 · ${widget.analysis.occasion}',
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkHint,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Score chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.ice.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.ice.withOpacity(0.3)),
            ),
            child: Text(
              '${widget.analysis.styleScore}',
              style: GoogleFonts.outfit(
                color: AppTheme.iceDeep,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      itemCount: _messages.length + (_thinking ? 1 : 0),
      itemBuilder: (_, i) {
        if (_thinking && i == _messages.length) {
          return _buildThinkingBubble();
        }
        return _buildBubble(_messages[i], i);
      },
    );
  }

  Widget _buildBubble(_ChatMessage msg, int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: msg.isUser
                        ? AppTheme.ink
                        : msg.isError
                        ? AppTheme.error.withOpacity(0.08)
                        : AppTheme.bgSecondary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                    ),
                    border: msg.isError
                        ? Border.all(color: AppTheme.error.withOpacity(0.2))
                        : !msg.isUser
                        ? Border.all(color: AppTheme.border)
                        : null,
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.outfit(
                      color: msg.isUser
                          ? Colors.white
                          : msg.isError
                          ? AppTheme.error
                          : AppTheme.inkMid,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, curve: Curves.easeOut),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildThinkingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppTheme.border),
            ),
            child: AnimatedBuilder(
              animation: _dotCtrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final delay = i * 0.33;
                  final val = ((_dotCtrl.value + delay) % 1.0);
                  final scale = 0.6 + val * 0.6;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.inkHint.withOpacity(0.3 + val * 0.6),
                    ),
                    transform: Matrix4.identity()..translate(0.0, -scale + 0.6),
                  );
                }),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: _suggestions.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _send(_suggestions[i]),
          child:
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  _suggestions[i],
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkMid,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: i * 60),
                duration: 300.ms,
              ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppTheme.border),
              ),
              child: TextField(
                controller: _textCtrl,
                onSubmitted: _send,
                style: GoogleFonts.outfit(color: AppTheme.ink, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask about your outfit...',
                  hintStyle: GoogleFonts.outfit(
                    color: AppTheme.inkHint,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _send(_textCtrl.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _thinking ? AppTheme.bgSecondary : AppTheme.ink,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _thinking
                    ? Icons.hourglass_empty_rounded
                    : Icons.arrow_upward_rounded,
                color: _thinking ? AppTheme.inkHint : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}
