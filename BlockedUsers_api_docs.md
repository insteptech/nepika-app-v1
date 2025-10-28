# Blocked Users API Documentation

This documentation provides detailed information about the Blocked Users endpoint for frontend developers.

---

## Get Blocked Users List

Retrieve a paginated list of all users that the current user has blocked.

### Endpoint
```
GET /api/v1/community/blocks
```

### Authentication
- **Required**: Yes
- **Type**: Bearer Token
- **Header**: `Authorization: Bearer <your_access_token>`

### Query Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 1 | Page number (must be ≥ 1) |
| `page_size` | integer | No | 20 | Number of users per page (1-100) |

---

## Request Example

```bash
GET /api/v1/community/blocks?page=1&page_size=20
Headers:
  Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Response Format

### Success Response (200 OK)

```json
{
  "success": true,
  "message": "Blocked users retrieved successfully",
  "status_code": 200,
  "data": {
    "users": [
      {
        "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "username": "john_doe",
        "profile_image_url": "https://nepika-bucket.s3.amazonaws.com/profile-pictures/550e8400-e29b-41d4-a716-446655440000/profile.webp?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=...",
        "created_at": "2025-10-20T14:30:00"
      },
      {
        "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
        "user_id": "660e9511-f30c-52e5-b827-557766551111",
        "username": "jane_smith",
        "profile_image_url": null,
        "created_at": "2025-10-18T09:15:00"
      }
    ],
    "total": 45,
    "page": 1,
    "page_size": 20,
    "has_more": true
  },
  "errors": [],
  "timestamp": "2025-10-24T12:00:00+00:00"
}
```

### Empty Response (No Blocked Users)

```json
{
  "success": true,
  "message": "Blocked users retrieved successfully",
  "status_code": 200,
  "data": {
    "users": [],
    "total": 0,
    "page": 1,
    "page_size": 20,
    "has_more": false
  },
  "errors": [],
  "timestamp": "2025-10-24T12:00:00+00:00"
}
```

### Error Response (500 Internal Server Error)

```json
{
  "success": false,
  "message": "Failed to retrieve blocked users",
  "status_code": 500,
  "data": {},
  "errors": [],
  "timestamp": "2025-10-24T12:00:00+00:00"
}
```

### Unauthorized Response (401)

```json
{
  "detail": "Token is invalid or expired"
}
```

---

## Response Fields

### `data` Object

| Field | Type | Description |
|-------|------|-------------|
| `users` | array | List of blocked user objects |
| `total` | integer | Total number of blocked users across all pages |
| `page` | integer | Current page number |
| `page_size` | integer | Number of users per page |
| `has_more` | boolean | Whether there are more pages available |

### `users[]` Object (Blocked User)

| Field | Type | Description |
|-------|------|-------------|
| `id` | string (UUID) | Block record ID |
| `user_id` | string (UUID) | ID of the blocked user |
| `username` | string \| null | Username of the blocked user (null if no community profile) |
| `profile_image_url` | string \| null | **Presigned S3 URL** of profile picture (null if no image) |
| `created_at` | string (ISO 8601) | When the user was blocked (e.g., "2025-10-20T14:30:00") |

---

## Pagination Examples

### Page 1 (First 20 blocked users)
```bash
GET /api/v1/community/blocks?page=1&page_size=20
```

### Page 2 (Next 20 blocked users)
```bash
GET /api/v1/community/blocks?page=2&page_size=20
```

### Custom page size (10 users per page)
```bash
GET /api/v1/community/blocks?page=1&page_size=10
```

### Pagination Logic

```javascript
// Calculate total pages
const totalPages = Math.ceil(data.total / data.page_size);

// Check if there's a next page
const hasNextPage = data.has_more;

// Check if there's a previous page
const hasPrevPage = data.page > 1;

