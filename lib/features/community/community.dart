/// Community feature exports
/// Provides a clean interface to the community feature following barrel pattern
library;

// Main feature entry point
export 'main.dart';

// BLoC layer
export 'bloc/blocs/posts_bloc.dart';
export 'bloc/events/posts_event.dart';
export 'bloc/states/posts_state.dart' hide PostsLoading, PostsError;
export 'bloc/blocs/user_search_bloc.dart';
export 'bloc/events/user_search_event.dart';
export 'bloc/states/user_search_state.dart';
export 'bloc/blocs/profile_bloc.dart';
export 'bloc/events/profile_event.dart';
export 'bloc/states/profile_state.dart';
export 'bloc/blocs/community_bloc_manager.dart';

// Screens
export 'screens/community_home_screen.dart';
export 'screens/community_search_screen.dart';
export 'screens/create_post_screen.dart';
export 'screens/post_detail_screen.dart';
export 'screens/user_profile_screen.dart';

// Widgets
export 'widgets/user_post_widget.dart';
export 'widgets/user_avatar.dart';
export 'widgets/create_post_widget.dart';
export 'widgets/post_header.dart';
export 'widgets/post_content.dart';
export 'widgets/post_actions.dart';
export 'widgets/post_menu.dart';
export 'widgets/user_icon.dart';
export 'widgets/user_name.dart';
export 'widgets/like_button.dart';
export 'widgets/like_comment_share_row.dart';

// Components
export 'components/posts_loading.dart';
export 'components/posts_error.dart';