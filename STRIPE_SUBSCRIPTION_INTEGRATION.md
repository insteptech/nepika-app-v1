# Stripe Subscription Integration Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Backend Setup](#backend-setup)
4. [API Endpoints](#api-endpoints)
5. [Frontend Integration](#frontend-integration)
6. [Testing Guide](#testing-guide)
7. [Production Deployment](#production-deployment)
8. [Troubleshooting](#troubleshooting)

---

## Overview

This document provides a comprehensive guide for integrating the Stripe subscription module into your Flutter frontend application. The backend provides a complete REST API for managing user subscriptions with two plans: **Free** and **Premium**.

### Subscription Plans

| Plan | Price (Monthly) | Price (Yearly) | Features |
|------|----------------|----------------|----------|
| **Free** | $0.00 | $0.00 | Basic features |
| **Premium** | $6.99/month | $60.00/year | All features unlocked |

### Stripe Configuration

- **Monthly Price ID**: `price_1SLe3b9GE4oycUj8rjX69Us8`
- **Yearly Price ID**: `price_1SLe5L9GE4oycUj8Mck7oPgW`
- **Publishable Key**: Available via `/api/v1/payments/config` endpoint

---

## Architecture

### System Flow

```
┌─────────────────┐
│  Flutter App    │
│  (Frontend)     │
└────────┬────────┘
         │
         │ 1. Request checkout session
         ▼
┌─────────────────┐
│   FastAPI       │
│   Backend       │◄──────── 4. Webhook events
└────────┬────────┘         (subscription updates)
         │                         │
         │ 2. Create              │
         │    checkout            │
         ▼    session             │
┌─────────────────┐               │
│     Stripe      │               │
│     Checkout    │───────────────┘
└────────┬────────┘
         │
         │ 3. User completes payment
         ▼
┌─────────────────┐
│   Payment       │
│   Success       │
└─────────────────┘
```

### Database Schema

#### Subscriptions Table
```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key → users.id)
- plan (ENUM: 'free', 'premium')
- interval (ENUM: 'monthly', 'yearly', NULL for free)
- stripe_customer_id (String, Nullable)
- stripe_subscription_id (String, Nullable)
- status (ENUM: 'active', 'canceled', 'incomplete', 'past_due', etc.)
- current_period_start (DateTime, Nullable)
- current_period_end (DateTime, Nullable)
- cancel_at_period_end (Boolean, Default: false)
- canceled_at (DateTime, Nullable)
- created_at (DateTime)
- updated_at (DateTime, Nullable)
```

#### Payments Table
```sql
- id (UUID, Primary Key)
- user_id (UUID, Foreign Key → users.id)
- subscription_id (UUID, Foreign Key → subscriptions.id)
- amount (Decimal)
- currency (String, Default: 'usd')
- stripe_payment_intent_id (String, Nullable)
- stripe_invoice_id (String, Nullable)
- stripe_charge_id (String, Nullable)
- status (ENUM: 'pending', 'succeeded', 'failed', 'refunded', 'canceled')
- failure_code (String, Nullable)
- failure_message (String, Nullable)
- description (String, Nullable)
- receipt_url (String, Nullable)
- paid_at (DateTime, Nullable)
- created_at (DateTime)
- updated_at (DateTime, Nullable)
```

---

## Backend Setup

### Environment Variables

The backend requires the following environment variables in `.env`:

```env
# Stripe Configuration
# Frontend URL (for redirects after payment)
# For Flutter apps, use deep link scheme (e.g., nepika://subscription)
# For web apps, use full URL (e.g., https://yourdomain.com)
# IMPORTANT: Must include scheme (http://, https://, or custom scheme like nepika://)
FRONTEND_URL=nepika://subscription

# Price IDs
STRIPE_PREMIUM_MONTHLY_PRICE_ID=price_1SLe3b9GE4oycUj8rjX69Us8
STRIPE_PREMIUM_YEARLY_PRICE_ID=price_1SLe5L9GE4oycUj8Mck7oPgW
```

**Important Notes:**
- `STRIPE_WEBHOOK_SECRET`: Get this from Stripe CLI (`stripe listen`) for local development, or from Stripe Dashboard for production
- `FRONTEND_URL`: Must include a valid URL scheme (http://, https://, or custom deep link scheme)
- For local development, you can use `http://localhost:8000` as a placeholder

### Installation

1. Install dependencies:
```bash
pip install stripe==11.2.0
```

2. Run database migrations:
```bash
alembic upgrade head
```

3. Start the backend server:
```bash
uvicorn app.main:app --reload --port 8000
```

4. Start Stripe CLI for webhook forwarding (development only):
```bash
stripe listen --forward-to localhost:8000/api/v1/payments/webhook
```

---

## API Endpoints

### Base URL
```
http://localhost:8000/api/v1/payments
```

All endpoints require authentication via JWT token in the `Authorization` header:
```
Authorization: Bearer <your_jwt_token>
```

---

### 1. Get Stripe Configuration

**Endpoint**: `GET /payments/config`

**Authentication**: Not required (public endpoint)

**Description**: Get Stripe publishable key and price IDs for frontend integration.

**Response**:
```json
{
  "success": true,
  "message": "Stripe configuration retrieved successfully",
  "data": {
    "publishable_key": "pk_test_51SLdrA9GE4oycUj8FAO2gQPPhqYf250IeBwy4JZc9U6EntFKQw6EfDdRHl16vAr2vMiphDQhsFOTRf8RnBVMDvL800OnDeZxyd",
    "monthly_price_id": "price_1SLe3b9GE4oycUj8rjX69Us8",
    "yearly_price_id": "price_1SLe5L9GE4oycUj8Mck7oPgW",
    "monthly_price": "$6.99",
    "yearly_price": "$60.00"
  }
}
```

---

### 2. Get Subscription Status

**Endpoint**: `GET /payments/subscription/status`

**Authentication**: Required

**Description**: Get current user's subscription status.

**Response**:
```json
{
  "success": true,
  "message": "Subscription status retrieved successfully",
  "data": {
    "has_premium": true,
    "plan": "premium",
    "status": "active",
    "interval": "monthly",
    "current_period_end": "2024-02-01T00:00:00",
    "cancel_at_period_end": false
  }
}
```

**Status Values**:
- `active`: Subscription is active
- `canceled`: Subscription has been canceled
- `incomplete`: Payment pending
- `past_due`: Payment failed, retrying
- `trialing`: In trial period
- `unpaid`: Payment failed, no more retries

---

### 3. Get Full Subscription Details

**Endpoint**: `GET /payments/subscription`

**Authentication**: Required

**Description**: Get detailed subscription information.

**Response**:
```json
{
  "success": true,
  "message": "Subscription retrieved successfully",
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "123e4567-e89b-12d3-a456-426614174001",
    "plan": "premium",
    "interval": "monthly",
    "status": "active",
    "stripe_customer_id": "cus_xxxxxxxxxxxxx",
    "stripe_subscription_id": "sub_xxxxxxxxxxxxx",
    "current_period_start": "2024-01-01T00:00:00",
    "current_period_end": "2024-02-01T00:00:00",
    "cancel_at_period_end": false,
    "canceled_at": null,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
}
```

---

### 4. Create Checkout Session

**Endpoint**: `POST /payments/create-checkout-session`

**Authentication**: Required

**Description**: Create a Stripe Checkout session for subscription upgrade.

**Request Body**:
```json
{
  "price_id": "price_1SLe3b9GE4oycUj8rjX69Us8",
  "interval": "monthly",
  "success_url": "nepika://subscription/success",  // Optional
  "cancel_url": "nepika://subscription/cancel"      // Optional
}
```

**Request Parameters**:
- `price_id` (required): Stripe price ID (monthly or yearly)
- `interval` (required): `"monthly"` or `"yearly"`
- `success_url` (optional): Custom URL to redirect after successful payment
- `cancel_url` (optional): Custom URL to redirect if payment is canceled

**Response**:
```json
{
  "success": true,
  "message": "Checkout session created successfully",
  "data": {
    "checkout_url": "https://checkout.stripe.com/c/pay/cs_test_xxxxxxxxxxxxx",
    "session_id": "cs_test_xxxxxxxxxxxxx"
  }
}
```

**Error Response** (400):
```json
{
  "success": false,
  "message": "Invalid price_id or interval",
  "data": null,
  "status_code": 400
}
```

**Error Response** (500):
```json
{
  "success": false,
  "message": "Payment provider error: <error details>",
  "data": null,
  "status_code": 500
}
```

---

### 5. Cancel Subscription

**Endpoint**: `POST /payments/subscription/cancel`

**Authentication**: Required

**Description**: Cancel user's subscription.

**Request Body**:
```json
{
  "cancel_immediately": false
}
```

**Request Parameters**:
- `cancel_immediately` (optional, default: false):
  - `false`: Cancel at end of billing period (user keeps premium access until then)
  - `true`: Cancel immediately (user loses premium access now)

**Response**:
```json
{
  "success": true,
  "message": "Subscription will cancel at end of billing period",
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "plan": "premium",
    "status": "active",
    "cancel_at_period_end": true,
    "current_period_end": "2024-02-01T00:00:00"
  }
}
```

**Error Response** (400):
```json
{
  "success": false,
  "message": "No active Stripe subscription found",
  "data": null,
  "status_code": 400
}
```

---

### 6. Reactivate Subscription

**Endpoint**: `POST /payments/subscription/reactivate`

**Authentication**: Required

**Description**: Reactivate a subscription that was set to cancel at period end.

**Request Body**: None

**Response**:
```json
{
  "success": true,
  "message": "Subscription reactivated successfully",
  "data": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "plan": "premium",
    "status": "active",
    "cancel_at_period_end": false,
    "current_period_end": "2024-02-01T00:00:00"
  }
}
```

**Error Response** (400):
```json
{
  "success": false,
  "message": "Subscription is not set to cancel",
  "data": null,
  "status_code": 400
}
```

---

### 7. Webhook Endpoint (Internal)

**Endpoint**: `POST /payments/webhook`

**Authentication**: Stripe signature verification

**Description**: Receive webhook events from Stripe. This endpoint is called by Stripe's servers, not by your frontend.

**Supported Events**:
- `checkout.session.completed`: Subscription purchase completed
- `customer.subscription.created`: New subscription created
- `customer.subscription.updated`: Subscription status changed
- `customer.subscription.deleted`: Subscription canceled/expired
- `invoice.payment_succeeded`: Payment successful
- `invoice.payment_failed`: Payment failed
- `payment_intent.succeeded`: One-time payment successful
- `payment_intent.payment_failed`: One-time payment failed

---

## Frontend Integration

### Flutter Package Requirements

Add these packages to your `pubspec.yaml`:

```yaml
dependencies:
  http: ^1.1.0
  url_launcher: ^6.2.0
  flutter_secure_storage: ^9.0.0  # For storing auth tokens
```

### Step-by-Step Integration

---

#### Step 1: Setup HTTP Client

Create a service class for API calls:

```dart
// lib/services/subscription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubscriptionService {
  static const String baseUrl = 'http://localhost:8000/api/v1/payments';
  final storage = FlutterSecureStorage();

  // Get auth token from secure storage
  Future<String?> _getAuthToken() async {
    return await storage.read(key: 'auth_token');
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Get Stripe configuration
  Future<Map<String, dynamic>> getStripeConfig() async {
    final response = await http.get(
      Uri.parse('$baseUrl/config'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load Stripe config');
    }
  }

  // 2. Get subscription status
  Future<Map<String, dynamic>> getSubscriptionStatus() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/subscription/status'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load subscription status');
    }
  }

  // 3. Get full subscription details
  Future<Map<String, dynamic>> getSubscription() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/subscription'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      throw Exception('Failed to load subscription');
    }
  }

  // 4. Create checkout session
  Future<Map<String, dynamic>> createCheckoutSession({
    required String priceId,
    required String interval, // 'monthly' or 'yearly'
    String? successUrl,
    String? cancelUrl,
  }) async {
    final headers = await _getHeaders();
    final body = {
      'price_id': priceId,
      'interval': interval,
      if (successUrl != null) 'success_url': successUrl,
      if (cancelUrl != null) 'cancel_url': cancelUrl,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/create-checkout-session'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to create checkout session');
    }
  }

  // 5. Cancel subscription
  Future<Map<String, dynamic>> cancelSubscription({
    bool cancelImmediately = false,
  }) async {
    final headers = await _getHeaders();
    final body = {
      'cancel_immediately': cancelImmediately,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/subscription/cancel'),
      headers: headers,
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to cancel subscription');
    }
  }

  // 6. Reactivate subscription
  Future<Map<String, dynamic>> reactivateSubscription() async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/subscription/reactivate'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'];
    } else {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Failed to reactivate subscription');
    }
  }
}
```

---

#### Step 2: Create Subscription Model

```dart
// lib/models/subscription.dart

class SubscriptionStatus {
  final bool hasPremium;
  final String plan; // 'free' or 'premium'
  final String status; // 'active', 'canceled', etc.
  final String? interval; // 'monthly', 'yearly', or null
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  SubscriptionStatus({
    required this.hasPremium,
    required this.plan,
    required this.status,
    this.interval,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      hasPremium: json['has_premium'],
      plan: json['plan'],
      status: json['status'],
      interval: json['interval'],
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : null,
      cancelAtPeriodEnd: json['cancel_at_period_end'],
    );
  }
}

class StripeConfig {
  final String publishableKey;
  final String monthlyPriceId;
  final String yearlyPriceId;
  final String monthlyPrice;
  final String yearlyPrice;

  StripeConfig({
    required this.publishableKey,
    required this.monthlyPriceId,
    required this.yearlyPriceId,
    required this.monthlyPrice,
    required this.yearlyPrice,
  });

  factory StripeConfig.fromJson(Map<String, dynamic> json) {
    return StripeConfig(
      publishableKey: json['publishable_key'],
      monthlyPriceId: json['monthly_price_id'],
      yearlyPriceId: json['yearly_price_id'],
      monthlyPrice: json['monthly_price'],
      yearlyPrice: json['yearly_price'],
    );
  }
}
```

---

#### Step 3: Create Subscription Screen

```dart
// lib/screens/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/subscription_service.dart';
import '../models/subscription.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _service = SubscriptionService();

  SubscriptionStatus? _status;
  StripeConfig? _config;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final configData = await _service.getStripeConfig();
      final statusData = await _service.getSubscriptionStatus();

      setState(() {
        _config = StripeConfig.fromJson(configData);
        _status = SubscriptionStatus.fromJson(statusData);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _upgradeToPremium(String interval) async {
    if (_config == null) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Get price ID based on interval
      final priceId = interval == 'monthly'
          ? _config!.monthlyPriceId
          : _config!.yearlyPriceId;

      // Create checkout session
      final result = await _service.createCheckoutSession(
        priceId: priceId,
        interval: interval,
        successUrl: 'nepika://subscription/success',
        cancelUrl: 'nepika://subscription/cancel',
      );

      // Close loading dialog
      Navigator.pop(context);

      // Launch Stripe Checkout in browser
      final checkoutUrl = result['checkout_url'];
      if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
        await launchUrl(
          Uri.parse(checkoutUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch checkout URL');
      }
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _cancelSubscription() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Subscription'),
        content: Text(
          'Are you sure you want to cancel your subscription? '
          'You will retain premium access until the end of your billing period.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      await _service.cancelSubscription(cancelImmediately: false);

      // Close loading dialog
      Navigator.pop(context);

      // Reload data
      await _loadData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription will cancel at end of billing period'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _reactivateSubscription() async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      await _service.reactivateSubscription();

      // Close loading dialog
      Navigator.pop(context);

      // Reload data
      await _loadData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription reactivated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Subscription')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Subscription')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Status Card
            _buildStatusCard(),
            SizedBox(height: 24),

            // Show upgrade options if user is on free plan
            if (_status?.plan == 'free') ...[
              Text(
                'Upgrade to Premium',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 16),
              _buildPricingCard('monthly'),
              SizedBox(height: 16),
              _buildPricingCard('yearly'),
            ],

            // Show cancel/reactivate options if user has premium
            if (_status?.plan == 'premium') ...[
              if (_status?.cancelAtPeriodEnd == true)
                ElevatedButton(
                  onPressed: _reactivateSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.all(16),
                  ),
                  child: Text('Reactivate Subscription'),
                )
              else
                OutlinedButton(
                  onPressed: _cancelSubscription,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.all(16),
                  ),
                  child: Text('Cancel Subscription'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isPremium = _status?.hasPremium ?? false;

    return Card(
      color: isPremium ? Colors.amber.shade50 : Colors.grey.shade100,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPremium ? Icons.star : Icons.person,
                  color: isPremium ? Colors.amber : Colors.grey,
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  isPremium ? 'Premium Plan' : 'Free Plan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            if (isPremium) ...[
              SizedBox(height: 12),
              Text('Status: ${_status?.status}'),
              Text('Billing: ${_status?.interval}'),
              if (_status?.currentPeriodEnd != null)
                Text(
                  'Renews: ${_status!.currentPeriodEnd!.toLocal().toString().split(' ')[0]}',
                ),
              if (_status?.cancelAtPeriodEnd == true)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠️ Subscription will cancel at end of billing period',
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricingCard(String interval) {
    if (_config == null) return SizedBox();

    final isMonthly = interval == 'monthly';
    final price = isMonthly ? _config!.monthlyPrice : _config!.yearlyPrice;
    final pricePerMonth = isMonthly ? price : '\$5.00'; // $60/12 = $5/month

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMonthly ? 'Monthly' : 'Yearly',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 4),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isMonthly)
                      Text(
                        '$pricePerMonth per month',
                        style: TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
                if (!isMonthly)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Save 29%',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _upgradeToPremium(interval),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Subscribe ${isMonthly ? "Monthly" : "Yearly"}'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

#### Step 4: Handle Deep Links (Optional)

If you want to handle the redirect back to your app after payment, set up deep linking:

##### Android Configuration

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<activity
    android:name=".MainActivity"
    ...>
    <!-- Existing intent filters -->

    <!-- Deep link for subscription -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="nepika"
            android:host="subscription" />
    </intent-filter>
</activity>
```

##### iOS Configuration

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourapp.nepika</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>nepika</string>
        </array>
    </dict>
</array>
```

##### Handle Deep Link in Flutter

```dart
// In your main.dart or app.dart

import 'package:uni_links/uni_links.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.scheme == 'nepika') {
        if (uri.host == 'subscription') {
          if (uri.path == '/success') {
            // Payment successful - refresh subscription status
            Navigator.pushNamed(context, '/subscription');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Subscription activated successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (uri.path == '/cancel') {
            // Payment canceled
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment was canceled')),
            );
          }
        }
      }
    }, onError: (err) {
      // Handle error
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Your app configuration
    );
  }
}
```

---

#### Step 5: Check Premium Status for Feature Gating

```dart
// lib/utils/premium_check.dart

import '../services/subscription_service.dart';

class PremiumCheck {
  static final SubscriptionService _service = SubscriptionService();

  static Future<bool> hasPremiumAccess() async {
    try {
      final status = await _service.getSubscriptionStatus();
      return status['has_premium'] == true;
    } catch (e) {
      return false; // Default to no access on error
    }
  }

  static Widget premiumFeature({
    required Widget child,
    required Widget premiumPrompt,
  }) {
    return FutureBuilder<bool>(
      future: hasPremiumAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == true) {
          return child; // Show premium feature
        } else {
          return premiumPrompt; // Show upgrade prompt
        }
      },
    );
  }
}

