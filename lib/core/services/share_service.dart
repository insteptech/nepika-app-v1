import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../../domain/community/entities/community_entities.dart';

/// Service to handle sharing functionality for posts
class ShareService {
  /// Share a post using the native share sheet
  static Future<void> sharePost({
    required BuildContext context,
    required PostEntity post,
  }) async {
    try {
      // Determine what to share
      final String textToShare = _generateShareText(post);
      
      // Check if post has media (assuming single image for now based on UI)
      final String? imageUrl = (post.mediaUrls?.isNotEmpty ?? false) 
          ? post.mediaUrls!.first 
          : post.userAvatar; // Fallback to avatar if desired, or null

      // For now, we prioritize sharing the content/link via text
      // Image sharing would require downloading the file first which adds complexity
      // We will implement text/link sharing first as per requirement
      
      await Share.share(
        textToShare,
        subject: 'Check out this post on Nepika',
      );
      
    } catch (e) {
      debugPrint('ShareService: Error sharing post: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not share post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Generate the text content for sharing
  static String _generateShareText(PostEntity post) {
    final StringBuffer buffer = StringBuffer();
    
    // Add user attribution
    buffer.writeln('Posted by @${post.username} on Nepika:');
    buffer.writeln();
    
    // Add content (truncated if too long, though standard share usually takes full text)
    if (post.content.length > 200) {
      buffer.writeln('${post.content.substring(0, 200)}...');
    } else {
      buffer.writeln(post.content);
    }
    
    buffer.writeln();
    
    // Add Deep Link / Web Link
    // Assuming a standard web URL structure. 
    // If deep linking is set up, this should be the deep link.
    // buffer.writeln('https://nepika.com/post/${post.id}');
    buffer.writeln('Download Nepika to see more!');
    
    return buffer.toString();
  }

  /// Copy post link to clipboard
  static Future<void> copyLink({
    required BuildContext context,
    required String postId,
  }) async {
    try {
      final String link = 'https://nepika.com/post/$postId';
      await Clipboard.setData(ClipboardData(text: link));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('ShareService: Error copying link: $e');
    }
  }
}