// Calculate current range
const startItem = (data.page - 1) * data.page_size + 1;
const endItem = Math.min(data.page * data.page_size, data.total);
// Example: "Showing 21-40 of 45"
```

---

## Important Notes

### 1. **Presigned URLs**
- The `profile_image_url` is a **presigned S3 URL**
- **Expires after 1 hour**
- Cache it temporarily, but refresh if needed
- Can be used directly in `<img>` tags or image widgets

### 2. **Null Values**
- `username` can be `null` if the user hasn't set up their community profile
- `profile_image_url` is `null` if the user has no profile picture
- Always handle these null cases in your UI

### 3. **Empty State**
- When `users` array is empty and `total` is 0, show an empty state message
- Example: "You haven't blocked any users yet"

### 4. **Performance**
- Recommended `page_size`: 20 (default)
- Maximum `page_size`: 100
- Use pagination for better performance with large lists

---

## Frontend Integration Examples

### React/JavaScript

```javascript
async function getBlockedUsers(page = 1, pageSize = 20) {
  try {
    const response = await fetch(
      `https://api.nepika.com/api/v1/community/blocks?page=${page}&page_size=${pageSize}`,
      {
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        }
      }
    );

    if (!response.ok) {
      throw new Error('Failed to fetch blocked users');
    }

    const result = await response.json();

    if (result.success) {
      const { users, total, page, page_size, has_more } = result.data;

      console.log(`Showing ${users.length} of ${total} blocked users`);
      console.log(`Current page: ${page}`);
      console.log(`Has more: ${has_more}`);

      return result.data;
    } else {
      console.error('Error:', result.message);
      return null;
    }
  } catch (error) {
    console.error('Error fetching blocked users:', error);
    return null;
  }
}

// Usage
const blockedData = await getBlockedUsers(1, 20);
if (blockedData) {
  blockedData.users.forEach(user => {
    console.log(`Username: ${user.username || 'Unknown'}`);
    console.log(`Profile: ${user.profile_image_url || 'No image'}`);
    console.log(`Blocked on: ${user.created_at}`);
  });
}
```

### React Component Example

```jsx
import React, { useState, useEffect } from 'react';

