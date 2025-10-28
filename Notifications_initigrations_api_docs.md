1. Get ALL Notifications (No Filter)
Request:

GET /api/v1/community/notifications
Response:

{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "type": "like",
        "is_read": false,
        "created_at": "2025-10-24T09:30:00",
        "actor": {
          "id": "123e4567-e89b-12d3-a456-426614174000",
          "full_name": "John Doe",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/john.jpg"
        },
        "post": {
          "id": "987e6543-e21b-12d3-a456-426614174000",
          "content": "Amazing sunset at the beach!"
        }
      },
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "type": "reply",
        "is_read": false,
        "created_at": "2025-10-24T09:25:00",
        "actor": {
          "id": "234e5678-e89b-12d3-a456-426614174001",
          "full_name": "Jane Smith",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/jane.jpg"
        },
        "post": {
          "id": "876e5432-e21b-12d3-a456-426614174001",
          "content": "Love this photo!"
        }
      },
      {
        "id": "770e8400-e29b-41d4-a716-446655440002",
        "type": "follow",
        "is_read": true,
        "created_at": "2025-10-24T09:20:00",
        "actor": {
          "id": "345e6789-e89b-12d3-a456-426614174002",
          "full_name": "Mike Johnson",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/mike.jpg"
        },
        "post": null
      },
      {
        "id": "880e8400-e29b-41d4-a716-446655440003",
        "type": "mention",
        "is_read": false,
        "created_at": "2025-10-24T09:15:00",
        "actor": {
          "id": "456e7890-e89b-12d3-a456-426614174003",
          "full_name": "Sarah Williams",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/sarah.jpg"
        },
        "post": {
          "id": "765e4321-e21b-12d3-a456-426614174002",
          "content": "Hey @username, check this out!"
        }
      }
    ],
    "total_count": 45,
    "unread_count": 12,
    "limit": 20,
    "offset": 0,
    "filter_type": null
  }
}
2. Get ONLY LIKE Notifications
Request:

GET /api/v1/community/notifications?type=like
Response:

{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "type": "like",
        "is_read": false,
        "created_at": "2025-10-24T09:30:00",
        "actor": {
          "id": "123e4567-e89b-12d3-a456-426614174000",
          "full_name": "John Doe",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/john.jpg"
        },
        "post": {
          "id": "987e6543-e21b-12d3-a456-426614174000",
          "content": "Amazing sunset at the beach!"
        }
      },
      {
        "id": "551e8400-e29b-41d4-a716-446655440004",
        "type": "like",
        "is_read": true,
        "created_at": "2025-10-24T08:45:00",
        "actor": {
          "id": "567e8901-e89b-12d3-a456-426614174004",
          "full_name": "Emily Davis",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/emily.jpg"
        },
        "post": {
          "id": "654e3210-e21b-12d3-a456-426614174003",
          "content": "Just finished my morning run!"
        }
      }
    ],
    "total_count": 15,
    "unread_count": 12,
    "limit": 20,
    "offset": 0,
    "filter_type": "like"
  }
}
3. Get ONLY REPLY/COMMENT Notifications
Request:

GET /api/v1/community/notifications?type=reply
Response:

{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "type": "reply",
        "is_read": false,
        "created_at": "2025-10-24T09:25:00",
        "actor": {
          "id": "234e5678-e89b-12d3-a456-426614174001",
          "full_name": "Jane Smith",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/jane.jpg"
        },
        "post": {
          "id": "876e5432-e21b-12d3-a456-426614174001",
          "content": "Love this photo!"
        }
      },
      {
        "id": "661e8400-e29b-41d4-a716-446655440005",
        "type": "reply",
        "is_read": true,
        "created_at": "2025-10-24T08:30:00",
        "actor": {
          "id": "678e9012-e89b-12d3-a456-426614174005",
          "full_name": "Robert Brown",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/robert.jpg"
        },
        "post": {
          "id": "543e2109-e21b-12d3-a456-426614174004",
          "content": "Great point! I totally agree."
        }
      }
    ],
    "total_count": 8,
    "unread_count": 12,
    "limit": 20,
    "offset": 0,
    "filter_type": "reply"
  }
}
4. Get ONLY MENTION Notifications
Request:

