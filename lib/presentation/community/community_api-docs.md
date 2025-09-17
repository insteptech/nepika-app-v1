# 🌟 Community Module API Documentation

A comprehensive Twitter-like social media platform with posts, comments, likes, profiles, and follow system.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Authentication](#authentication)
3. [Post Management](#post-management)
4. [User-Specific Post Endpoints](#user-specific-post-endpoints)
5. [Profile Management](#profile-management)
6. [Social Features](#social-features)
7. [Block Management](#block-management)
8. [Response Format](#response-format)
9. [Error Handling](#error-handling)

---

## 🎯 Overview

The Community Module provides a complete social media experience with the following features:

- **Posts & Comments**: Create, read, update, delete posts with nested commenting system
- **Like System**: Toggle likes on posts and comments (including own posts)
- **User Profiles**: Create and manage community profiles with social metrics
- **Follow System**: Follow/unfollow users with real-time follower counts
- **Feed Generation**: Personalized feeds based on follows and user activity
- **User-Specific Posts**: Dedicated endpoints to fetch specific user's posts and comments
- **Block Management**: Block/unblock users to prevent unwanted interactions
- **Pagination**: All list endpoints support pagination for optimal performance

**Base URL:** `http://localhost:8000/api/v1/community`

---

## 🔐 Authentication

All endpoints require JWT authentication via the Authorization header:

```http
Authorization: Bearer <your_jwt_token>
```

---

## 📝 Post Management

### 1. Create Post

**Purpose:** Create a new post or reply to existing posts  
**Method:** `POST`  
**URL:** `/community/posts`

**Request Body:**
```json
{
  "content": "Hello world! This is my first post on the community platform 🚀",
  "parent_post_id": null
}
```

**Request Body (Reply):**
```json
{
  "content": "Great post! I totally agree with your points 👍",
  "parent_post_id": "de68d1d6-8577-48a0-91c1-642ee05667d1"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Post created successfully",
  "status_code": 201,
  "data": {
    "id": "de68d1d6-8577-48a0-91c1-642ee05667d1",
    "user_id": "7c42f706-59cc-4535-b120-2030a2e2377c",
    "tenant_id": null,
    "content": "Hello world! This is my first post on the community platform 🚀",
    "parent_post_id": null,
    "like_count": 0,
    "comment_count": 0,
    "is_edited": false,
    "is_deleted": false,
    "created_at": "2025-09-08T09:45:31.820925",
    "updated_at": null,
    "username": "new_username_2024",
    "user_avatar": "https://gravatar.com/avatar/professional_headshot.jpg",
    "is_liked_by_user": false
  }
}
```

---

### 2. Get Posts Feed

**Purpose:** Retrieve posts with filtering and pagination options  
**Method:** `GET`  
**URL:** `/community/posts`

**Query Parameters:**
- `page` (int, optional): Page number (default: 1)
- `page_size` (int, optional): Items per page (default: 20, max: 100)
- `user_id` (UUID, optional): Filter posts by specific user
- `following_only` (bool, optional): Show only posts from followed users

**Example URLs:**
```bash
# Get all posts (community feed)
GET /community/posts?page=1&page_size=20

# Get specific user's posts
GET /community/posts?user_id=7c42f706-59cc-4535-b120-2030a2e2377c

# Get posts from followed users only
GET /community/posts?following_only=true&page=1&page_size=10
```

**Response:**
```json
{
  "success": true,
  "message": "Posts retrieved successfully",
  "status_code": 200,
  "data": {
    "posts": [
      {
        "id": "de68d1d6-8577-48a0-91c1-642ee05667d1",
        "user_id": "7c42f706-59cc-4535-b120-2030a2e2377c",
        "content": "Hello world! This is my first post...",
        "parent_post_id": null,
        "like_count": 5,
        "comment_count": 2,
        "is_edited": false,
        "created_at": "2025-09-08T09:45:31.820925",
        "username": "new_username_2024",
        "user_avatar": "https://gravatar.com/avatar/professional_headshot.jpg",
        "is_liked_by_user": true
      }
    ],
    "total": 150,
    "page": 1,
    "page_size": 20,
    "has_more": true
  }
}
```

---

### 3. Get Single Post

**Purpose:** Retrieve a specific post by ID  
**Method:** `GET`  
**URL:** `/community/posts/{post_id}`

**Example:**
```bash
GET /community/posts/de68d1d6-8577-48a0-91c1-642ee05667d1
```

**Response:** Same as individual post object in posts feed

---

### 4. Get Post Comments

**Purpose:** Retrieve comments/replies for a specific post  
**Method:** `GET`  
**URL:** `/community/posts/{post_id}/comments`

**Query Parameters:**
- `page` (int, optional): Page number (default: 1)
- `page_size` (int, optional): Items per page (default: 20, max: 100)

**Example:**
```bash
GET /community/posts/de68d1d6-8577-48a0-91c1-642ee05667d1/comments?page=1&page_size=20
```

**Response:**
```json
{
  "success": true,
  "message": "Comments retrieved successfully",
  "status_code": 200,
  "data": {
    "comments": [
      {
        "id": "comment-uuid-here",
        "user_id": "7c42f706-59cc-4535-b120-2030a2e2377c",
        "content": "Great post! Thanks for sharing.",
        "parent_post_id": "de68d1d6-8577-48a0-91c1-642ee05667d1",
        "like_count": 3,
        "comment_count": 1,
        "created_at": "2025-09-08T10:15:31.820925",
        "username": "commenter_user",
        "is_liked_by_user": false
      }
    ],
    "total": 25,
    "page": 1,
    "page_size": 20,
    "has_more": true,
    "parent_post_id": "de68d1d6-8577-48a0-91c1-642ee05667d1"
  }
}
```

---

### 5. Update Post

**Purpose:** Update content of an existing post (only by post owner)  
**Method:** `PUT`  
**URL:** `/community/posts/{post_id}`

**Request Body:**
```json
{
  "content": "Updated: Hello world! This is my EDITED post on the community platform 🚀✨"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Post updated successfully",
  "status_code": 200,
  "data": {
    "id": "de68d1d6-8577-48a0-91c1-642ee05667d1",
    "content": "Updated: Hello world! This is my EDITED post...",
    "is_edited": true,
    "updated_at": "2025-09-08T10:30:00.000000"
  }
}
```

---

### 6. Delete Post

**Purpose:** Soft delete a post (only by post owner)  
**Method:** `DELETE`  
**URL:** `/community/posts/{post_id}`

**No Request Body Required**

**Response:**
```json
{
  "success": true,
  "message": "Post deleted successfully",
  "status_code": 200,
  "data": {
    "deleted": true
  }
}
```

---

### 7. Toggle Like

**Purpose:** Like or unlike a post (toggle functionality)  
**Method:** `PUT`  
**URL:** `/community/posts/{post_id}/like`

**No Request Body Required**

**Example:**
```bash
PUT /community/posts/de68d1d6-8577-48a0-91c1-642ee05667d1/like
```

**Response (Liked):**
```json
{
  "success": true,
  "message": "Post liked successfully",
  "status_code": 200,
  "data": {
    "is_liked": true,
    "like_count": 6,
    "message": "Post liked successfully"
  }
}
```

**Response (Unliked):**
```json
{
  "success": true,
  "message": "Post unliked successfully",
  "status_code": 200,
  "data": {
    "is_liked": false,
    "like_count": 5,
    "message": "Post unliked successfully"
  }
}
```

---

## 📚 User-Specific Post Endpoints

### 17. Get Current User's Main Posts

**Purpose:** Retrieve the current user's main posts (not comments/replies)  
**Method:** `GET`  
**URL:** `/community/users/posts`

**Query Parameters:**
- `user_id` (UUID, optional): User ID to get posts for. If not provided, gets current user's posts
- `page` (int, optional): Page number (default: 1)
- `page_size` (int, optional): Items per page (default: 20, max: 100)

**Example:**
```bash
# Get current user's main posts
GET /community/users/posts?page=1&page_size=20

# Get specific user's main posts
GET /community/users/posts?user_id=7c42f706-59cc-4535-b120-2030a2e2377c&page=1&page_size=20
```

**Response:** Same structure as posts feed response

---

### 18. Get Current User's Comment Posts

**Purpose:** Retrieve the current user's comment posts (replies to other posts)  
**Method:** `GET`  
**URL:** `/community/users/posts/comments`

**Query Parameters:**
- `user_id` (UUID, optional): User ID to get comment posts for. If not provided, gets current user's comment posts
- `page` (int, optional): Page number (default: 1)
- `page_size` (int, optional): Items per page (default: 20, max: 100)

**Example:**
```bash
# Get current user's comment posts
GET /community/users/posts/comments?page=1&page_size=20

# Get specific user's comment posts
GET /community/users/posts/comments?user_id=7c42f706-59cc-4535-b120-2030a2e2377c&page=1&page_size=20
```

**Response:** Same structure as posts feed response

---

### 19. Get Specific User's Main Posts

**Purpose:** Retrieve a specific user's main posts using path parameter  
**Method:** `GET`  
**URL:** `/community/users/posts/{user_id}`

**Query Parameters:**
- `page` (int, optional): Page number (default: 1)
- `page_size` (int, optional): Items per page (default: 20, max: 100)

**Example:**
```bash
GET /community/users/posts/7c42f706-59cc-4535-b120-2030a2e2377c?page=1&page_size=20
```

**Response:** Same structure as posts feed response

---

### 20. Get Specific User's Comment Posts

**Purpose:** Retrieve a specific user's comment posts using path parameter  
**Method:** `GET`  
**URL:** `/community/users/posts/{user_id}/comments`

**Query Parameters:**
- `page` (int, optional): Page number (default: 1)
- `page_size` (int, optional): Items per page (default: 20, max: 100)

**Example:**
```bash
GET /community/users/posts/7c42f706-59cc-4535-b120-2030a2e2377c/comments?page=1&page_size=20
```

**Response:** Same structure as posts feed response

---

## 👤 Profile Management

### 21. Create Community Profile

**Purpose:** Create a community profile for the current user  
**Method:** `POST`  
**URL:** `/community/profiles`

**Request Body:**
```json
{
  "username": "tech_expert_2024",
  "bio": "Senior Full-Stack Developer | React & Node.js Specialist | Open Source Contributor\n\n🚀 Building scalable web applications\n📚 Teaching & mentoring developers\n🔗 Links: github.com/techexpert",
  "profile_image_url": "https://gravatar.com/avatar/professional_headshot.jpg",
  "banner_image_url": "https://images.example.com/tech_workspace_banner.jpg",
  "is_private": false
}
```

**Response:**
```json
{
  "success": true,
  "message": "Profile created successfully",
  "status_code": 201,
  "data": {
    "id": "88f1692f-fd33-43e6-98c0-8264d6a9c418",
    "user_id": "7c42f706-59cc-4535-b120-2030a2e2377c",
    "tenant_id": null,
    "username": "tech_expert_2024",
    "bio": "Senior Full-Stack Developer | React & Node.js Specialist...",
    "profile_image_url": "https://gravatar.com/avatar/professional_headshot.jpg",
    "banner_image_url": "https://images.example.com/tech_workspace_banner.jpg",
    "is_private": false,
    "is_verified": false,
    "followers_count": 0,
    "following_count": 0,
    "posts_count": 0,
    "settings": null,
    "created_at": "2025-09-08T08:54:00Z",
    "updated_at": null
  }
}
```

---

### 22. Get User Profile

**Purpose:** Retrieve a user's community profile  
**Method:** `GET`  
**URL:** `/community/profiles/{user_id}`

**Example:**
```bash
GET /community/profiles/7c42f706-59cc-4535-b120-2030a2e2377c
```

**Response:** Same as profile creation response

---

### 23. Get My Profile

**Purpose:** Retrieve current user's community profile  
**Method:** `GET`  
**URL:** `/community/profiles`

**Response:** Same as profile creation response

---

### 24. Update Profile

**Purpose:** Update current user's community profile (partial updates allowed)  
**Method:** `PUT`  
**URL:** `/community/profiles`

**Request Body (All fields optional):**
```json
{
  "username": "updated_tech_expert",
  "bio": "🚀 Senior Full-Stack Developer | React & Node.js Expert\n📍 San Francisco, CA\n💡 10+ years building scalable applications",
  "profile_image_url": "https://cdn.example.com/avatars/new_profile_pic.jpg",
  "banner_image_url": "https://cdn.example.com/banners/updated_banner.jpg",
  "is_private": false,
  "settings": {
    "notifications_enabled": true,
    "email_notifications": false,
    "theme": "dark",
    "language": "en"
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "status_code": 200,
  "data": {
    "id": "88f1692f-fd33-43e6-98c0-8264d6a9c418",
    "username": "updated_tech_expert",
    "bio": "🚀 Senior Full-Stack Developer | React & Node.js Expert...",
    "updated_at": "2025-09-08T11:15:00Z"
  }
}
```

---

## 👥 Social Features

### 25. Follow User

**Purpose:** Follow another user  
**Method:** `POST`  
**URL:** `/community/follow`

**Request Body:**
```json
{
  "user_id": "7c42f706-59cc-4535-b120-2030a2e2377c"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully followed user",
  "status_code": 200,
  "data": {
    "is_following": true,
    "message": "Successfully followed user"
  }
}
```

---

### 26. Unfollow User

**Purpose:** Unfollow a user  
**Method:** `DELETE`  
**URL:** `/community/follow/{user_id}`

**Example:**
```bash
DELETE /community/follow/7c42f706-59cc-4535-b120-2030a2e2377c
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully unfollowed user",
  "status_code": 200,
  "data": {
    "is_following": false,
    "message": "Successfully unfollowed user"
  }
}
```

---

### 27. Get Followers

**Purpose:** Get list of users following a specific user  
**Method:** `GET`  
**URL:** `/community/users/{user_id}/followers`

**Query Parameters:**
- `page` (int, optional): Page number (default: 1)
- `page_size` (int, optional): Items per page (default: 20, max: 100)

**Example:**
```bash
GET /community/users/7c42f706-59cc-4535-b120-2030a2e2377c/followers?page=1&page_size=25
```

**Response:**
```json
{
  "success": true,
  "message": "Followers retrieved successfully",
  "status_code": 200,
  "data": {
    "users": [
      {
        "id": "follower-profile-id",
        "username": "follower_user",
        "profile_image_url": "https://cdn.example.com/avatars/follower.jpg",
        "is_verified": false,
        "followers_count": 150,
        "created_at": "2025-09-07T15:30:00Z"
      }
    ],
    "total": 342,
    "page": 1,
    "page_size": 25,
    "has_more": true
  }
}
```

---

### 28. Get Following

**Purpose:** Get list of users that a specific user is following  
**Method:** `GET`  
**URL:** `/community/users/{user_id}/following`

**Query Parameters:** Same as followers

**Response:** Same structure as followers response

---

### 29. Check Follow Status

**Purpose:** Check if current user is following a specific user  
**Method:** `GET`  
**URL:** `/community/follow/status/{user_id}`

**Example:**
```bash
GET /community/follow/status/7c42f706-59cc-4535-b120-2030a2e2377c
```

**Response:**
```json
{
  "success": true,
  "message": "Follow status retrieved successfully",
  "status_code": 200,
  "data": {
    "is_following": true
  }
}
```

---

## 🚫 Block Management

### 30. Block User

**Purpose:** Block another user to prevent them from interacting with your content  
**Method:** `POST`  
**URL:** `/community/block`

**Request Body:**
```json
{
  "user_id": "7c42f706-59cc-4535-b120-2030a2e2377c",
  "reason": "Inappropriate behavior"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User blocked successfully",
  "status_code": 200,
  "data": {
    "is_blocked": true,
    "message": "User blocked successfully"
  }
}
```

---

### 31. Unblock User

**Purpose:** Unblock a previously blocked user  
**Method:** `DELETE`  
**URL:** `/community/block/{user_id}`

**Example:**
```bash
DELETE /community/block/7c42f706-59cc-4535-b120-2030a2e2377c
```

**Response:**
```json
{
  "success": true,
  "message": "User unblocked successfully",
  "status_code": 200,
  "data": {
    "is_blocked": false,
    "message": "User unblocked successfully"
  }
}
```

---

### 32. Get Blocked Users List

**Purpose:** Retrieve list of users that current user has blocked  
**Method:** `GET`  
**URL:** `/community/blocks`

**Query Parameters:**
- `page` (int, optional): Page number (default: 1)
- `page_size` (int, optional): Items per page (default: 20, max: 100)

**Example:**
```bash
GET /community/blocks?page=1&page_size=20
```

**Response:**
```json
{
  "success": true,
  "message": "Blocked users retrieved successfully",
  "status_code": 200,
  "data": {
    "blocked_users": [
      {
        "id": "block-record-id",
        "blocked_user_id": "7c42f706-59cc-4535-b120-2030a2e2377c",
        "username": "blocked_user",
        "profile_image_url": "https://cdn.example.com/avatars/blocked_user.jpg",
        "reason": "Inappropriate behavior",
        "blocked_at": "2025-09-08T10:30:00Z"
      }
    ],
    "total": 5,
    "page": 1,
    "page_size": 20,
    "has_more": false
  }
}
```

---

### 33. Check Block Status

**Purpose:** Check if current user has blocked a specific user  
**Method:** `GET`  
**URL:** `/community/block/status/{user_id}`

**Example:**
```bash
GET /community/block/status/7c42f706-59cc-4535-b120-2030a2e2377c
```

**Response:**
```json
{
  "success": true,
  "message": "Block status retrieved successfully",
  "status_code": 200,
  "data": {
    "is_blocked": true
  }
}
```

---

## 📊 Response Format

All API responses follow a consistent format:

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "status_code": 200,
  "data": { /* Response data */ },
  "timestamp": "2025-09-08T10:30:00.000000+00:00"
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description",
  "status_code": 400,
  "data": {},
  "errors": [
    {
      "code": "validation_error",
      "message": "Detailed error message",
      "field": "field_name"
    }
  ],
  "timestamp": "2025-09-08T10:30:00.000000+00:00"
}
```

---

## ⚠️ Error Handling

### Common HTTP Status Codes

- **200** - Success
- **201** - Created
- **400** - Bad Request (validation errors)
- **401** - Unauthorized (invalid/missing JWT token)
- **403** - Forbidden (insufficient permissions)
- **404** - Not Found (resource doesn't exist)
- **409** - Conflict (duplicate username, etc.)
- **422** - Unprocessable Entity (validation errors)
- **500** - Internal Server Error

### Common Error Scenarios

#### Authentication Errors
```json
{
  "success": false,
  "message": "User with ID abc123 not found in database",
  "status_code": 404
}
```

#### Validation Errors
```json
{
  "success": false,
  "message": "Post content cannot be empty",
  "status_code": 400
}
```

#### Permission Errors
```json
{
  "success": false,
  "message": "You can only edit your own posts",
  "status_code": 403
}
```

#### Duplicate Data Errors
```json
{
  "success": false,
  "message": "Username already exists",
  "status_code": 409
}
```

---

## 🚀 Quick Start Guide

1. **Authentication**: Obtain JWT token from auth endpoints
2. **Create Profile**: `POST /community/profiles`
3. **Create Posts**: `POST /community/posts`
4. **Follow Users**: `POST /community/follow`
5. **Engage**: Like posts and leave comments
6. **Browse**: Use feeds to discover content

---

## 📝 Notes for Frontend Developers

- All timestamps are in ISO 8601 format with UTC timezone
- UUIDs are returned as strings in JSON responses
- Pagination uses `page` and `page_size` parameters consistently
- All list responses include `total`, `has_more` metadata
- Like functionality is toggle-based (same endpoint for like/unlike)
- Comments are treated as posts with `parent_post_id`
- Profile creation is required before posting or following
- Username must be unique across all community profiles
- Content fields support markdown and emojis
- File uploads should be handled separately, URLs stored in profile fields

---

## 🛠️ Development Notes

- Base URL: `http://localhost:8000/api/v1/community`
- All endpoints require JWT authentication
- Rate limiting may be applied per endpoint
- Soft delete is used for posts (is_deleted flag)
- Real-time counters are automatically maintained
- Pagination is optimized for large datasets
- Database indexes are optimized for common queries

---

*Last Updated: September 8, 2025*
