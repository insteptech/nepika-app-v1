# Flutter SSE Real-Time Notifications Integration Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [API Endpoints Reference](#api-endpoints-reference)
4. [Required Packages](#required-packages)
5. [Implementation Architecture](#implementation-architecture)
6. [Integration Steps](#integration-steps)
7. [Event Formats](#event-formats)
8. [Testing Guide](#testing-guide)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### What is SSE (Server-Sent Events)?
SSE is a one-way communication channel from server to client that allows the backend to push real-time updates to your Flutter app without polling.

### Notification Types
Your app will receive real-time notifications for:

| Type | Trigger | Auto-Delete When |
|------|---------|------------------|
| **like** | User likes your post | User unlikes |
| **reply** | User comments on your post | User deletes comment |
| **follow** | User follows you | User unfollows |
| **mention** | User mentions you (@username) | User deletes post |

### How It Works
```
User A performs action → Backend creates notification → SSE sends to User B → Flutter updates UI
User A reverses action → Backend deletes notification → SSE sends deletion event → Flutter removes from UI
```

---

## Prerequisites

### Required Knowledge
- Flutter state management (Provider/Riverpod/Bloc)
- HTTP requests in Flutter
- JWT authentication handling
- Dart async/streams

### App Requirements
- Authentication implemented (JWT token available)
- User session management
- Network connectivity handling

---

## API Endpoints Reference

### Base URL
```
YOUR_BACKEND_URL/api/v1
```

### Endpoints

#### 1. SSE Stream (Real-time notifications)
```
GET /community/notifications/stream
Headers: Authorization: Bearer <JWT_TOKEN>
Response: text/event-stream
```

#### 2. Get Unread Count
```
GET /community/notifications/unread-count
Headers: Authorization: Bearer <JWT_TOKEN>
Response: {"status": "success", "data": {"unread_count": 5}}
```

#### 3. Mark All as Seen
```
POST /community/notifications/mark-seen
Headers: Authorization: Bearer <JWT_TOKEN>
Response: {"status": "success", "message": "Notifications marked as seen"}
```

### Authentication
All endpoints require JWT token in header:
```
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## Required Packages

Add these packages to your `pubspec.yaml`:

### Essential
- **HTTP Client**: For API calls (http, dio, etc.)
- **SSE Client**: For Server-Sent Events connection
- **State Management**: Your choice (Provider, Riverpod, Bloc, GetX)

### Optional
- **Local Notifications**: For background notifications
- **Connectivity Check**: To handle network changes

---

## Implementation Architecture

### 1. Service Layer
Create a **NotificationService** that handles:
- Opening SSE connection
- Parsing incoming events
- Maintaining notification list
- Managing unread count
- Closing connection

### 2. State Management Layer
Create a **NotificationProvider/Controller** that:
- Wraps the service
- Exposes data to UI
- Triggers UI rebuilds
- Manages lifecycle

### 3. UI Layer
Build these components:
- **Notification Badge**: Shows unread count
- **Notification List**: Displays all notifications
- **Notification Item**: Individual notification display

### 4. Data Models
Define models for:
- Notification (with type, actor, message, timestamp)
- Actor (user who triggered notification)
- Deleted Notification (for removal events)

---

## Integration Steps

### Step 1: Set Up Data Models

Create models to represent:

**Notification Model** should include:
- Notification type (like, reply, follow, mention)
- Notification ID
- Message text
- Actor information (id, username, profile image)
- Post ID (if applicable)
- Created timestamp
- Unread count

**Actor Model** should include:
- User ID
- Username
- Full name
- Profile image URL

**Deleted Notification Model** should include:
- Type
- Actor ID
- Post ID

### Step 2: Create Notification Service

Your service should handle:

**Connection Management:**
- Connect to SSE stream with JWT token
- Handle connection errors
- Auto-reconnect on disconnect
- Close connection properly

**Event Processing:**
- Parse incoming SSE events (format: `data: {...}`)
- Distinguish between creation and deletion events
- Update local notification list
- Update unread count
- Emit updates to listeners

**API Integration:**
- Fetch initial unread count
- Mark notifications as seen
- Handle API errors

**Event Types to Handle:**
1. `connected` - Initial connection confirmation
2. `like` - Like notification
3. `reply` - Reply notification
4. `follow` - Follow notification
5. `mention` - Mention notification
6. `notification_deleted` - Deletion event
7. Heartbeat (`: heartbeat`) - Keep-alive ping every 30 seconds

### Step 3: Implement State Management

Choose your state management solution and:

**Expose:**
- List of notifications
- Unread count
- Loading state
- Error state

**Actions:**
- Connect to SSE (on login/app start)
- Disconnect from SSE (on logout/app close)
- Mark all as seen
- Refresh unread count

**Lifecycle:**
- Connect when user logs in
- Disconnect when user logs out
- Reconnect when app resumes
- Disconnect when app pauses

### Step 4: Build Notification Badge

Create a widget that:
- Shows notification icon
- Displays unread count badge (if > 0)
- Updates in real-time
- Navigates to notification list on tap

**Badge Requirements:**
- Circle shape overlay on icon
- Red background
- White text
- Hide when count is 0

### Step 5: Build Notification List Screen

Create a screen that:
- Displays all notifications in chronological order
- Shows empty state when no notifications
- Marks all as seen when opened
- Allows navigation to related content (post/profile)

**Notification Item Display:**
- Profile picture with notification type icon overlay
- Message text
- Relative timestamp ("2m ago", "1h ago")
- Different icons/colors per type

**Type Icons:**
- Like → Heart (❤️ / Red)
- Reply → Comment (💬 / Blue)
- Follow → Person (👤 / Green)
- Mention → At symbol (📢 / Orange)

### Step 6: Initialize on App Start

In your app initialization:
1. Check if user is logged in
2. Get JWT token from storage
3. Connect to SSE stream
4. Fetch initial unread count
5. Listen for notification updates

### Step 7: Handle App Lifecycle

Implement lifecycle management:
- **App Resumed** → Reconnect SSE
- **App Paused** → Disconnect SSE (save battery)
- **User Login** → Connect SSE
- **User Logout** → Disconnect SSE
- **Network Lost** → Handle gracefully, auto-reconnect when back

---

## Event Formats

### New Notification Event

**Event types:** `like`, `reply`, `follow`, `mention`

```json
{
  "type": "like",
  "notification_id": "uuid",
  "message": "john_doe liked your post",
  "actor": {
    "id": "user-id",
    "username": "john_doe",
    "full_name": "John Doe",
    "profile_image_url": "url"
  },
  "post_id": "post-id",
  "created_at": "2025-10-01T12:00:00",
  "unread_count": 5
}
```

### Notification Deleted Event

**Event type:** `notification_deleted`

```json
{
  "type": "notification_deleted",
  "deleted_notification": {
    "type": "like",
    "actor_id": "user-id",
    "post_id": "post-id"
  },
  "unread_count": 4
}
```

### Connection Event

**Event type:** `connected`

```json
{
  "type": "connected"
}
```

### Heartbeat

Raw SSE format (not JSON):
```
: heartbeat
```

**Note:** Heartbeats are sent every 30 seconds. Ignore these or use them to detect connection alive.

---

## Testing Guide

### Test 1: Connection

**Steps:**
1. Login to your Flutter app
2. Check console/logs for "SSE Connected" message
3. Verify no error messages

**Expected:** Successful connection within 2-3 seconds

---

### Test 2: Like Notification

**Setup:**
- User A: API client (Postman/curl)
- User B: Flutter app

**Steps:**
1. Open Flutter app as User B
2. Using Postman, like a post as User A:
   ```
   POST /api/v1/community/posts/{post_id}/like
   Headers: Authorization: Bearer USER_A_TOKEN
   ```
3. Watch Flutter app

**Expected Results:**
- Badge count increases instantly
- New notification appears in list
- Message shows: "user_a liked your post"
- No page refresh needed

---

### Test 3: Unlike (Auto-Delete)

**Steps:**
1. Using Postman, unlike the same post (toggle like again)
2. Watch Flutter app

**Expected Results:**
- Badge count decreases instantly
- Notification disappears from list
- No page refresh needed

---

### Test 4: Reply Notification

**Steps:**
1. Using Postman, comment on User B's post as User A:
   ```
   POST /api/v1/community/posts
   Body: {
     "content": "Great post!",
     "parent_post_id": "USER_B_POST_ID"
   }
   Headers: Authorization: Bearer USER_A_TOKEN
   ```
2. Watch Flutter app

**Expected:** Reply notification appears

---

### Test 5: Delete Reply (Auto-Delete)

**Steps:**
1. Using Postman, delete the comment:
   ```
   DELETE /api/v1/community/posts/{comment_id}
   Headers: Authorization: Bearer USER_A_TOKEN
   ```
2. Watch Flutter app

**Expected:** Reply notification disappears

---

### Test 6: Follow Notification

**Steps:**
1. Using Postman, follow User B as User A:
   ```
   POST /api/v1/community/profiles/{user_b_id}/follow
   Headers: Authorization: Bearer USER_A_TOKEN
   ```
2. Watch Flutter app

**Expected:** Follow notification appears

---

### Test 7: Unfollow (Auto-Delete)

**Steps:**
1. Using Postman, unfollow User B:
   ```
   DELETE /api/v1/community/profiles/{user_b_id}/follow
   Headers: Authorization: Bearer USER_A_TOKEN
   ```
2. Watch Flutter app

**Expected:** Follow notification disappears

---

### Test 8: Mention Notification

**Steps:**
1. Using Postman, create post mentioning User B:
   ```
   POST /api/v1/community/posts
   Body: {
     "content": "Hey @user_b check this out!"
   }
   Headers: Authorization: Bearer USER_A_TOKEN
   ```
2. Watch Flutter app

**Expected:** Mention notification appears

---

### Test 9: Mark as Seen

**Steps:**
1. Ensure there are unread notifications (badge shows count)
2. Open notifications screen in Flutter app
3. Watch badge count

**Expected:**
- Badge count becomes 0
- All notifications remain visible in list

---

## Best Practices

### 1. Connection Management

**Do:**
- Connect after successful login
- Disconnect on logout
- Reconnect when app resumes from background
- Disconnect when app goes to background (save battery/data)

**Don't:**
- Keep connection open when user not logged in
- Forget to close connection on logout
- Open multiple connections

### 2. Error Handling

**Handle these scenarios:**
- Connection timeout
- Network lost
- Token expired (401 error)
- Server unavailable (500 error)
- Invalid event format

**Recovery strategies:**
- Auto-reconnect after 5 seconds
- Show user-friendly error messages
- Fallback to polling if SSE fails repeatedly
- Refresh token if expired

### 3. Performance Optimization

**Tips:**
- Limit notification list to last 50-100 items
- Lazy load older notifications
- Cache notifications locally
- Clear old notifications periodically
- Dispose streams/subscriptions properly

### 4. UI/UX Considerations

**User experience:**
- Show loading state while connecting
- Display "Connecting..." if reconnecting
- Animate badge count changes
- Show toast for new notifications (optional)
- Use sound/vibration (optional)
- Allow users to disable real-time updates

### 5. Security

**Important:**
- Never log JWT tokens
- Store tokens securely (encrypted storage)
- Validate all incoming events
- Handle malformed data gracefully
- Clear tokens on logout

### 6. Lifecycle Management

**App States:**
- **Foreground** → SSE connected
- **Background** → SSE disconnected (optional: keep for high-priority apps)
- **Terminated** → SSE auto-disconnects
- **Resumed** → SSE reconnects

### 7. Testing

**Test scenarios:**
- Slow network
- Network disconnect/reconnect
- Token expiration during SSE
- Multiple rapid notifications
- App background/foreground transitions
- Fresh install vs existing user

---

## Troubleshooting

### Issue 1: SSE Not Connecting

**Symptoms:**
- No connection established
- Timeout errors
- Connection immediately closes

**Solutions:**
1. Verify backend is running (test with curl/Postman)
2. Check JWT token is valid and not expired
3. Verify network connectivity
4. Check URL format (http vs https)
5. Ensure proper headers are sent
6. Check firewall/proxy settings

**Test connection with curl:**
```bash
curl -N -H "Authorization: Bearer YOUR_TOKEN" \
  http://YOUR_BACKEND/api/v1/community/notifications/stream
```

---

### Issue 2: No Notifications Received

**Symptoms:**
- Connected but no events arrive
- Heartbeats working but no notifications

**Solutions:**
1. Verify user has notifications in backend
2. Check event parsing logic
3. Test with Postman to trigger notification
4. Check console for parsing errors
5. Verify event type matching

---

### Issue 3: Badge Count Not Updating

**Symptoms:**
- Notifications arrive but badge stuck
- Count incorrect

**Solutions:**
1. Check state management is notifying listeners
2. Verify unread_count field is being parsed
3. Call initial fetch on app start
4. Ensure mark-as-seen API is called correctly

---

### Issue 4: Memory Leaks

**Symptoms:**
- App crashes after extended use
- Memory usage increases over time

**Solutions:**
1. Dispose streams properly
2. Close SSE connection on screen dispose
3. Limit notification list size
4. Clear old notifications periodically
5. Cancel all subscriptions on logout

---

### Issue 5: Notifications Disappear Randomly

**Symptoms:**
- Notifications removed unexpectedly
- List empties randomly

**Solutions:**
1. Check deletion event handling logic
2. Verify matching criteria (type + actor_id + post_id)
3. Don't match partial data
4. Log deletion events to debug

---

### Issue 6: Connection Drops Frequently

**Symptoms:**
- Constant reconnecting
- Connection unstable

**Solutions:**
1. Check network stability
2. Increase heartbeat timeout
3. Implement exponential backoff for reconnection
4. Check server timeout settings
5. Monitor backend logs for errors

---

### Issue 7: Token Expired During SSE

**Symptoms:**
- 401 Unauthorized after some time
- Connection closes unexpectedly

**Solutions:**
1. Implement token refresh mechanism
2. Reconnect with new token
3. Handle 401 errors gracefully
4. Prompt user to re-login if needed

---

## SSE vs WebSocket

### Why SSE for This Use Case?

**SSE Advantages:**
- ✅ Simpler implementation
- ✅ Automatic reconnection
- ✅ Works over HTTP (no special protocol)
- ✅ Built-in event IDs
- ✅ Works with JWT auth easily
- ✅ One-way is sufficient for notifications

**When to Use WebSocket:**
- Need two-way communication (chat)
- Real-time collaboration
- Gaming
- Live location tracking

**For notifications, SSE is perfect!**

---

## Performance Benchmarks

### Expected Metrics

**Connection:**
- Initial connection: 1-3 seconds
- Reconnection: 1-2 seconds
- Heartbeat interval: 30 seconds

**Latency:**
- Notification delivery: < 500ms
- Badge update: Immediate (< 100ms)
- UI update: < 200ms

**Resource Usage:**
- Memory: ~5-10 MB for SSE connection
- Battery: Minimal (idle connection)
- Network: ~1-2 KB/min (heartbeats only)

---

## Summary

### What You Need to Build

1. **Service Layer**
   - SSE connection handler
   - Event parser
   - API client for mark-as-seen

2. **State Management**
   - Notification list state
   - Unread count state
   - Loading/error states

3. **UI Components**
   - Notification badge (with count)
   - Notification list screen
   - Individual notification items

4. **Lifecycle Management**
   - Connect on login
   - Disconnect on logout
   - Handle app background/foreground

### Key Implementation Points

- Parse SSE events correctly (handle `data:` prefix)
- Match deleted notifications by type + actor_id + post_id
- Update badge count from event payload
- Mark as seen when opening notification screen
- Auto-reconnect on disconnect

### Success Criteria

✅ Notifications arrive in real-time (< 1 second)
✅ Badge count updates automatically
✅ Deleted notifications disappear automatically
✅ No page refresh needed
✅ Works across app restarts
✅ Handles network disconnects gracefully

---

**Need Help?**
- Test API endpoints first with Postman/curl
- Check backend logs for SSE events
- Monitor Flutter console for errors
- Verify JWT token validity

**Happy Coding! 🚀**
