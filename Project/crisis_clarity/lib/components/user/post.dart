import 'package:flutter/material.dart';
import 'package:crisis_clarity/theme/app_theme.dart';

enum SeverityLevel {
  red('RED', 'Critical Emergency', AppTheme.primaryRed),
  orange('ORANGE', 'Severe Alert', Colors.orange),
  yellow('YELLOW', 'Moderate Alert', Colors.amber),
  green('GREEN', 'Information', Colors.green);

  final String label;
  final String description;
  final Color color;

  const SeverityLevel(this.label, this.description, this.color);
}

class Post {
  final String id;
  final String username;
  final String userAvatar;
  final String userRole;
  final String location;
  final String timeAgo;
  final SeverityLevel severity;
  final String title;
  final String content;
  final String disasterType;
  final int feedbackCount;
  final bool hasNotification;
  final bool isPinned;
  final int trustScore; // 0-100
  final String trustStatus; // verified, partial, fake
  final String? link;

  Post({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.userRole,
    required this.location,
    required this.timeAgo,
    required this.severity,
    required this.title,
    required this.content,
    this.disasterType = 'general',
    this.feedbackCount = 0,
    this.hasNotification = false,
    this.isPinned = false,
    this.trustScore = 50,
    this.trustStatus = 'partial',
    this.link,
  });
}

class PostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback? onFeedback;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAIChat;
  final VoidCallback? onProfileTap;

  const PostWidget({
    super.key,
    required this.post,
    this.onFeedback,
    this.onNotificationTap,
    this.onAIChat,
    this.onProfileTap,
  });

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _hasGivenFeedback = false;
  int _feedbackCount = 0;
  bool _isNotified = false;
  bool _showFeedbackOptions = false;

  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  @override
  void initState() {
    super.initState();
    _feedbackCount = widget.post.feedbackCount;
    _isNotified = widget.post.hasNotification;

    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _toggleFeedback() {
    setState(() {
      if (!_showFeedbackOptions) {
        _showFeedbackOptions = true;
        _feedbackController.forward();
      } else {
        _showFeedbackOptions = false;
        _feedbackController.reverse();
      }
    });
  }

  void _handleFeedback(bool understood) {
    setState(() {
      _feedbackCount++;
      _hasGivenFeedback = true;
      _showFeedbackOptions = false;
      _feedbackController.reverse();
    });
    widget.onFeedback?.call();

    // Show snackbar based on feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          understood ? 'Thanks for confirming!' : 'We\'ll share more details',
          style: const TextStyle(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: understood ? Colors.green : widget.post.severity.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleNotification() {
    setState(() {
      _isNotified = !_isNotified;
    });
    widget.onNotificationTap?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isNotified ? 'Notifications enabled for this post' : 'Notifications disabled',
          style: const TextStyle(fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: widget.post.severity.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Left Border Highlight and Severity Bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    widget.post.severity.color,
                    widget.post.severity.color.withOpacity(0.4),
                  ],
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with User Info and Notification Button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info
                      Expanded(
                        child: GestureDetector(
                          onTap: widget.onProfileTap,
                          child: Row(
                            children: [
                              // User Avatar with Role Badge
                              Stack(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.post.severity.color.withOpacity(0.3),
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(widget.post.userAvatar),
                                        fit: BoxFit.cover,
                                        onError: (_, __) => const AssetImage(''),
                                      ),
                                      color: Colors.grey[200],
                                    ),
                                    child: widget.post.userAvatar.isEmpty
                                        ? Center(
                                      child: Text(
                                        widget.post.username[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: widget.post.severity.color,
                                        ),
                                      ),
                                    )
                                        : null,
                                  ),
                                  if (widget.post.userRole.isNotEmpty)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: widget.post.severity.color,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          widget.post.userRole == 'Admin'
                                              ? Icons.shield
                                              : Icons.verified,
                                          size: 12,
                                          color: widget.post.severity.color,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // User Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            widget.post.username,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (widget.post.isPinned) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.push_pin,
                                            size: 16,
                                            color: widget.post.severity.color,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 12,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            '${widget.post.location}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          widget.post.timeAgo,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Notify Me Button (Right Top Corner)
                      Container(
                        decoration: BoxDecoration(
                          color: _isNotified
                              ? widget.post.severity.color.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _isNotified
                                ? widget.post.severity.color.withOpacity(0.3)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: IconButton(
                          onPressed: _toggleNotification,
                          icon: Icon(
                            _isNotified
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                            color: _isNotified
                                ? widget.post.severity.color
                                : Colors.grey[600],
                            size: 22,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          tooltip: _isNotified ? 'Notify On' : 'Notify Me',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Severity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.post.severity.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: widget.post.severity.color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: widget.post.severity.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.post.severity.color.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.post.severity.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.post.severity.color,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: widget.post.severity.color.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.post.severity.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.post.severity.color.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Post Title
                  Text(
                    widget.post.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Post Content with See More
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textSpan = TextSpan(
                        text: widget.post.content,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          height: 1.6,
                        ),
                      );

                      final textPainter = TextPainter(
                        text: textSpan,
                        maxLines: _isExpanded ? null : 3,
                        textDirection: TextDirection.ltr,
                      );

                      textPainter.layout(maxWidth: constraints.maxWidth);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.post.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              height: 1.6,
                            ),
                            maxLines: _isExpanded ? null : 3,
                            overflow: _isExpanded ? null : TextOverflow.ellipsis,
                          ),
                          if (!_isExpanded && textPainter.didExceedMaxLines)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isExpanded = true;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'See more',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: widget.post.severity.color,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 10,
                                      color: widget.post.severity.color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Feedback Section
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        // Feedback Button
                        GestureDetector(
                          onTap: _toggleFeedback,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _hasGivenFeedback
                                  ? widget.post.severity.color.withOpacity(0.1)
                                  : (_showFeedbackOptions ? Colors.grey[50] : Colors.grey[50]),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _hasGivenFeedback
                                    ? widget.post.severity.color.withOpacity(0.3)
                                    : (_showFeedbackOptions ? widget.post.severity.color.withOpacity(0.2) : Colors.grey[300]!),
                                width: _hasGivenFeedback ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _hasGivenFeedback ? Icons.check_circle : Icons.feedback_outlined,
                                  size: 18,
                                  color: _hasGivenFeedback
                                      ? widget.post.severity.color
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _hasGivenFeedback
                                      ? 'Feedback Recorded'
                                      : (_showFeedbackOptions ? 'Select Option' : 'Give Feedback'),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _hasGivenFeedback
                                        ? widget.post.severity.color
                                        : Colors.grey[700],
                                  ),
                                ),
                                if (!_hasGivenFeedback && !_showFeedbackOptions)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.arrow_drop_down,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Feedback Options (Understood/Not Understood)
                        if (_showFeedbackOptions && !_hasGivenFeedback)
                          SizeTransition(
                            sizeFactor: _feedbackAnimation,
                            child: Container(
                              margin: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildFeedbackOption(
                                      icon: Icons.check_circle_outline,
                                      label: 'Understood',
                                      color: Colors.green,
                                      onTap: () => _handleFeedback(true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildFeedbackOption(
                                      icon: Icons.help_outline,
                                      label: 'Not Understood',
                                      color: Colors.orange,
                                      onTap: () => _handleFeedback(false),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AI Chat Button
                  GestureDetector(
                    onTap: widget.onAIChat,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.post.severity.color,
                            widget.post.severity.color.withOpacity(0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: widget.post.severity.color.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 18,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ask AI about this situation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Left Color Highlight (matches left border)
            Container(
              height: 4,
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.post.severity.color,
                    widget.post.severity.color.withOpacity(0.2),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}