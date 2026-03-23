import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:crisis_clarity/components/user/post.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI Avatar Lottie Widget - Controls animation behavior
// ─────────────────────────────────────────────────────────────────────────────
class AIAvatarLottie extends StatefulWidget {
  final bool isLatestChat;   // true = infinite loop, false = freeze last frame
  final double size;
  final Color borderColor;

  const AIAvatarLottie({
    super.key,
    required this.isLatestChat,
    this.size = 60,
    this.borderColor = Colors.white,
  });

  @override
  State<AIAvatarLottie> createState() => _AIAvatarLottieState();
}

class _AIAvatarLottieState extends State<AIAvatarLottie>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(AIAvatarLottie oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation behavior when isLatestChat changes
    if (widget.isLatestChat != oldWidget.isLatestChat) {
      if (widget.isLatestChat) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            widget.borderColor.withOpacity(0.4),
            widget.borderColor.withOpacity(0.12)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
            color: widget.borderColor.withOpacity(0.3),
            width: 1.5
        ),
      ),
      child: ClipOval(
        child: Lottie.asset(
          'assets/animations/ai_loading.json',
          controller: _controller,
          fit: BoxFit.cover,
          onLoaded: (composition) {
            _controller.duration = composition.duration;

            if (widget.isLatestChat) {
              _controller.repeat(); // Latest reply loops forever
            } else {
              _controller.value = 1.0; // Freeze on last frame for older messages
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AIChatScreen
// • [post] is optional — FAB on UserPage opens it without a specific post
// • When a post is provided, the chat is contextualised to that alert
// ─────────────────────────────────────────────────────────────────────────────
class AIChatScreen extends StatefulWidget {
  final Post? post;
  const AIChatScreen({super.key, this.post});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _inputEnabled = true;

  late final AnimationController _headerCtrl;

  static const _suggestions = [
    _QSuggestion('🏠 Nearest Shelters',   'Where are the nearest emergency shelters?'),
    _QSuggestion('🆘 Safety Tips',        'What safety precautions should I take?'),
    _QSuggestion('📞 Emergency Contacts', 'What emergency numbers should I call?'),
    _QSuggestion('🚗 Evacuation Routes',  'What are the safest evacuation routes?'),
  ];

  Color get _color => widget.post?.severity.color ?? AppTheme.primaryRed;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: widget.post != null
              ? 'Hi! I\'m your Crisis AI. I\'m here to help you navigate **${widget.post!.title}**.\n\nWhat would you like to know?'
              : 'Hi! I\'m your Crisis AI Assistant 👋\n\nI\'m here to help you stay safe. Ask me about alerts, shelters, emergency contacts, or evacuation routes.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_inputEnabled) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
      _inputEnabled = false;
    });
    _inputCtrl.clear();
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    setState(() {
      _isTyping = false;
      _inputEnabled = true;
      _messages.add(_ChatMessage(text: _respond(text), isUser: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  String _respond(String q) {
    final ql = q.toLowerCase();
    if (ql.contains('shelter') || ql.contains('safe place')) {
      return '🏢 **Nearest Emergency Shelters:**\n\n• Chembur Gymkhana — 2.3 km\n• Municipal School, Kurla — 1.8 km\n• Community Hall, Dharavi — 3.1 km\n\nAll have medical aid, food, water & backup power. Bring ID if available.';
    } else if (ql.contains('contact') || ql.contains('number') || ql.contains('call')) {
      return '📞 **Emergency Contacts:**\n\n🚨 National Emergency — **112**\n🚒 Fire Brigade — **101**\n🏥 Ambulance — **108**\n👮 Police — **100**\n🌊 NDRF — 011-24363260\n🏙️ BMC — **1916**';
    } else if (ql.contains('evacuat') || ql.contains('route') || ql.contains('leave')) {
      return '🚗 **Evacuation Routes:**\n\nFrom Chembur:\n• Western Express Hwy via Sion — OPEN ✅\n• Eastern Freeway — CLOSED ❌\n\nFrom Kurla:\n• LBS Marg towards Thane — SLOW ⚠️\n\nAvoid underpasses. Follow police direction.';
    } else if (ql.contains('safe') || ql.contains('tip') || ql.contains('precaution')) {
      final label = widget.post?.severity.label ?? 'Current';
      return '🛡️ **Safety Tips — $label Alert:**\n\n1. Stay indoors & away from windows\n2. Keep emergency kit ready\n3. Charge all devices now\n4. Store drinking water\n5. Monitor official channels only\n6. Help elderly neighbours if safe\n7. Do NOT spread unverified news';
    }
    return 'Based on the current crisis, I recommend following official NDRF/BMC advisories. For immediate help, call **112**.\n\nIs there something specific you need help with?';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF09090F),
      resizeToAvoidBottomInset: true,
      body: Stack(children: [
        // Ambient glows
        Positioned(top: -80, right: -80,
            child: _GlowOrb(color: color, size: 340, opacity: 0.16)),
        Positioned(bottom: 140, left: -60,
            child: _GlowOrb(color: color, size: 260, opacity: 0.10)),

        SafeArea(
          child: Column(children: [
            _buildHeader(color),
            if (widget.post != null) _buildSeverityBanner(color),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState(color)
                  : _buildMsgList(color),
            ),
            if (!_isTyping && _messages.length <= 1) _buildSuggestions(color),
            _buildInput(color, bottomInset),
          ]),
        ),
      ]),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(Color color) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
          .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 19),
            onPressed: () => Navigator.pop(context),
          ),
          // Header AI Avatar - Always loops
          AIAvatarLottie(
            isLatestChat: true,
            size: 46,
            borderColor: color,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Crisis AI',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: Colors.white, letterSpacing: -0.3)),
            Row(children: [
              Container(width: 7, height: 7,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF4CAF50))),
              const SizedBox(width: 5),
              const Text('Online · Ready to help',
                  style: TextStyle(fontSize: 11.5, color: Colors.white54)),
            ]),
          ])),
          if (widget.post != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_amber_rounded, size: 11, color: color),
                const SizedBox(width: 4),
                Text(widget.post!.severity.label.toUpperCase(),
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800,
                        color: color, letterSpacing: 0.5)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _buildSeverityBanner(Color color) {
    final title = widget.post!.title;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(Icons.crisis_alert, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(
          title.length > 55 ? '${title.substring(0, 55)}…' : title,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600),
        )),
      ]),
    );
  }

  Widget _buildEmptyState(Color color) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Empty state AI Avatar - Always loops
      AIAvatarLottie(
        isLatestChat: true,
        size: 130,
        borderColor: color,
      ),
      const SizedBox(height: 14),
      Text('Initializing AI…',
          style: TextStyle(color: Colors.white.withOpacity(0.4),
              fontSize: 14, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _buildMsgList(Color color) => ListView.builder(
    controller: _scrollCtrl,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    itemCount: _messages.length + (_isTyping ? 1 : 0),
    itemBuilder: (_, i) {
      if (_isTyping && i == _messages.length) return _TypingIndicator(color: color);
      return _MessageBubble(
        message: _messages[i],
        color: color,
        isLatestMessage: i == _messages.length - 1 && _messages[i].isUser == false,
      );
    },
  );

  Widget _buildSuggestions(Color color) => SizedBox(
    height: 44,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _sendMessage(_suggestions[i].query),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Text(_suggestions[i].label,
              style: TextStyle(fontSize: 12.5, color: color.withOpacity(0.9),
                  fontWeight: FontWeight.w600)),
        ),
      ),
    ),
  );

  Widget _buildInput(Color color, double bottomInset) => AnimatedPadding(
    duration: const Duration(milliseconds: 200),
    padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, maxHeight: 120),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: TextField(
              controller: _inputCtrl,
              enabled: _inputEnabled,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'Ask about this crisis…',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () => _sendMessage(_inputCtrl.text),
          child: Container(
            width: 48, height: 48,
            margin: const EdgeInsets.only(bottom: 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 14,
                  offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _GlowOrb extends StatelessWidget {
  final Color color; final double size, opacity;
  const _GlowOrb({required this.color, required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(
            colors: [color.withOpacity(opacity), Colors.transparent])),
  );
}

class _MessageBubble extends StatefulWidget {
  final _ChatMessage message;
  final Color color;
  final bool isLatestMessage;

  const _MessageBubble({
    required this.message,
    required this.color,
    required this.isLatestMessage,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 350))..forward();
  late final Animation<double> _scale =
  Tween(begin: 0.86, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
  late final Animation<double> _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final color = widget.color;
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                // AI Avatar in message bubble
                // Latest AI message loops forever, older ones freeze
                AIAvatarLottie(
                  isLatestChat: widget.isLatestMessage, // Only latest message loops
                  size: 32,
                  borderColor: color,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser ? LinearGradient(
                        colors: [color, color.withOpacity(0.75)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                    color: isUser ? null : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: isUser ? [BoxShadow(color: color.withOpacity(0.28),
                        blurRadius: 12, offset: const Offset(0, 4))] : null,
                  ),
                  child: _richText(widget.message.text, isUser),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.person_rounded, color: Colors.white60, size: 17),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _richText(String text, bool isUser) {
    final spans = <TextSpan>[];
    final re = RegExp(r'\*\*(.*?)\*\*');
    int last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13.5, height: 1.55,
            color: isUser ? Colors.white : Colors.white.withOpacity(0.88)),
        children: spans,
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      // Typing indicator AI Avatar - Always loops
      AIAvatarLottie(
        isLatestChat: true, // During typing, show infinite animation
        size: 32,
        borderColor: color,
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const SizedBox(
          width: 60,
          height: 20,
          child: Center(
            child: Text('...', style: TextStyle(color: Colors.white60, fontSize: 18)),
          ),
        ),
      ),
    ]),
  );
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class _QSuggestion {
  final String label, query;
  const _QSuggestion(this.label, this.query);
}