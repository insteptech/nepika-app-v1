# NEPIKA In-App Purchase Testing Guide

## SETUP REQUIRED BEFORE TESTING

### 🔧 Phase 1: Complete Platform Configuration
✅ iOS entitlements added
✅ Android billing permission added
⚠️ **Still needed**: Store configuration (see Phase 2)

### 🏪 Phase 2: Store Setup (REQUIRED FOR TESTING)

#### iOS App Store Connect:
1. **Create Products** (REQUIRED before any testing):
   - Navigate to App Store Connect → Nepika → Features → In-App Purchases
   - Create products: `nepika_weekly_subscription` and `nepika_yearly_subscription`
   - Submit for review (required for sandbox testing)

2. **Sandbox Testing Account**:
   - Create sandbox user: `test.nepika@icloud.com`
   - Use this account for all iOS testing

#### Android Google Play Console:
1. **Create Subscriptions**:
   - Navigate to Play Console → Nepika → Monetize → Products → Subscriptions
   - Create: `nepika_weekly_subscription` and `nepika_yearly_subscription`
   
2. **Upload to Internal Testing**:
   - Build and upload APK/AAB to Internal Testing track
   - Add your email as test user

---

## 📱 TESTING PROCEDURES

### Pre-Testing Checklist
- [ ] App Store Connect products created and approved
- [ ] Google Play subscriptions created and active
- [ ] Test accounts configured
- [ ] App uploaded to respective store testing environments

### iOS Testing Steps

#### Step 1: Environment Setup
```bash
# Build for iOS device (required - simulator won't work)
flutter build ios
# Install on physical device via Xcode
```

#### Step 2: Test Account Setup
1. **Sign out** of your Apple ID in iOS Settings
2. DO NOT sign in with sandbox account yet
3. Launch Nepika app

#### Step 3: Purchase Testing
1. Navigate to pricing screen in app
2. Select weekly or yearly subscription
3. Tap "Subscribe Now"
4. When prompted, sign in with: `test.nepika@icloud.com`
5. Complete purchase flow

#### Step 4: Verify Results
- Check subscription status in app
- Verify in App Store Connect → Sandbox Transactions
- Test restore purchases functionality

### Android Testing Steps

#### Step 1: Environment Setup
```bash
# Build for Android
flutter build apk --release
# Or upload AAB to Play Console
flutter build appbundle
```

#### Step 2: Install from Play Console
1. Upload build to Internal Testing
2. Share Internal Testing link with test users
3. Install via Play Console link (NOT direct APK)

#### Step 3: Purchase Testing
1. Use real Google account (added as test user)
2. Navigate to pricing screen
3. Complete purchase flow
4. Note: Test purchases are free but behave like real purchases

#### Step 4: Verify Results
- Check subscription in app
- Verify in Google Play Console → Order Management
- Test subscription management

---

## 🔍 TESTING SCENARIOS

### 1. Successful Purchase Flow
**Goal**: Verify complete purchase process
```
1. App Launch → Pricing Screen
2. Select Product → Purchase
3. Complete Payment → Success
4. Verify Premium Access
```

### 2. Purchase Cancellation
**Goal**: Test user cancellation handling
```
1. Initiate Purchase
2. Cancel during payment flow
3. Verify app returns to previous state
4. Check no subscription created
```

### 3. Network Failure Handling
**Goal**: Test offline scenarios
```
1. Disconnect internet
2. Attempt purchase
3. Verify error handling
4. Reconnect and retry
```

### 4. Already Subscribed
**Goal**: Test existing subscription detection
```
1. Complete successful purchase
2. Attempt same purchase again
3. Verify appropriate handling
```

### 5. Restore Purchases
**Goal**: Test purchase restoration
```
1. Complete purchase on device A
2. Install app on device B (same account)
3. Use "Restore Purchases"
4. Verify subscription restored
```

---

## 🐛 DEBUGGING

### Enable Debug Logging
Add this to your testing code:
```dart
import 'package:nepika/core/utils/iap_testing_helper.dart';

// In your test function
IAPTestingHelper.printTestingGuide();
IAPTestingHelper.logPurchaseAttempt(
  productId: 'nepika_monthly_subscription',
  platform: 'ios',
  userId: 'test_user',
);
```

### Common Issues & Solutions

#### iOS Issues:
- **"Cannot connect to iTunes Store"**: Use physical device, check sandbox account
- **Products not found**: Ensure App Store Connect products are approved
- **Purchase fails silently**: Check device logs via Xcode Console

#### Android Issues:
- **Billing unavailable**: Must install via Play Console Internal Testing link
- **Products not found**: Verify subscriptions are active in Play Console
- **Authentication failed**: Ensure Google account is added as test user

### Debug Commands
```bash
# View iOS device logs
xcrun devicectl list devices
xcrun devicectl stream logs --device [DEVICE_ID]

# View Android logs
adb logcat | grep -i billing
adb logcat | grep -i nepika
```

---

## 📊 TEST VALIDATION

### Success Criteria
- [ ] Purchase initiation successful
- [ ] Payment flow completes
- [ ] Subscription activated in app
- [ ] Server receives and processes purchase
- [ ] Premium features unlocked
- [ ] Purchase restoration works
- [ ] Error states handled gracefully

### Performance Metrics
- Purchase flow completion time: < 30 seconds
- Error recovery time: < 5 seconds
- Subscription verification: < 3 seconds

---

## 🚀 PRODUCTION READINESS

### Before Going Live:
1. **Complete all store reviews**:
   - iOS: App Store review with IAP
   - Android: Play Console review

2. **Update entitlements for production**:
   - iOS: Change `aps-environment` to `production`
   - Android: Verify release signing

3. **Server endpoints ready**:
   - Receipt verification working
   - Webhook processing implemented
   - Subscription management functional

4. **Final testing**:
   - Test on production store environment
   - Verify all subscription plans working
   - Test subscription management flows

### Launch Checklist:
- [ ] Store products approved and live
- [ ] Server verification working
- [ ] Error handling tested
- [ ] Subscription management working
- [ ] Customer support processes ready
- [ ] Analytics/monitoring configured

---

## 📞 TROUBLESHOOTING CONTACTS

### Apple Support:
- App Store Connect Support
- Developer Technical Support (DTS)

### Google Support:
- Google Play Console Support
- Android Developer Support

### Internal:
- Backend team for server verification issues
- QA team for comprehensive testing
- Product team for business logic validation