// Usage example:
Widget myFeature() {
  return PremiumCheck.premiumFeature(
    child: MyPremiumFeature(),
    premiumPrompt: Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.lock, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('This is a premium feature'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/subscription');
              },
              child: Text('Upgrade to Premium'),
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

## Testing Guide

### Local Testing with Stripe CLI

1. **Start your backend server**:
```bash
uvicorn app.main:app --reload --port 8000
```

2. **Start Stripe CLI webhook forwarding**:
```bash
stripe listen --forward-to localhost:8000/api/v1/payments/webhook
```

3. **Run your Flutter app** (connected to localhost backend)

4. **Test the subscription flow**:
   - Open subscription screen in app
   - Click "Subscribe Monthly" or "Subscribe Yearly"
   - Complete payment using Stripe test card numbers

### Stripe Test Card Numbers

| Card Number | Description |
|------------|-------------|
| `4242 4242 4242 4242` | Successful payment |
| `4000 0025 0000 3155` | Requires authentication (3D Secure) |
| `4000 0000 0000 9995` | Payment declined |
| `4000 0000 0000 0341` | Charge succeeds but domestic card |

**Test Card Details**:
- **Expiry**: Any future date (e.g., `12/34`)
- **CVC**: Any 3 digits (e.g., `123`)
- **ZIP**: Any 5 digits (e.g., `12345`)

### Test Webhook Events

You can manually trigger webhook events using Stripe CLI:

```bash
# Test successful checkout
stripe trigger checkout.session.completed

# Test subscription updated
stripe trigger customer.subscription.updated

# Test payment succeeded
stripe trigger invoice.payment_succeeded

# Test payment failed
stripe trigger invoice.payment_failed
```

### Testing Checklist

- [ ] User can view subscription status
- [ ] User can upgrade to monthly premium
- [ ] User can upgrade to yearly premium
- [ ] Payment redirects to Stripe Checkout
- [ ] Successful payment updates subscription in database
- [ ] User sees premium features after upgrade
- [ ] User can cancel subscription (at period end)
- [ ] User can reactivate canceled subscription
- [ ] Webhooks properly update subscription status
- [ ] Failed payments are recorded correctly

---

## Production Deployment

### Backend Configuration

1. **Update environment variables for production**:
```env
# Use production Stripe keys
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxx
STRIPE_PREMIUM_MONTHLY_PRICE_ID=price_xxxxxxxxxxxxx  # Production price ID
STRIPE_PREMIUM_YEARLY_PRICE_ID=price_xxxxxxxxxxxxx   # Production price ID

# Production frontend URL (deep link or web URL)
FRONTEND_URL=https://yourapp.com/subscription
```

2. **Configure webhook endpoint in Stripe Dashboard**:
   - Go to: https://dashboard.stripe.com/webhooks
   - Add endpoint: `https://your-api-domain.com/api/v1/payments/webhook`
   - Select all subscription and payment events
   - Copy the webhook signing secret
   - Update `STRIPE_WEBHOOK_SECRET` in production environment

3. **Deploy backend to production server**

### Frontend Configuration

1. **Update API base URL** in `SubscriptionService`:
```dart
static const String baseUrl = 'https://your-api-domain.com/api/v1/payments';
```

2. **Configure deep links** for production app

3. **Test with production Stripe account** (use real card or test mode in production dashboard)

### Security Checklist

- [ ] All API endpoints require authentication
- [ ] Webhook signature verification is enabled
- [ ] HTTPS is enabled for all API calls
- [ ] Environment variables are properly secured
- [ ] Database is backed up regularly
- [ ] Rate limiting is configured
- [ ] CORS is properly configured

---

## Troubleshooting

### Common Issues

#### 1. "Payment provider error" when creating checkout session

**Cause**: Invalid Stripe API key or price ID

**Solution**:
- Verify `STRIPE_SECRET_KEY` in `.env`
- Verify price IDs match your Stripe dashboard
- Check if you're using test keys with test price IDs

#### 2. Webhook events returning 500 errors

**Cause**: Webhook handler encountering errors during processing

**Solution**:
- Check backend logs for detailed error messages
- Common causes:
  - Missing subscription records in database
  - Invalid data in webhook payload
  - Database connection issues
- The webhook handler now returns 200 even if processing fails to prevent Stripe retries
- Check logs for `"Error handling [event_type]"` messages

#### 3. "Invalid URL" error when creating checkout session

**Cause**: `FRONTEND_URL` in `.env` doesn't have a valid URL scheme

**Solution**:
- Ensure `FRONTEND_URL` includes a scheme:
  - ✅ Good: `http://localhost:8000`, `https://yourdomain.com`, `nepika://subscription`
  - ❌ Bad: `localhost:8000`, `yourdomain.com`, `subscription`
- Update `.env`:
  ```env
  # For Flutter app with deep links
  FRONTEND_URL=nepika://subscription

  # For web app
  FRONTEND_URL=https://yourdomain.com

  # For local testing
  FRONTEND_URL=http://localhost:8000
  ```

#### 4. Webhook events not received

**Cause**: Webhook secret mismatch or incorrect URL

**Solution**:
- For local testing: Make sure Stripe CLI is running: `stripe listen --forward-to localhost:8000/api/v1/payments/webhook`
- For production: Verify webhook URL in Stripe dashboard matches your deployed API
- Verify `STRIPE_WEBHOOK_SECRET` matches the one from Stripe
- You should see `[200]` responses in Stripe CLI, not `[500]`

#### 5. "No active Stripe subscription found" when canceling

**Cause**: User doesn't have an active subscription or webhook hasn't processed yet

**Solution**:
- Wait a few seconds after payment for webhooks to process
- Check subscription status: `GET /api/v1/payments/subscription`
- Check backend logs for webhook processing errors

#### 6. Subscription status not updating after payment

**Cause**: Webhook event not processed or failed

**Solution**:
- Check backend logs for webhook errors
- Verify webhook signature verification is working
- Test webhook manually: `stripe trigger checkout.session.completed`
- Check database to see if subscription record exists
- Ensure webhooks are returning `[200]` in Stripe CLI terminal

#### 7. Deep link not working after payment

**Cause**: Deep link not properly configured in app

**Solution**:
- Verify `AndroidManifest.xml` has correct intent filter
- Verify `Info.plist` has correct URL scheme
- Test deep link manually: `adb shell am start -W -a android.intent.action.VIEW -d "nepika://subscription/success"`

### Debug Mode

Enable debug logging in backend by setting:
```env
DEBUG=True
LOG_LEVEL=DEBUG
```

Check logs for detailed error messages:
- Stripe API errors
- Webhook processing errors
- Database errors

### Support Resources

- **Stripe API Documentation**: https://stripe.com/docs/api
- **Stripe Testing Guide**: https://stripe.com/docs/testing
- **Stripe CLI Documentation**: https://stripe.com/docs/stripe-cli
- **Flutter url_launcher**: https://pub.dev/packages/url_launcher

---

## API Response Codes

| Status Code | Meaning |
|------------|---------|
| 200 | Success |
| 400 | Bad Request (invalid parameters) |
| 401 | Unauthorized (missing or invalid auth token) |
| 404 | Not Found |
| 500 | Internal Server Error (Stripe API error or database error) |

---

## Appendix

### Subscription Lifecycle

```
Free User
    │
    ├─→ Creates checkout session
    │   └─→ Redirects to Stripe Checkout
    │       ├─→ Completes payment
    │       │   └─→ checkout.session.completed webhook
    │       │       └─→ Subscription activated (Premium)
    │       │
    │       └─→ Cancels payment
    │           └─→ Remains Free
    │
Premium User
    │
    ├─→ Recurring payment succeeds
    │   └─→ invoice.payment_succeeded webhook
    │       └─→ Subscription continues
    │
    ├─→ Recurring payment fails
    │   └─→ invoice.payment_failed webhook
    │       └─→ Status: past_due → retries → unpaid → canceled
    │
    ├─→ Cancels subscription (at period end)
    │   └─→ cancel_at_period_end = true
    │       └─→ Still has premium until period ends
    │           └─→ customer.subscription.deleted webhook
    │               └─→ Downgraded to Free
    │
    └─→ Cancels subscription (immediately)
        └─→ customer.subscription.deleted webhook
            └─→ Immediately downgraded to Free
```

### Database Queries

**Check if user has premium access**:
```sql
SELECT * FROM subscriptions
WHERE user_id = 'user_uuid'
  AND plan = 'premium'
  AND status IN ('active', 'trialing');
```

**Get all premium users**:
```sql
SELECT u.* FROM users u
JOIN subscriptions s ON u.id = s.user_id
WHERE s.plan = 'premium' AND s.status = 'active';
```

**Get subscriptions expiring soon**:
```sql
SELECT * FROM subscriptions
WHERE status = 'active'
  AND current_period_end < NOW() + INTERVAL '7 days';
```

---

## Changelog

### Version 1.0.1 (2025-10-24)
- **Fixed**: Webhook handler now returns 200 for all events (prevents 500 errors)
- **Fixed**: URL scheme validation for checkout session creation
- **Improved**: Error handling and logging for webhook events
- **Improved**: Graceful handling of unhandled webhook events
- **Updated**: Environment variable documentation for FRONTEND_URL
- **Added**: Troubleshooting section for common webhook issues

### Version 1.0.0 (2024-01-15)
- Initial implementation
- Support for Free and Premium plans
- Monthly and Yearly billing intervals
- Stripe Checkout integration
- Webhook event handling
- Subscription cancellation and reactivation
- Payment history tracking

---

## License

This integration is proprietary to Nepika AI. All rights reserved.

---

## Contact

For questions or support regarding this integration, contact:
- Backend Team: backend@nepika.ai
- Frontend Team: frontend@nepika.ai
- Documentation Issues: docs@nepika.ai
