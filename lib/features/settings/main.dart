/// Settings Feature Module
/// 
/// This module provides all settings functionality including:
/// - Main settings screen with navigation options
/// - Community and engagement settings
/// - Notifications and settings management  
/// - Help and support options
/// - Logout functionality with confirmation dialog
/// 
/// Architecture:
/// - Feature-first structure with clear separation of concerns
/// - Reusable components and widgets
/// - Shared models to eliminate code duplication
/// - BLoC state management for complex state operations
/// - Clean abstractions for shared functionality
library;

// Screens
export 'screens/main_settings_screen.dart';
export 'screens/community_settings_screen.dart';
export 'screens/help_support_screen.dart';
export 'screens/notifications_settings_screen.dart';
export 'screens/setup_notifications_screen.dart';
export 'screens/privacy_policy_screen.dart';
export 'screens/terms_of_use_screen.dart';

// Components
export 'components/logout_dialog.dart';
export 'components/settings_options_list.dart';

// Widgets
export 'widgets/settings_header.dart';
export 'widgets/settings_option_tile.dart';

// Models
export 'models/settings_option_data.dart';

// BLoC
export 'bloc/settings_bloc.dart';
export 'bloc/settings_event.dart';
export 'bloc/settings_state.dart';