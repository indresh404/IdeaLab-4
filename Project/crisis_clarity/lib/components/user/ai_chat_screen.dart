import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:crisis_clarity/theme/app_theme.dart';
import 'package:crisis_clarity/components/user/post.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crisis_clarity/features/alerts/providers/alert_provider.dart';
import 'package:crisis_clarity/core/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AI Avatar Lottie Widget - Controls animation behavior
// ─────────────────────────────────────────────────────────────────────────────
class AIAvatarLottie extends StatefulWidget {
  final bool isLatestChat;
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
              _controller.repeat();
            } else {
              _controller.value = 1.0;
            }
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AIChatScreen
// ─────────────────────────────────────────────────────────────────────────────
class AIChatScreen extends ConsumerStatefulWidget {
  final Post? post;
  const AIChatScreen({super.key, this.post});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _inputEnabled = true;
  final FocusNode _focusNode = FocusNode();

  // Voice Features
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = "";

  late final AnimationController _headerCtrl;

  static const _suggestions = [
    _QSuggestion('📊 Analyze Situation',   'Generate a concise situational summary and safety advice for this event.'),
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

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToBottom();
        });
      }
    });

    _initTts();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: widget.post != null
              ? 'Hi! I\'m your Crisis AI Assistant 👋\n\nI see you\'re interested in **${widget.post!.title}**.\n\nWould you like me to analyze the situation and provide safety advice?'
              : 'Hi! I\'m your Crisis AI Assistant 👋\n\nI\'m here to help you stay safe. Ask me about alerts, shelters, emergency contacts, or evacuation routes.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _initTts() {
    _tts.setStartHandler(() => setState(() => _isSpeaking = true));
    _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _tts.setErrorHandler((msg) => setState(() => _isSpeaking = false));
  }

  Future<void> _speak(String text, {String lang = 'English'}) async {
    if (text.isEmpty) return;
    // Set TTS language based on AI response
    if (lang == 'Hindi') {
      await _tts.setLanguage('hi-IN');
    } else if (lang == 'Marathi') {
      await _tts.setLanguage('mr-IN');
    } else {
      await _tts.setLanguage('en-US');
    }
    await _tts.speak(text.replaceAll('**', '')); // Strip markdown
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _triggerSummary() async {
    setState(() => _isTyping = true);
    
    try {
      final contextText = widget.post != null 
          ? "The user is viewing an alert about ${widget.post!.title} in ${widget.post!.location}. Content: ${widget.post!.content}"
          : null;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': 'Generate a concise situational summary and safety advice for this event.',
          'context': contextText,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['response'];
        final responseLang = data['language'] ?? 'English';

        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(_ChatMessage(
            text: summary,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _speak(summary, lang: responseLang);
      } else {
        throw Exception('Failed to get AI summary');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          text: '❌ Crisis AI is still warming up. This can take a minute on first load. Please try sending a message in a few seconds.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      // Try again once after 10 seconds if it's the first failure
      if (widget.post != null && _messages.length <= 2) {
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _messages.last.text.contains('warming up')) {
            _triggerSummary();
          }
        });
      }
    }
    _scrollToBottom();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350), 
          curve: Curves.easeOut
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) => setState(() => _isListening = false),
    );

    if (available) {
      HapticFeedback.mediumImpact();
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
            _inputCtrl.text = _lastWords;
          });
          if (result.finalResult) {
            _sendMessage(_lastWords);
          }
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_inputEnabled) return;
    
    final userMessage = text.trim();
    HapticFeedback.lightImpact();
    
    setState(() {
      _messages.add(_ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
      _inputEnabled = false;
      _isListening = false;
    });
    
    _inputCtrl.clear();
    _scrollToBottom();
    _stopSpeaking();

    try {
      final contextText = widget.post != null 
          ? "The user is viewing an alert about ${widget.post!.title} in ${widget.post!.location}. Content: ${widget.post!.content}"
          : null;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': userMessage,
          'context': contextText,
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['response'];
        final responseLang = data['language'] ?? 'English';

        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _inputEnabled = true;
          _messages.add(_ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _speak(aiResponse, lang: responseLang);
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _inputEnabled = true;
        _messages.add(_ChatMessage(
          text: '⚠️ Crisis AI is currently unresponsive. Please check if the backend is running or try again in a moment.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Scaffold(
      backgroundColor: const Color(0xFF09090F),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          _focusNode.unfocus();
        },
        child: Stack(
          children: [
            Positioned(
              top: -80, 
              right: -80,
              child: _GlowOrb(color: color, size: 340, opacity: 0.16)
            ),
            Positioned(
              bottom: 140, 
              left: -60,
              child: _GlowOrb(color: color, size: 260, opacity: 0.10)
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(color),
                  if (widget.post != null) _buildSeverityBanner(color),
                  Expanded(
                    child: _messages.isEmpty
                        ? _buildEmptyState(color)
                        : _buildMsgList(color),
                  ),
                  if (!_isTyping && _messages.length <= 1)
                    _buildSuggestions(color),
                  _buildInput(color),
                ],
              ),
            ),
            if (_isListening) _buildListeningOverlay(color),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningOverlay(Color color) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset('assets/animations/ai_loading.json', width: 220),
            const SizedBox(height: 30),
            const Text('Listening...', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(_lastWords, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 18)),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: _stopListening,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
                child: const Icon(Icons.close, color: Colors.white, size: 36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
          .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white60, size: 19),
              onPressed: () => Navigator.pop(context),
            ),
            AIAvatarLottie(
              isLatestChat: true,
              size: 46,
              borderColor: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  const Text('Crisis AI',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                          color: Colors.white, letterSpacing: -0.3)),
                  Row(
                    children: [
                      Container(
                        width: 7, 
                        height: 7,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle, color: Color(0xFF4CAF50)
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text('Online · Ready to help',
                          style: TextStyle(fontSize: 11.5, color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_off, color: color),
              onPressed: () => _isSpeaking ? _stopSpeaking() : null,
            ),
          ],
        ),
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
      child: Row(
        children: [
          Icon(Icons.crisis_alert, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.length > 55 ? '${title.substring(0, 55)}…' : title,
              style: TextStyle(
                fontSize: 12, 
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w600
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color color) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        AIAvatarLottie(
          isLatestChat: true,
          size: 130,
          borderColor: color,
        ),
        const SizedBox(height: 14),
        Text(
          'Initializing AI…',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14, 
            fontWeight: FontWeight.w500
          ),
        ),
      ],
    ),
  );

  Widget _buildMsgList(Color color) => ListView.builder(
    controller: _scrollCtrl,
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    itemCount: _messages.length + (_isTyping ? 1 : 0),
    itemBuilder: (_, i) {
      if (_isTyping && i == _messages.length) {
        return _TypingIndicator(color: color);
      }
      return _MessageBubble(
        message: _messages[i],
        color: color,
        isLatestMessage: i == _messages.length - 1 && _messages[i].isUser == false,
      );
    },
  );

  Widget _buildSuggestions(Color color) => Container(
    height: 44,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () {
          if (_suggestions[i].label.contains('Analyze Situation')) {
            _triggerSummary();
          } else {
            _sendMessage(_suggestions[i].query);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Text(
            _suggestions[i].label,
            style: TextStyle(
              fontSize: 12.5, 
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildInput(Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF09090F),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: color, size: 26),
            onPressed: _toggleListening,
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 48, 
                maxHeight: 100,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                enabled: _inputEnabled,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 5,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Ask about this crisis…',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.28), 
                    fontSize: 14
                  ),
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
              width: 48, 
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                  begin: Alignment.topLeft, 
                  end: Alignment.bottomRight
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4), 
                    blurRadius: 14,
                    offset: const Offset(0, 4)
                  )
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color; 
  final double size, opacity;
  const _GlowOrb({required this.color, required this.size, required this.opacity});
  
  @override
  Widget build(BuildContext context) => Container(
    width: size, 
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withOpacity(opacity), Colors.transparent]
      ),
    ),
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
  late final AnimationController _c = AnimationController(
    vsync: this, 
    duration: const Duration(milliseconds: 350)
  )..forward();
  
  late final Animation<double> _scale = Tween(begin: 0.86, end: 1.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOutBack)
  );
  
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c, 
    curve: Curves.easeOut
  );

  @override 
  void dispose() { 
    _c.dispose(); 
    super.dispose(); 
  }

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
                AIAvatarLottie(
                  isLatestChat: widget.isLatestMessage,
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
                      begin: Alignment.topLeft, 
                      end: Alignment.bottomRight
                    ) : null,
                    color: isUser ? null : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                    boxShadow: isUser ? [
                      BoxShadow(
                        color: color.withOpacity(0.28),
                        blurRadius: 12, 
                        offset: const Offset(0, 4)
                      )
                    ] : null,
                  ),
                  child: _richText(widget.message.text, isUser),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32, 
                  height: 32,
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
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1), 
          style: const TextStyle(fontWeight: FontWeight.w700)
        )
      );
      last = m.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13.5, 
          height: 1.55,
          color: isUser ? Colors.white : Colors.white.withOpacity(0.88)
        ),
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end, 
      children: [
        AIAvatarLottie(
          isLatestChat: true,
          size: 32,
          borderColor: color,
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), 
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), 
              bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: const SizedBox(
            width: 60,
            height: 20,
            child: Center(
              child: Text(
                '...', 
                style: TextStyle(color: Colors.white60, fontSize: 18)
              ),
            ),
          ),
        ),
      ],
    ),
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