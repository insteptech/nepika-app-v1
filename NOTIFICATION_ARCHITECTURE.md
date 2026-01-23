# Notification System Architecture

## System Overview

The NEPIKA notification system consists of three main components working together to provide real-time, persistent notifications with visual feedback.

```
┌─────────────────────────────────────────────────────────────────┐
│                     USER INTERFACE LAYER                        │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Activity Page / Notifications Screen                    │   │
│  │  - Displays list of notifications                        │   │
│  │  - Shows badge count in navbar                           │   │
│  │  - Highlights newly arrived notifications (2 sec)        │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌────────────────────┐  ┌─────────────────────────────────┐   │
│  │ Notification Item  │  │  Highlight Animation Service    │   │
│  │ - Yellow highlight │  │  - Broadcasts highlight events  │   │
│  │ - Fade animation   │  │  - 2-second duration            │   │
│  └────────────────────┘  └─────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↑
                              │ emits state
                              │
┌─────────────────────────────────────────────────────────────────┐
│                      STATE MANAGEMENT (BLoC)                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  NotificationBloc                                        │   │
│  │  - Manages notification state                            │   │
│  │  - Listens to real-time updates                          │   │
│  │  - Handles API calls for notification operations         │   │
│  │  - Syncs with NotificationService streams               │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
            ↑                              ↑
            │ events                       │ stream subscriptions
            │                              │
┌────────────┴──────────────────────────────┴──────────────────────┐
│                    SERVICES LAYER                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  NotificationService (Singleton)                          │ │
│  │  - Manages SSE/WebSocket connection                       │ │
│  │  - Parses incoming notification events                    │ │
│  │  - Maintains notification list in memory                  │ │
│  │  - Broadcasts unread count updates                        │ │
│  │  - Streams: notificationStream, unreadCountStream, etc.   │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  UnifiedFCMService                                        │ │
│  │  - Handles push notifications from Firebase              │ │
│  │  - Navigates to notification on tap                       │ │
│  │  - Broadcasts highlight events                           │ │
│  │  - Encodes rich payload data                             │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  NotificationHighlightService (Singleton)                │ │
│  │  - Broadcasts highlight events to UI                     │ │
│  │  - Manages 2-second animation timing                      │ │
│  │  - Event data: notificationId, type, duration            │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
            ↑                              ↑
            │ HTTP requests                │ SSE stream
            │ API calls                    │ connection
            │                              │
┌───────────┴──────────────────────────────┴──────────────────────┐
│                     NETWORK LAYER                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  SecureApiClient (Dio)                                    │ │
│  │  - Makes authenticated HTTP requests                      │ │
│  │  - Adds Bearer token to headers                           │ │
│  │  - Handles request/response errors                        │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  HTTP Stream (SSE)                                        │ │
│  │  - Server-Sent Events connection                          │ │
│  │  - UTF-8 decoded line-by-line streaming                   │ │
│  │  - Handles keep-alive and reconnection                    │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
            ↓                              ↓
            │ API Endpoints                │ SSE Endpoint
            │                              │
┌───────────┴──────────────────────────────┴──────────────────────┐
│                   BACKEND ENDPOINTS                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  GET /community/notifications                             │ │
│  │  - Fetch paginated notification list                      │ │
│  │  - Returns: [{notification}, ...], unread_count           │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  GET /community/notifications/stream (SSE)                │ │
│  │  - Real-time notification stream                          │ │
│  │  - Events: like, reply, follow, mention, comment, etc.    │ │
│  │  - Always includes unread_count in response               │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  POST /community/notifications/{id}/mark-as-seen          │ │
│  │  - Mark notification as seen                              │ │
│  │  - Returns: updated unread_count                          │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Firebase Cloud Messaging                                 │ │
│  │  - Push notification delivery                             │ │
│  │  - Triggers when app is closed                            │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### Push Notification Flow

```
┌─ Backend ─────────────────────┐
│  Creates notification event   │
│  Sends to FCM                 │
└──────────────────────────────┬┘
                               │
                               ↓
                    ┌──────────────────┐
                    │ Firebase Cloud   │
                    │ Messaging (FCM)  │
                    └────────┬─────────┘
                             │
                    ┌────────▼───────────┐
              YES   │ App in foreground? │ NO
             ┌──────┴────────────────────┴──────┐
             ↓                                   ↓
    ┌────────────────────┐          ┌──────────────────────┐
    │ onMessage() method │          │ System notification  │
    │ Shows local notif  │          │ User taps it         │
    │ Broadcasts route   │          │ App opens/resumes    │
    └────────────────────┘          └──────────┬───────────┘
             │                                  │
             └──────────────┬──────────────────┘
                            │
                    ┌───────▼────────┐
                    │ Navigate to    │
                    │ /notifications │
                    │ Display list   │
                    │ Highlight item │
                    │ (2 sec yellow) │
                    └────────────────┘
