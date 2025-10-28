# Subscription Payment API Documentation

Complete API reference for subscription payment integration using Stripe Checkout.

---

## Table of Contents

1. [Get Subscription Plans](#1-get-subscription-plans)
2. [Get Stripe Configuration](#2-get-stripe-configuration)
3. [Create Checkout Session](#3-create-checkout-session)
4. [Get Subscription Status](#4-get-subscription-status)
5. [Get Subscription Details](#5-get-subscription-details)
6. [Cancel Subscription](#6-cancel-subscription)
7. [Reactivate Subscription](#7-reactivate-subscription)
8. [Webhook Configuration](#8-webhook-configuration)

---

## 1. Get Subscription Plans

Retrieves all available subscription plans.

**Endpoint:** `GET /api/v1/payments/plans`

**Authentication:** Not required (public endpoint)

**Response:**
```json
{
  "success": true,
  "message": "Subscription plans retrieved successfully",
  "data": {
    "plans": [
      {
        "id": "uuid",
        "name": "Nepika Premium",
        "plan_code": "nepika_premium_monthly",
        "duration": "monthly",
        "price": 6.99,
        "currency": "USD",
        "stripe_price_id": "price_1SLe3b9GE4oycUj8rjX69Us8",
        "plan_details": [
          "Unlimited face scans per month",
          "Detailed skin analysis across all 9 parameters",
          "Advanced AI recommendations"
        ],
        "description": "Premium monthly subscription",
        "is_active": "true",
        "display_order": "1"
      },
      {
        "id": "uuid",
        "name": "Nepika Premium Yearly",
        "plan_code": "nepika_premium_yearly",
        "duration": "yearly",
        "price": 60.00,
        "currency": "USD",
        "stripe_price_id": "price_1SLe3c9GE4oycUj8rjX69Us9",
        "plan_details": [
          "Unlimited face scans per month",
          "Detailed skin analysis across all 9 parameters",
          "Advanced AI recommendations",
          "Save 28% compared to monthly"
        ],
        "description": "Premium yearly subscription",
        "is_active": "true",
        "display_order": "2"
      }
    ],
    "total": 2
  }
}
```

---

## 2. Get Stripe Configuration

Retrieves Stripe publishable key and price information.

**Endpoint:** `GET /api/v1/payments/config`

**Authentication:** Not required (public endpoint)

**Response:**
```json
{
  "success": true,
  "message": "Stripe configuration retrieved successfully",
  "data": {
    "publishable_key": "pk_test_xxxxxxxxxxxxx",
    "monthly_price_id": "price_1SLe3b9GE4oycUj8rjX69Us8",
    "yearly_price_id": "price_1SLe3c9GE4oycUj8rjX69Us9",
    "monthly_price": "$6.99",
    "yearly_price": "$60.00"
  }
}
```

---

## 3. Create Checkout Session

Creates a Stripe Checkout session and returns URL for payment.

**Endpoint:** `POST /api/v1/payments/create-checkout-session`

**Authentication:** Required - `Authorization: Bearer <access_token>`

**Request Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "price_id": "price_1SLe3b9GE4oycUj8rjX69Us8",
  "interval": "monthly"
}
```

**Parameters:**
- `price_id` (string, required): Stripe price ID from `/plans` endpoint
- `interval` (string, required): Either "monthly" or "yearly"

**Success Response (200):**
```json
{
  "success": true,
  "message": "Checkout session created successfully",
  "data": {
    "session_id": "cs_test_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    "url": "https://checkout.stripe.com/c/pay/cs_test_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
    "publishable_key": "pk_test_xxxxxxxxxxxxx"
  }
}
```

**Error Response (404):**
```json
{
  "success": false,
  "message": "User not found",
  "data": null
}
```

**Error Response (500):**
```json
{
  "success": false,
  "message": "Failed to create checkout session: <error details>",
  "data": null
}
```

**Usage:**
1. Call this endpoint to get checkout URL
2. Redirect user to the `url` in the response
3. User completes payment on Stripe's hosted page
4. Stripe redirects back to your success/cancel URL
5. Webhook activates subscription automatically

---

## 4. Get Subscription Status

Retrieves simplified subscription status for current user.

**Endpoint:** `GET /api/v1/payments/subscription/status`

**Authentication:** Required - `Authorization: Bearer <access_token>`

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Subscription status retrieved successfully",
  "data": {
    "has_premium": true,
    "plan": "premium",
    "status": "active",
    "interval": "monthly",
    "current_period_end": "2024-03-01T00:00:00",
    "cancel_at_period_end": false
  }
}
```

**Status Values:**
- `active` - Subscription is active
- `canceled` - Subscription has been canceled
- `incomplete` - Payment not yet completed
- `past_due` - Payment failed, awaiting retry
- `trialing` - In trial period
- `unpaid` - Payment failed after retries

---

## 5. Get Subscription Details

Retrieves complete subscription information.

**Endpoint:** `GET /api/v1/payments/subscription`

**Authentication:** Required - `Authorization: Bearer <access_token>`

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Subscription retrieved successfully",
  "data": {
    "id": "uuid",
    "user_id": "user-uuid",
    "plan": "premium",
    "interval": "monthly",
    "status": "active",
    "stripe_customer_id": "cus_xxxxxxxxxxxxx",
    "stripe_subscription_id": "sub_xxxxxxxxxxxxx",
    "current_period_start": "2024-02-01T00:00:00",
    "current_period_end": "2024-03-01T00:00:00",
    "cancel_at_period_end": false,
    "canceled_at": null,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-02-01T00:00:00"
  }
}
```

---

## 6. Cancel Subscription

Cancels the user's subscription.

**Endpoint:** `POST /api/v1/payments/subscription/cancel`

**Authentication:** Required - `Authorization: Bearer <access_token>`

**Request Headers:**
```
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "cancel_immediately": false
}
```

**Parameters:**
- `cancel_immediately` (boolean, optional):
  - `false` (default): Cancel at period end, user keeps access
  - `true`: Cancel immediately, user loses access now

**Success Response - Cancel at Period End (200):**
```json
{
  "success": true,
  "message": "Subscription will cancel at end of billing period",
  "data": {
    "id": "uuid",
    "status": "active",
    "cancel_at_period_end": true,
    "current_period_end": "2024-03-01T00:00:00"
  }
}
```

**Success Response - Cancel Immediately (200):**
```json
{
  "success": true,
  "message": "Subscription canceled immediately",
  "data": {
    "id": "uuid",
    "status": "canceled",
    "cancel_at_period_end": false,
    "canceled_at": "2024-02-15T10:30:00"
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "No active Stripe subscription found",
  "data": null
}
```

---

## 7. Reactivate Subscription

Reactivates a subscription that was set to cancel at period end.

**Endpoint:** `POST /api/v1/payments/subscription/reactivate`

**Authentication:** Required - `Authorization: Bearer <access_token>`

**Request Headers:**
```
Authorization: Bearer <access_token>
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Subscription reactivated successfully",
  "data": {
    "id": "uuid",
    "status": "active",
    "cancel_at_period_end": false,
    "current_period_end": "2024-03-01T00:00:00"
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Subscription is not set to cancel",
  "data": null
}
```

---

## 8. Webhook Configuration

The API uses webhooks to receive real-time updates from Stripe about subscription events.

**Webhook Endpoint:** `POST /api/v1/payments/webhook`

**This endpoint is called by Stripe, not your frontend.**

### Required Environment Variables

Add these to your backend `.env` file:

```env
# Stripe Keys
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx

# Stripe Price IDs
STRIPE_PREMIUM_MONTHLY_PRICE_ID=price_1SLe3b9GE4oycUj8rjX69Us8
STRIPE_PREMIUM_YEARLY_PRICE_ID=price_1SLe3c9GE4oycUj8rjX69Us9

# Frontend URL (for Checkout redirects)
FRONTEND_URL=https://your-frontend-domain.com
```

### Stripe Dashboard Setup

1. **Go to:** [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks)

2. **Click:** "Add endpoint"

3. **Enter Webhook URL:**
   ```
   https://your-backend-domain.com/api/v1/payments/webhook
   ```

4. **Select Events to Listen For:**
   - ⭐ `checkout.session.completed` (CRITICAL - creates subscription)
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_succeeded`
   - `invoice.payment_failed`

5. **Copy Signing Secret:**
   - Click "Reveal" next to "Signing secret"
   - Copy the value (starts with `whsec_`)

6. **Add to Environment:**
   ```env
   STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
   ```

7. **Restart Backend Server**

### ⚠️ Critical Notes

- **`checkout.session.completed` is REQUIRED** - Without this webhook, subscriptions will NOT be created after payment
- Webhook URL must be publicly accessible (not `localhost` in production)
- Use Stripe CLI for local development testing
- Always verify webhook signature for security

### Testing Webhooks Locally

```bash
# Install Stripe CLI
# Mac: brew install stripe/stripe-cli/stripe
# Windows: scoop install stripe

# Login
stripe login

# Forward webhooks to local server
stripe listen --forward-to localhost:8000/api/v1/payments/webhook

# In another terminal, trigger test events
stripe trigger checkout.session.completed
```

---

## Response Format

All endpoints follow this standard format:

```json
{
  "success": true | false,
  "message": "Human-readable message",
  "data": { ... } | null
}
```

**HTTP Status Codes:**
- `200` - Success
- `400` - Bad request / Validation error
- `404` - Resource not found
- `500` - Server error

---

## Common Workflow

### Subscribe User

1. **GET** `/plans` - Display available plans
2. **POST** `/create-checkout-session` - Get payment URL
3. Redirect user to Stripe Checkout URL
4. User completes payment on Stripe
5. Stripe sends `checkout.session.completed` webhook
6. Backend creates subscription automatically
7. **GET** `/subscription/status` - Verify activation

### Check Access

```
GET /subscription/status
```
Use `has_premium` field to control feature access.

### Cancel Subscription

```
POST /subscription/cancel
Body: { "cancel_immediately": false }
```

### Reactivate Before Period End

```
POST /subscription/reactivate
```

---