GET /api/v1/community/notifications?type=mention
Response:

{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "880e8400-e29b-41d4-a716-446655440003",
        "type": "mention",
        "is_read": false,
        "created_at": "2025-10-24T09:15:00",
        "actor": {
          "id": "456e7890-e89b-12d3-a456-426614174003",
          "full_name": "Sarah Williams",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/sarah.jpg"
        },
        "post": {
          "id": "765e4321-e21b-12d3-a456-426614174002",
          "content": "Hey @username, check this out!"
        }
      }
    ],
    "total_count": 3,
    "unread_count": 12,
    "limit": 20,
    "offset": 0,
    "filter_type": "mention"
  }
}
5. Get ONLY FOLLOW Notifications
Request:

GET /api/v1/community/notifications?type=follow
Response:

{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "770e8400-e29b-41d4-a716-446655440002",
        "type": "follow",
        "is_read": true,
        "created_at": "2025-10-24T09:20:00",
        "actor": {
          "id": "345e6789-e89b-12d3-a456-426614174002",
          "full_name": "Mike Johnson",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/mike.jpg"
        },
        "post": null
      },
      {
        "id": "771e8400-e29b-41d4-a716-446655440006",
        "type": "follow",
        "is_read": false,
        "created_at": "2025-10-24T08:00:00",
        "actor": {
          "id": "789e0123-e89b-12d3-a456-426614174006",
          "full_name": "Lisa Anderson",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/lisa.jpg"
        },
        "post": null
      }
    ],
    "total_count": 12,
    "unread_count": 12,
    "limit": 20,
    "offset": 0,
    "filter_type": "follow"
  }
}
6. Get ONLY FOLLOW REQUEST Notifications
Request:

GET /api/v1/community/notifications?type=follow_request
Response:

{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "990e8400-e29b-41d4-a716-446655440007",
        "type": "follow_request",
        "is_read": false,
        "created_at": "2025-10-24T07:45:00",
        "actor": {
          "id": "890e1234-e89b-12d3-a456-426614174007",
          "full_name": "David Martinez",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/david.jpg"
        },
        "post": null
      }
    ],
    "total_count": 5,
    "unread_count": 12,
    "limit": 20,
    "offset": 0,
    "filter_type": "follow_request"
  }
}
7. Get ONLY FOLLOW REQUEST ACCEPTED Notifications
Request:

GET /api/v1/community/notifications?type=follow_request_accepted
Response:

{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "aa0e8400-e29b-41d4-a716-446655440008",
        "type": "follow_request_accepted",
        "is_read": true,
        "created_at": "2025-10-24T07:30:00",
        "actor": {
          "id": "901e2345-e89b-12d3-a456-426614174008",
          "full_name": "Jennifer Garcia",
          "profile_picture_url": "https://s3.amazonaws.com/profiles/jennifer.jpg"
        },
        "post": null
      }
    ],
    "total_count": 2,
    "unread_count": 12,
    "limit": 20,
    "offset": 0,
    "filter_type": "follow_request_accepted"
  }
}
8. Error Response - Invalid Type
Request:

GET /api/v1/community/notifications?type=invalid_type
Response:

{
  "success": false,
  "message": "Invalid notification type. Valid types are: like, reply, mention, follow, follow_request, follow_request_accepted",
  "status_code": 400
}
9. Empty Result (No Notifications of That Type)
Request:

GET /api/v1/community/notifications?type=mention
Response:

{
  "success": true,
  "data": {
    "notifications": [],
    "total_count": 0,
    "unread_count": 12,
    "limit": 20,
    "offset": 0,
    "filter_type": "mention"
  }
}