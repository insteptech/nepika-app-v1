# Follow Request System - API Documentation
 
## Overview
 
This document provides a complete reference for the Follow Request System APIs, including request/response structures and notification formats.
 
---
 
## Base URL
```
https://your-api.com/api/v1
```
 
---
 
## Authentication
All endpoints require Bearer token authentication:
```
Authorization: Bearer <your_access_token>
```
 
---
 
## API Endpoints
 
### 1. Follow a User (Modified)
 
**Endpoint:** `POST /community/follow`
 
**Description:** Follow a user directly (public account) or send a follow request (private account)
 
**Request Body:**
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```
 
**Response - Public Account (Followed Immediately):**
```json
{
  "status": "success",
  "message": "Successfully followed user",
  "data": {
    "is_following": true,
    "follow_request_status": null,
    "message": "Successfully followed user"
  }
}
```
 
**Response - Private Account (Request Sent):**
```json
{
  "status": "success",
  "message": "Follow request sent",
  "data": {
    "is_following": false,
    "follow_request_status": "pending",
    "message": "Follow request sent"
  }
}
```
 
**Response - Already Following:**
```json
{
  "status": "success",
  "message": "Already following this user",
  "data": {
    "is_following": true,
    "follow_request_status": null,
    "message": "Already following this user"
  }
}
```
 
**Error Response - Request Already Pending:**
```json
{
  "status": "error",
  "message": "Follow request already pending",
  "status_code": 400
}
```
 
---
 
### 2. Get Received Follow Requests
 
**Endpoint:** `GET /community/follow-requests/received`
 
**Description:** Get list of people who want to follow you (for private accounts)
 
**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 1 | Page number |
| `page_size` | integer | No | 20 | Items per page (max 100) |
 
**Request Example:**
```
GET /community/follow-requests/received?page=1&page_size=20
Authorization: Bearer <token>
```
 
**Response:**
```json
{
  "status": "success",
  "message": "Received follow requests retrieved successfully",
  "data": {
    "requests": [
      {
        "id": "a1b2c3d4-e5f6-4789-a123-456789abcdef",
        "requester_id": "550e8400-e29b-41d4-a716-446655440000",
        "target_id": "94274ead-1545-4fe4-8cd9-3879908a3ebc",
        "status": "pending",
        "created_at": "2025-10-23T15:30:00Z",
        "updated_at": null,
        "requester_username": "john_doe",
        "requester_profile_image_url": "https://s3.amazonaws.com/.../profile.jpg",
        "requester_is_verified": true
      },
      {
        "id": "b2c3d4e5-f6a7-4890-b234-567890bcdefg",
        "requester_id": "660e8400-e29b-41d4-a716-446655440001",
        "target_id": "94274ead-1545-4fe4-8cd9-3879908a3ebc",
        "status": "pending",
        "created_at": "2025-10-23T14:20:00Z",
        "updated_at": null,
        "requester_username": "jane_smith",
        "requester_profile_image_url": "https://s3.amazonaws.com/.../profile2.jpg",
        "requester_is_verified": false
      }
    ],
    "total": 5,
    "page": 1,
    "page_size": 20,
    "has_more": false
  }
}
```
 
**Empty State Response:**
```json
{
  "status": "success",
  "message": "Received follow requests retrieved successfully",
  "data": {
    "requests": [],
    "total": 0,
    "page": 1,
    "page_size": 20,
    "has_more": false
  }
}
```
 
---
 
### 3. Get Sent Follow Requests
 
**Endpoint:** `GET /community/follow-requests/sent`
 
**Description:** Get list of pending follow requests you sent (waiting for approval)
 
**Query Parameters:**
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 1 | Page number |
| `page_size` | integer | No | 20 | Items per page (max 100) |
 
**Request Example:**
```
GET /community/follow-requests/sent?page=1&page_size=20
Authorization: Bearer <token>
```
 
**Response:**
```json
{
  "status": "success",
  "message": "Sent follow requests retrieved successfully",
  "data": {
    "requests": [
      {
        "id": "c3d4e5f6-a7b8-4901-c345-678901cdefgh",
        "requester_id": "94274ead-1545-4fe4-8cd9-3879908a3ebc",
        "target_id": "770e9511-f30c-52e5-b827-557766550002",
        "status": "pending",
        "created_at": "2025-10-23T16:00:00Z",
        "updated_at": null,
        "target_username": "private_user",
        "target_profile_image_url": "https://s3.amazonaws.com/.../profile3.jpg",
        "target_is_verified": true
      }
    ],
    "total": 1,
    "page": 1,
    "page_size": 20,
    "has_more": false
  }
}
```
 
---
 
### 4. Accept Follow Request
 
**Endpoint:** `POST /community/follow-requests/accept/{request_id}`
 
**Description:** Accept a follow request (creates the follow relationship)
 
**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `request_id` | UUID | Yes | ID of the follow request |
 
**Request Example:**
```
POST /community/follow-requests/accept/a1b2c3d4-e5f6-4789-a123-456789abcdef
Authorization: Bearer <token>
```
 
**Response:**
```json
{
  "status": "success",
  "message": "Follow request accepted",
  "data": {
    "success": true,
    "message": "Follow request accepted",
    "request_id": "a1b2c3d4-e5f6-4789-a123-456789abcdef",
    "status": "accepted"
  }
}
```
 
**What Happens:**
- ✅ Follow request status updated to `accepted`
- ✅ Follow relationship created in database
- ✅ Follower/following counts incremented
- ✅ SSE notification sent to requester
- ✅ FCM push notification sent to requester
 
**Error Response - Request Not Found:**
```json
{
  "status": "error",
  "message": "Follow request not found or you are not authorized to access it",
  "status_code": 404
}
```
 
---
 
### 5. Decline Follow Request
 
**Endpoint:** `POST /community/follow-requests/decline/{request_id}`
 
**Description:** Decline a follow request (no follow relationship created)
 
**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `request_id` | UUID | Yes | ID of the follow request |
 
**Request Example:**
```
POST /community/follow-requests/decline/a1b2c3d4-e5f6-4789-a123-456789abcdef
Authorization: Bearer <token>
```
 
**Response:**
```json
{
  "status": "success",
  "message": "Follow request declined",
  "data": {
    "success": true,
    "message": "Follow request declined",
    "request_id": "a1b2c3d4-e5f6-4789-a123-456789abcdef",
    "status": "declined"
  }
}
```
 
**What Happens:**
- ✅ Follow request status updated to `declined`
- ✅ Requester can send a new request later
- ✅ No follow relationship created
 
---
 
### 6. Cancel Follow Request
 
**Endpoint:** `DELETE /community/follow-requests/cancel/{target_user_id}`
 
**Description:** Cancel a pending follow request you sent
 
**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `target_user_id` | UUID | Yes | User ID you sent the request to |
 
**Request Example:**
```
DELETE /community/follow-requests/cancel/770e9511-f30c-52e5-b827-557766550002
Authorization: Bearer <token>
```
 
**Response:**
```json
{
  "status": "success",
  "message": "Follow request cancelled",
  "data": {
    "success": true,
    "message": "Follow request cancelled",
    "status": "cancelled"
  }
}
```
 
**What Happens:**
- ✅ Follow request deleted from database
- ✅ You can send a new request later
 
**Error Response - No Pending Request:**
```json
{
  "status": "error",
  "message": "No pending follow request found for this user",
  "status_code": 404
}
```
 
---
 
### 7. Check Follow Request Status
 
**Endpoint:** `GET /community/follow-requests/status/{target_user_id}`
 
**Description:** Check if you have a pending/accepted/declined request with a user
 
**Path Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `target_user_id` | UUID | Yes | User ID to check status with |
 
**Request Example:**
```
GET /community/follow-requests/status/770e9511-f30c-52e5-b827-557766550002
Authorization: Bearer <token>
```
 
**Response - Has Pending Request:**
```json
{
  "status": "success",
  "message": "Follow request status retrieved successfully",
  "data": {
    "status": "pending",
    "has_request": true
  }
}
```
 
**Response - No Request:**
```json
{
  "status": "success",
  "message": "Follow request status retrieved successfully",
  "data": {
    "status": null,
    "has_request": false
  }
}
```
 
**Possible Status Values:**
- `"pending"` - Request is waiting for approval
- `"accepted"` - Request was accepted (now following)
- `"declined"` - Request was declined
- `null` - No request exists
 
---
 
### 8. Get User Profile (Updated)
 
**Endpoint:** `GET /community/profiles/{user_id}`
 
**Description:** Get user profile with follow request status
 
**Response:**
```json
{
  "status": "success",
  "message": "Profile retrieved successfully",
  "data": {
    "id": "a1b2c3d4-e5f6-4789-a123-456789abcdef",
    "user_id": "770e9511-f30c-52e5-b827-557766550002",
    "username": "jane_private",
    "bio": "This is my bio",
    "profile_image_url": "https://s3.amazonaws.com/.../profile.jpg",
    "banner_image_url": "https://s3.amazonaws.com/.../banner.jpg",
    "is_private": true,
    "is_verified": false,
    "followers_count": 450,
    "following_count": 320,
    "posts_count": 0,
    "is_self": false,
    "is_following": false,
    "follow_request_status": "pending",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-10-23T11:00:00Z"
  }
}
```
 
**Key Fields for Follow System:**
- `is_private` (boolean) - If true, requires follow request approval
- `is_following` (boolean) - If true, you are already following this user
- `follow_request_status` (string|null) - Status of your follow request:
  - `null` - No request sent
  - `"pending"` - Request sent, waiting for approval
  - `"accepted"` - Request accepted (same as is_following: true)
  - `"declined"` - Request declined
 
---
 
## Notifications
 
### SSE (Server-Sent Events)
 
**Endpoint:** `GET /community/notifications/stream`
 
**Authentication:** Bearer token required
 
**Connection:**
```typescript
const eventSource = new EventSource('/api/v1/community/notifications/stream', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```
 
### Notification Types
 
#### 1. Follow Request Received (`follow_request`)
 
**When:** Someone sends a follow request to your private account
 
**Payload:**
```json
{
  "type": "follow_request",
  "notification_id": "776e861d-6823-4bcd-ae46-425da5fbe226",
  "message": "madhav wants to follow you",
  "actor": {
    "id": "680f2493-baec-4a9c-9545-3b05657ed099",
    "username": "madhav",
    "full_name": "Madhav Kumar",
    "profile_image_url": "https://s3.amazonaws.com/.../profile.jpg"
  },
  "post_id": null,
  "created_at": "2025-10-23T11:43:08.220916Z",
  "unread_count": 3
}
```
 
**What to Do:**
- Show in-app notification: "madhav wants to follow you"
- Update follow requests badge count
- Navigate to follow requests list when clicked
 
---
 
#### 2. Follow Request Accepted (`follow_request_accepted`)
 
**When:** Someone accepts your follow request
 
**Payload:**
```json
{
  "type": "follow_request_accepted",
  "notification_id": "886f951e-7834-5cde-b157-536800cdefg3",
  "message": "nitin accepted your follow request",
  "actor": {
    "id": "94274ead-1545-4fe4-8cd9-3879908a3ebc",
    "username": "nitin",
    "full_name": "Nitin Sharma",
    "profile_image_url": "https://s3.amazonaws.com/.../profile.jpg"
  },
  "post_id": null,
  "created_at": "2025-10-23T11:45:32.445821Z",
  "unread_count": 4
}
```
 
**What to Do:**
- Show in-app notification: "nitin accepted your follow request"
- Update UI to show you're now following this user
- Navigate to their profile when clicked
 
---
 
#### 3. New Follower (`follow`)
 
**When:** Someone follows your public account (instant follow, no request)
 
**Payload:**
```json
{
  "type": "follow",
  "notification_id": "996g062f-8945-6def-c268-647911defgh4",
  "message": "john_doe started following you",
  "actor": {
    "id": "770e9511-f30c-52e5-b827-557766550002",
    "username": "john_doe",
    "full_name": "John Doe",
    "profile_image_url": "https://s3.amazonaws.com/.../profile.jpg"
  },
  "post_id": null,
  "created_at": "2025-10-23T11:46:15.778945Z",
  "unread_count": 5
}
```
 
**What to Do:**
- Show in-app notification: "john_doe started following you"
- Increment follower count
- Navigate to their profile when clicked
 
---
 
### FCM Push Notifications
 
Push notifications are automatically sent via Firebase Cloud Messaging. They contain the same information as SSE notifications:
 
**Data Payload:**
```json
{
  "type": "follow_request",
  "actor_id": "680f2493-baec-4a9c-9545-3b05657ed099",
  "actor_username": "madhav",
  "actor_profile_image_url": "https://s3.amazonaws.com/.../profile.jpg"
}
```
 
**Notification Payload:**
```json
{
  "title": "New Follow Request",
  "body": "madhav wants to follow you"
}
```
 
---
 
## Response Data Types
 
### FollowRequest Object
```typescript
{
  id: string;                          // UUID
  requester_id: string;                // UUID
  target_id: string;                   // UUID
  status: "pending" | "accepted" | "declined";
  created_at: string;                  // ISO 8601 datetime
  updated_at: string | null;           // ISO 8601 datetime
 
  // Enriched user info (when listing requests)
  requester_username?: string;
  requester_profile_image_url?: string;
  requester_is_verified?: boolean;
  target_username?: string;
  target_profile_image_url?: string;
  target_is_verified?: boolean;
}
```
 
### FollowResponseWithStatus
```typescript
{
  is_following: boolean;
  follow_request_status: "pending" | "accepted" | "declined" | null;
  message: string;
}
```
 
### SSE Notification Object
```typescript
{
  type: "follow_request" | "follow_request_accepted" | "follow" | "like" | "reply" | "mention";
  notification_id: string;             // UUID
  message: string;                     // Pre-formatted message
  actor: {
    id: string;                        // UUID
    username: string;
    full_name: string;
    profile_image_url: string;
  };
  post_id: string | null;              // UUID or null
  created_at: string;                  // ISO 8601 datetime
  unread_count: number;                // Total unread notifications
}
```
 
---
 
## Error Responses
 
All error responses follow this format:
 
```json
{
  "status": "error",
  "message": "Error message here",
  "status_code": 400
}
```
 
### Common Errors
 
**400 Bad Request:**
- "Cannot follow yourself"
- "Follow request already pending"
- "Already following this user"
 
**401 Unauthorized:**
- "Authentication required"
- "Invalid or expired token"
 
**404 Not Found:**
- "User not found"
- "Follow request not found or you are not authorized to access it"
- "No pending follow request found for this user"
 
**500 Internal Server Error:**
- "An unexpected error occurred"
 
---
 
## Quick Reference
 
### Follow System States
 
| User State | Button Label | Button Action | API Call |
|------------|--------------|---------------|----------|
| Public account, not following | "Follow" | Follow immediately | `POST /community/follow` |
| Private account, no request | "Follow" | Send follow request | `POST /community/follow` |
| Request pending | "Requested" | Cancel request | `DELETE /follow-requests/cancel/{user_id}` |
| Following | "Following" | Unfollow | `DELETE /community/follow/{user_id}` |
| Own profile | "Edit Profile" | Navigate to edit | - |
 
### Notification Handling
 
| Event Type | Action | Navigate To |
|------------|--------|-------------|
| `follow_request` | Show "wants to follow you" | Follow requests list |
| `follow_request_accepted` | Show "accepted your request" | User's profile |
| `follow` | Show "started following you" | User's profile |
 
---
 
**Last Updated:** 2025-10-23
**API Version:** v1