```

### Real-Time Update Flow

```
┌─ Backend ─────────────────────┐
│ New notification occurs       │
│ (like, comment, follow, etc.) │
└──────────────────────────────┬┘
                               │
                    ┌──────────▼──────────┐
                    │ SSE Stream sends    │
                    │ event to client     │
                    └──────────┬──────────┘
                               │
                 ┌─────────────▼──────────────┐
                 │ NotificationService       │
                 │ - Receives SSE line       │
                 │ - Parses event JSON       │
                 │ - Updates unread count    │
                 │ - Broadcasts via stream   │
                 └─────────────┬──────────────┘
                               │
                 ┌─────────────▼──────────────┐
                 │ NotificationBloc          │
                 │ - Listens to stream       │
                 │ - Emits UnreadCountUpdated│
                 │ - Updates local list      │
                 └─────────────┬──────────────┘
                               │
                    ┌──────────▼──────────┐
                    │ UI Updates Badge    │
                    │ Displays new count  │
                    └─────────────────────┘
```

### Highlight Animation Flow

```
┌─ User Action ─────────────────────┐
│ 1. App receives push notification │
│ 2. OR user navigates from push    │
└────────────────┬──────────────────┘
                 │
        ┌────────▼──────────┐
        │ UnifiedFCMService │
        │ or navigation arg │
        └────────┬──────────┘
                 │
        ┌────────▼───────────────────────┐
        │ NotificationHighlightService   │
        │ - Broadcasts highlight event   │
        │ - Event data: {               │
        │     notificationId,           │
        │     duration: 2 seconds       │
        │   }                           │
        └────────┬───────────────────────┘
                 │
        ┌────────▼──────────────────────┐
        │ NotificationsScreen           │
        │ - Receives highlight event    │
        │ - Marks notification as high  │
        │ - Passes isHighlighted=true   │
        └────────┬──────────────────────┘
                 │
        ┌────────▼──────────────────────┐
        │ NotificationItem Widget       │
        │ - AnimationController starts  │
        │ - ColorTween animation:       │
        │   Yellow (0.3 alpha) →        │
        │   Transparent                 │
        │ - Duration: 2 seconds         │
        │ - Background changes          │
        └────────┬──────────────────────┘
                 │
        ┌────────▼──────────────────────┐
        │ 2 seconds later               │
        │ Animation completes           │
        │ Item reverts to normal style  │
        └───────────────────────────────┘
```

## Component Details

### 1. NotificationService
**Location:** `lib/core/services/notification_service.dart`
**Pattern:** Singleton
**Responsibility:** Central hub for all notification operations

**Key Methods:**
```dart
Future<void> connect()
  // Establishes SSE connection
  // Called on app startup

void _handleSSELine(String line)
  // Parses incoming SSE events
  // Emits through appropriate stream

Future<void> fetchUnreadCount()
  // Fetches current unread count from API

Future<void> markAllNotificationsAsSeen()
  // Resets unread count to 0
```

**Streams:**
```dart
Stream<int> unreadCountStream
  // Broadcasts unread count changes
  
Stream<NotificationEntity> notificationStream
  // (Commented out) new notifications

Stream<DeletedNotificationEntity> deletedNotificationStream
  // Deleted notifications

Stream<bool> connectionStatusStream
  // Connection status changes
```

### 2. UnifiedFCMService
**Location:** `lib/core/services/unified_fcm_service.dart`
**Responsibility:** Push notification handling and navigation

**Key Methods:**
```dart
void _handleNotificationTap(RemoteMessage message)
  // Parses JSON payload
  // Navigates to /notifications
  // Broadcasts highlight event

void _handleNotificationNavigation(Map<String, dynamic> payload)
  // Routes to appropriate screen
  // Passes highlight data
