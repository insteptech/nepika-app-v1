import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../domain/community/entities/community_entities.dart';
import '../utils/community_navigation.dart';

/// Post content widget handling text display with clickable links and hashtags
/// Follows Single Responsibility Principle - only handles content display
class PostContent extends StatelessWidget {
  final PostEntity post;
  final String token;
  final String userId;
  final bool disableActions;

  const PostContent({
    super.key,
    required this.post,
    required this.token,
    required this.userId,
    required this.disableActions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 9),
      child: InkWell(
        onTap: disableActions ? null : () => _navigateToPostDetail(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LayoutBuilder(
            builder: (context, constraints) => _buildContentWithTruncation(context, constraints),
          ),
        ),
      ),
    );
  }

  Widget _buildContentWithTruncation(BuildContext context, BoxConstraints constraints) {
    final baseStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w300,
    );
    
    final textSpan = TextSpan(
      text: post.content,
      style: baseStyle,
    );
    
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 5,
    );
    textPainter.layout(maxWidth: constraints.maxWidth);
    
    final isTextOverflowing = textPainter.didExceedMaxLines;
    
    if (isTextOverflowing) {
      return _buildTruncatedContent(context, constraints, baseStyle);
    } else {
      final clickableSpans = _buildClickableTextSpans(context, post.content, baseStyle);
      return RichText(
        text: TextSpan(children: clickableSpans),
      );
    }
  }

  Widget _buildTruncatedContent(BuildContext context, BoxConstraints constraints, TextStyle? baseStyle) {
    final seeMoreSpan = TextSpan(
      text: '..see more',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = disableActions ? null : () => _navigateToPostDetail(context),
    );
    
    // Calculate truncated text to fit with "see more"
    String truncatedText = post.content;
    final words = post.content.split(' ');
    
    // Test with progressively shorter text until it fits
    for (int i = words.length - 1; i > 0; i--) {
      final truncatedContent = words.take(i).join(' ');
      final clickableSpans = _buildClickableTextSpans(context, truncatedContent, baseStyle);
      final testSpan = TextSpan(
        children: [...clickableSpans, seeMoreSpan],
      );
      final testPainter = TextPainter(
        text: testSpan,
        textDirection: TextDirection.ltr,
        maxLines: 5,
      );
      testPainter.layout(maxWidth: constraints.maxWidth);
      
      if (!testPainter.didExceedMaxLines) {
        truncatedText = truncatedContent;
        break;
      }
    }
    
    final finalClickableSpans = _buildClickableTextSpans(context, truncatedText, baseStyle);
    
    return RichText(
      text: TextSpan(
        children: [...finalClickableSpans, seeMoreSpan],
      ),
    );
  }

  List<TextSpan> _buildClickableTextSpans(BuildContext context, String text, TextStyle? baseStyle) {
    final List<TextSpan> spans = [];
    
    // Regex patterns for URLs and hashtags
    final urlPattern = RegExp(r'https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?:/[^\s]*)?');
    final hashtagPattern = RegExp(r'#[a-zA-Z0-9_-]+');
    
    // Find all matches (URLs and hashtags)
    final allMatches = <Match>[];
    allMatches.addAll(urlPattern.allMatches(text));
    allMatches.addAll(hashtagPattern.allMatches(text));
    
    // Sort matches by start position
    allMatches.sort((a, b) => a.start.compareTo(b.start));
    
    int lastIndex = 0;
    
    for (final match in allMatches) {
      // Add normal text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }
      
      final matchText = match.group(0)!;
      
      if (urlPattern.hasMatch(matchText)) {
        // Handle URL
        spans.add(TextSpan(
          text: matchText,
          style: baseStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w500,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchUrl(context, matchText),
        ));
      } else if (hashtagPattern.hasMatch(matchText)) {
        // Handle Hashtag
        spans.add(TextSpan(
          text: matchText,
          style: baseStyle?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => _handleHashtagTap(context, matchText),
        ));
      }
      
      lastIndex = match.end;
    }
    
    // Add remaining normal text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }
    
    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }

  void _navigateToPostDetail(BuildContext context) async {
    await CommunityNavigation.navigateToPostDetail(
      context,
      postId: post.id,
      token: token,
      userId: userId,
    );
  }

  void _launchUrl(BuildContext context, String url) async {
    try {
      // Ensure URL has protocol
      String fullUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        fullUrl = 'https://$url';
      }
      
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(context, 'Could not open $url');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'Error opening link: $e');
    }
  }

  void _handleHashtagTap(BuildContext context, String hashtag) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hashtag tapped: $hashtag'),
        duration: const Duration(seconds: 1),
      ),
    );
    // TODO: Navigate to hashtag search or trending page
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}