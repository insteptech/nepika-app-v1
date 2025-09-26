
# Community Profile Management API Documentation

## Base URL
All endpoints are prefixed with:

```

/api/v1/community

````

---

## 1. Profile Management

### Create Community Profile
- **Endpoint:** `POST /profiles`  
- **Method:** `POST`  
- **Authentication:** Required (Bearer token)  
- **Description:** Create a new community profile for the current user  

**Request Body:**
```json
{
  "username": "string (optional, 3-50 chars)",
  "bio": "string (optional, max 500 chars)",
  "profile_image_url": "string (optional)",
  "banner_image_url": "string (optional)",
  "is_private": "boolean (default: false)"
}
````

**Response:**

```json
{
  "success": true,
  "message": "Profile created successfully",
  "data": {
    "id": "uuid",
    "user_id": "uuid",
    "tenant_id": "uuid or null",
    "username": "string or null",
    "bio": "string or null",
    "profile_image_url": "string or null",
    "banner_image_url": "string or null",
    "is_private": "boolean",
    "is_verified": "boolean",
    "followers_count": "integer",
    "following_count": "integer",
    "posts_count": "integer",
    "settings": "object or null",
    "created_at": "datetime",
    "updated_at": "datetime or null"
  }
}
```

---

### Get My Profile

* **Endpoint:** `GET /profiles`
* **Method:** `GET`
* **Authentication:** Required (Bearer token)
* **Description:** Retrieve current user's community profile

**Response:** Same as Create Profile response

---

### Get Any User's Profile

* **Endpoint:** `GET /profiles/{user_id}`
* **Method:** `GET`
* **Authentication:** Required (Bearer token)
* **Description:** Retrieve any user's community profile by user ID

**Path Parameters:**

* `user_id`: UUID of the user

**Response:** Same as Create Profile response

---

### Update Profile

* **Endpoint:** `PUT /profiles`
* **Method:** `PUT`
* **Authentication:** Required (Bearer token)
* **Description:** Update current user's community profile information

**Request Body:**

```json
{
  "username": "string (optional, 3-50 chars)",
  "bio": "string (optional, max 500 chars)",
  "profile_image_url": "string (optional)",
  "banner_image_url": "string (optional)",
  "is_private": "boolean (optional)",
  "settings": "object (optional)"
}
```

**Response:** Same as Create Profile response

---

## 2. Image Upload Management

### Generate Secure Image URL

* **Endpoint:** `GET /images/secure-url`
* **Method:** `GET`
* **Authentication:** Required (Bearer token)
* **Description:** Generate secure presigned URL for accessing stored images

**Query Parameters:**

* `s3_url`: S3 URL in format `s3://bucket/key` (required)
* `expires_in`: URL expiration time in seconds (default: 3600, max: 86400)

**Response:**

```json
{
  "success": true,
  "message": "Secure URL generated successfully",
  "data": {
    "secure_url": "string",
    "expires_in": "integer",
    "original_s3_url": "string"
  }
}
```

---

## 3. Follow/Unfollow Management

### Follow a User

* **Endpoint:** `POST /follow`
* **Method:** `POST`
* **Authentication:** Required (Bearer token + Community profile)
* **Description:** Follow another user

**Request Body:**

```json
{
  "user_id": "uuid"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Successfully followed user" | "Already following user",
  "data": {
    "is_following": "boolean",
    "message": "string"
  }
}
```

---

### Unfollow a User

* **Endpoint:** `DELETE /follow/{user_id}`
* **Method:** `DELETE`
* **Authentication:** Required (Bearer token + Community profile)
* **Description:** Unfollow a user

**Path Parameters:**

* `user_id`: UUID of the user to unfollow

**Response:**

```json
{
  "success": true,
  "message": "Successfully unfollowed user" | "Not following user",
  "data": {
    "is_following": "boolean",
    "message": "string"
  }
}
```

---

### Check Follow Status

* **Endpoint:** `GET /follow/status/{user_id}`
* **Method:** `GET`
* **Authentication:** Required (Bearer token)
* **Description:** Check if current user is following another user

**Path Parameters:**

* `user_id`: UUID of the user to check follow status

**Response:**

```json
{
  "success": true,
  "message": "Follow status retrieved successfully",
  "data": {
    "is_following": "boolean"
  }
}
```

---

### Get User's Followers

* **Endpoint:** `GET /users/{user_id}/followers`
* **Method:** `GET`
* **Authentication:** Required (Bearer token)
* **Description:** Get list of users following a specific user

**Path Parameters:**

* `user_id`: UUID of the user

**Query Parameters:**

* `page`: Page number (default: 1)
* `page_size`: Number of followers per page (default: 20, max: 100)

**Response:**

```json
{
  "success": true,
  "message": "Followers retrieved successfully",
  "data": {
    "users": [
      {
        "id": "uuid",
        "username": "string or null",
        "profile_image_url": "string or null",
        "is_verified": "boolean",
        "followers_count": "integer",
        "created_at": "datetime"
      }
    ],
    "total": "integer",
    "page": "integer",
    "page_size": "integer",
    "has_more": "boolean"
  }
}
```

---

### Get User's Following

* **Endpoint:** `GET /users/{user_id}/following`
* **Method:** `GET`
* **Authentication:** Required (Bearer token)
* **Description:** Get list of users that a specific user is following

**Path Parameters:**

* `user_id`: UUID of the user

**Query Parameters:**

* `page`: Page number (default: 1)
* `page_size`: Number of following per page (default: 20, max: 100)

**Response:** Same as Get User's Followers response

---

## 4. Additional Features

### Search Users

* **Endpoint:** `GET /search/users`
* **Method:** `GET`
* **Authentication:** Required (Bearer token)
* **Description:** Search for users by username

**Query Parameters:**

* `q`: Search query (required, 1-50 chars)
* `page`: Page number (default: 1)
* `page_size`: Number of users per page (default: 10, max: 10)

**Response:**

```json
{
  "success": true,
  "message": "User search completed successfully",
  "data": {
    "users": [
      {
        "id": "uuid",
        "username": "string or null",
        "profile_image_url": "string or null",
        "is_verified": "boolean",
        "followers_count": "integer",
        "created_at": "datetime"
      }
    ],
    "total": "integer",
    "page": "integer",
    "page_size": "integer",
    "has_more": "boolean"
  }
}
```

---

## Image Upload Process

Since there's no direct image upload endpoint in the community controller, images are typically uploaded using the profile picture upload utility. The process:

1. **Upload Image:** Use a multipart form upload to upload profile/banner images
2. **Get S3 URL:** The upload returns an S3 URL
3. **Update Profile:** Use `PUT /profiles` to save the S3 URL to `profile_image_url` or `banner_image_url`
4. **Access Images:** Use `GET /images/secure-url` to generate secure URLs for viewing

---

## Error Responses

All endpoints return standardized error responses:

```json
{
  "success": false,
  "message": "Error description",
  "status_code": 400|401|403|404|409|500
}
```

**Common HTTP Status Codes:**

* `400`: Bad Request (validation errors)
* `401`: Unauthorized (invalid/missing token)
* `403`: Forbidden (insufficient permissions)
* `404`: Not Found (resource doesn't exist)
* `409`: Conflict (duplicate data, e.g., username already taken)
* `500`: Internal Server Error

---

## Authentication Notes

* All endpoints require Bearer token authentication
* Follow/unfollow endpoints require the user to have a community profile created
* The `require_community_profile` dependency ensures the user has created their community profile before performing certain actions