```

**Payload Structure:**
```json
{
  "type": "like",
  "screen": "notifications",
  "user_id": "user_123",
  "post_id": "post_456",
  "notification_id": "notif_789"
}
```

### 3. NotificationHighlightService
**Location:** `lib/core/services/notification_highlight_service.dart`
**Pattern:** Singleton
**Responsibility:** Broadcasting highlight events to UI

**Key Method:**
```dart
void highlightNotification({
  required String notificationId,
  required NotificationType type,
  Duration duration = const Duration(seconds: 2),
})
  // Emits highlight event to stream
```

### 4. NotificationBloc
**Location:** `lib/features/notifications/bloc/notification_bloc.dart`
**Responsibility:** State management and business logic

**Events:**
```dart
ConnectToNotificationStream
DisconnectFromNotificationStream
FetchAllNotifications
MarkAllNotificationsAsSeen
UnreadCountUpdated
NotificationReceived
// ... and more
```

**States:**
```dart
NotificationInitial
NotificationLoading
NotificationLoaded
NotificationError
NotificationConnecting
// ... and more
```

### 5. NotificationItem Widget
**Location:** `lib/features/notifications/widgets/notification_item.dart`
**Type:** StatefulWidget (animation support)
**Responsibility:** Individual notification display with animation

**Animation Details:**
```dart
AnimationController _highlightController
  // Duration: 2 seconds
  
ColorTween _highlightColorAnimation
  // Yellow (0.3 alpha) to transparent
  
When isHighlighted changes:
  // Forward animation
  // Background glows yellow
  // Fades after 2 seconds
```

## State Management Flow

```
┌─ BLoC Events ────────────────────────────────┐
│ ConnectToNotificationStream                  │
│ FetchAllNotifications                        │
│ MarkAllNotificationsAsSeen                   │
│ UnreadCountUpdated                           │
│ ... more events                              │
└─────────────┬────────────────────────────────┘
              │ processed by event handlers
              ↓
┌─ BLoC State Changes ──────────────────────────┐
│ NotificationLoading                          │
│ NotificationLoaded (with unreadCount)        │
│ NotificationError                            │
│ ... more states                              │
└─────────────┬────────────────────────────────┘
              │ emitted to listeners
              ↓
┌─ UI Rebuilds ─────────────────────────────────┐
│ Badge count updates                          │
│ Notification list refreshes                  │
│ Highlight animation triggers                 │
│ Error messages display                       │
└───────────────────────────────────────────────┘
```

## Error Handling

```
┌─ Connection Errors ────────────┐
│ SSE connection fails           │
│ → NotificationError state      │
│ → Show error message           │
│ → Retry after 5 seconds        │
└────────────────────────────────┘

┌─ API Errors ───────────────────┐
│ Notification fetch fails       │
│ → NotificationError state      │
│ → Show error message           │
│ → Allow manual retry           │
└────────────────────────────────┘

┌─ Parsing Errors ──────────────┐
│ Invalid event format           │
│ → Log error                    │
│ → Skip event                   │
│ → Continue listening           │
└────────────────────────────────┘

┌─ Null Safety Errors ───────────┐
│ Subscription not initialized   │
│ → Fixed: use nullable subscript │
│ → Fixed: null-safe operators   │
└────────────────────────────────┘
```

## Performance Optimization

### Memory Management
- Notification list size: capped at reasonable count
- Stream subscriptions properly disposed
- Animation controllers cleaned up on widget dispose
- Singleton services prevent multiple instances

### Network Efficiency
- SSE connection: single persistent connection
- Pagination: 20 items per API call
- Event batching: multiple events in single stream update
- Compression: server-side gzip compression

### UI Responsiveness
- Animation duration: 2 seconds (short, responsive)
- BLoC emits: throttled to prevent excessive rebuilds
- Notification rendering: efficient list widget
- Highlight service: broadcast stream for all listeners

## Security Considerations

### Authentication
- All API requests: Bearer token in headers
- SSE connection: authenticated with token
- Token refresh: automatic via Dio interceptor
- Secure storage: SharedPreferences with encryption

### Data Privacy
- Notification payload: minimal data exposed
- No sensitive data in payloads
- Local cache: cleared on logout
- SSE connection: HTTPS encrypted

### Error Messages
- Generic errors to user
- Detailed logs to console (debug only)
- No sensitive data in error messages
- Graceful degradation on failures

---

**This architecture ensures reliability, scalability, and optimal user experience for the NEPIKA notification system.**