function BlockedUsersList() {
  const [blockedUsers, setBlockedUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [hasMore, setHasMore] = useState(false);
  const [total, setTotal] = useState(0);

  useEffect(() => {
    fetchBlockedUsers();
  }, [page]);

  const fetchBlockedUsers = async () => {
    setLoading(true);
    try {
      const response = await fetch(
        `https://api.nepika.com/api/v1/community/blocks?page=${page}&page_size=20`,
        {
          headers: {
            'Authorization': `Bearer ${localStorage.getItem('token')}`,
            'Content-Type': 'application/json'
          }
        }
      );

      const result = await response.json();

      if (result.success) {
        setBlockedUsers(result.data.users);
        setHasMore(result.data.has_more);
        setTotal(result.data.total);
      }
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div>Loading blocked users...</div>;
  }

  if (blockedUsers.length === 0) {
    return <div>You haven't blocked any users yet.</div>;
  }

  return (
    <div>
      <h2>Blocked Users ({total})</h2>

      <div className="blocked-users-list">
        {blockedUsers.map(user => (
          <div key={user.id} className="blocked-user-item">
            {user.profile_image_url ? (
              <img src={user.profile_image_url} alt={user.username} />
            ) : (
              <div className="placeholder-avatar">No Image</div>
            )}
            <div>
              <p>{user.username || 'Unknown User'}</p>
              <small>Blocked on {new Date(user.created_at).toLocaleDateString()}</small>
            </div>
          </div>
        ))}
      </div>

      <div className="pagination">
        <button
          onClick={() => setPage(p => p - 1)}
          disabled={page === 1}
        >
          Previous
        </button>

        <span>Page {page}</span>

        <button
          onClick={() => setPage(p => p + 1)}
          disabled={!hasMore}
        >
          Next
        </button>
      </div>
    </div>
  );
}

export default BlockedUsersList;
```

### Flutter/Dart

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class BlockedUser {
  final String id;
  final String userId;
  final String? username;
  final String? profileImageUrl;
  final DateTime createdAt;

  BlockedUser({
    required this.id,
    required this.userId,
    this.username,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      id: json['id'],
      userId: json['user_id'],
      username: json['username'],
      profileImageUrl: json['profile_image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class BlockedUsersResponse {
  final List<BlockedUser> users;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  BlockedUsersResponse({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory BlockedUsersResponse.fromJson(Map<String, dynamic> json) {
    return BlockedUsersResponse(
      users: (json['users'] as List)
          .map((user) => BlockedUser.fromJson(user))
          .toList(),
      total: json['total'],
      page: json['page'],
      pageSize: json['page_size'],
      hasMore: json['has_more'],
    );
  }
}

Future<BlockedUsersResponse?> getBlockedUsers({
  int page = 1,
  int pageSize = 20,
  required String accessToken,
}) async {
  try {
    final response = await http.get(
      Uri.parse('https://api.nepika.com/api/v1/community/blocks?page=$page&page_size=$pageSize'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);

      if (result['success'] == true) {
        return BlockedUsersResponse.fromJson(result['data']);
      }
    } else if (response.statusCode == 401) {
      print('Unauthorized: Token invalid or expired');
    } else {
      print('Error: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching blocked users: $e');
  }
  return null;
}

// Usage example
void fetchAndDisplayBlockedUsers() async {
  final data = await getBlockedUsers(
    page: 1,
    pageSize: 20,
    accessToken: 'your_access_token',
  );

  if (data != null) {
    print('Total blocked users: ${data.total}');
    print('Current page: ${data.page}');
    print('Has more: ${data.hasMore}');

    for (var user in data.users) {
      print('Username: ${user.username ?? 'Unknown'}');
      print('Profile: ${user.profileImageUrl ?? 'No image'}');
      print('Blocked on: ${user.createdAt}');
    }
  }
}
```

### Flutter Widget Example

```dart
import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatefulWidget {
  @override
  _BlockedUsersScreenState createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<BlockedUser> blockedUsers = [];
  bool isLoading = true;
  int currentPage = 1;
  int total = 0;
  bool hasMore = false;

  @override
  void initState() {
    super.initState();
    fetchBlockedUsers();
  }

  Future<void> fetchBlockedUsers() async {
    setState(() => isLoading = true);

    final data = await getBlockedUsers(
      page: currentPage,
      pageSize: 20,
      accessToken: 'your_token',
    );

    if (data != null) {
      setState(() {
        blockedUsers = data.users;
        total = data.total;
        hasMore = data.hasMore;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (blockedUsers.isEmpty) {
      return Center(
        child: Text('You haven\'t blocked any users yet.'),
      );
    }

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('Blocked Users ($total)', style: TextStyle(fontSize: 20)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: blockedUsers.length,
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return ListTile(
                leading: user.profileImageUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(user.profileImageUrl!),
                      )
                    : CircleAvatar(child: Icon(Icons.person)),
                title: Text(user.username ?? 'Unknown User'),
                subtitle: Text('Blocked on ${user.createdAt.toLocal()}'),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: currentPage > 1
                  ? () {
                      setState(() => currentPage--);
                      fetchBlockedUsers();
                    }
                  : null,
              child: Text('Previous'),
            ),
            Text('Page $currentPage'),
            ElevatedButton(
              onPressed: hasMore
                  ? () {
                      setState(() => currentPage++);
                      fetchBlockedUsers();
                    }
                  : null,
              child: Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Common HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 401 | Unauthorized | Missing or invalid authentication token |
| 500 | Internal Server Error | Server error (contact support if persists) |

---

## Testing Tips

1. **First, block some users** using `POST /api/v1/community/block` endpoint

2. **Test pagination**:
   - Block 25+ users
   - Test with `page_size=10`
   - Navigate through pages

3. **Test edge cases**:
   - Empty state (no blocked users)
   - Users with no profile picture
   - Users with no username

4. **Test presigned URLs**:
   - Verify images load correctly
   - Test URL expiration (after 1 hour)

---

## Related Endpoints

### Block a User
```
POST /api/v1/community/block
Body: { "user_id": "550e8400-e29b-41d4-a716-446655440000" }
```

### Unblock a User
```
DELETE /api/v1/community/block/{user_id}
```

### Check Block Status
```
GET /api/v1/community/block/status/{user_id}
```

---

## Support

For questions or issues:
- **Email**: dev@nepika.com
- **Documentation**: https://docs.nepika.com
- **API Status**: https://status.nepika.com

---

**Last Updated**: October 24, 2025
**API Version**: v1
**Base URL**: `https://api.nepika.com` or `https://your-ngrok-url.ngrok-free.app`