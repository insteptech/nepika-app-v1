# StoreKit Product Loading Troubleshooting Guide

## Current Status
✅ Code is properly integrated (server/StoreKit merge working)
❌ StoreKit products not loading from App Store Connect
📊 Falling back to server prices

## The Issue
```
flutter: IAP: Products not found: [com.assisted.nepika.weekly, com.assisted.nepika.yearly]
flutter: IAP: Product query error: StoreKit: Failed to get response from platform.
flutter: IAP: Error code: storekit_no_response
flutter: IAP: Falling back to server prices (StoreKit unavailable)
```

## Root Causes (Most Likely)

### 1. **Products Are "Ready to Submit" But Not in Sandbox Yet** (MOST LIKELY)
**Problem:** App Store Connect can take 24-48 hours to propagate "Ready to Submit" products to sandbox environment.

**Solution:** Wait 24-48 hours after setting products to "Ready to Submit"

**Check:**
```bash
# Try again tomorrow and check logs
flutter run
```

### 2. **Testing on Simulator Instead of Physical Device** (CRITICAL)
**Problem:** StoreKit Configuration file only works on:
- Physical iOS devices (iOS 14+)
- Xcode 12+ with StoreKit testing enabled

**Solution:**
- MUST test on physical iPhone/iPad
- Simulator won't load real App Store Connect products
- Simulator CAN use local StoreKit Configuration file (Products.storekit)

### 3. **StoreKit Configuration Not Enabled in Xcode**
**Problem:** Created Products.storekit but didn't configure Xcode scheme

**Solution:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Click scheme selector → "Edit Scheme..."
3. Select "Run" → "Options" tab
4. Under "StoreKit Configuration", select "Products.storekit"
5. Clean build folder (Cmd+Shift+K)
6. Run on physical device

### 4. **Subscription Group Not "Ready to Submit"**
**Problem:** Individual products are ready, but the subscription group isn't

**Check in App Store Connect:**
- Go to: Subscriptions → Subscription Groups
- Ensure the group containing your products is also "Ready to Submit"
- Both products AND group need proper status

### 5. **App Not Configured in App Store Connect**
**Problem:** Products exist, but app itself has issues

**Solution:**
- App Store Connect → Your App → App Information
- Ensure Bundle ID matches: `com.assisted.nepika`
- Check "Paid Applications" agreement is signed
- App must be at least in "Prepare for Submission" status

## Quick Diagnostic Checklist

### App Store Connect
- [ ] Products status: "Ready to Submit" or better
- [ ] Subscription Group status: "Ready to Submit" or better
- [ ] Waited 24-48 hours since status change
- [ ] Bundle ID matches: `com.assisted.nepika`
- [ ] "Paid Applications" agreement active
- [ ] At least one price point configured
- [ ] At least one localization complete

### Xcode Configuration
- [ ] Testing on physical iOS device (NOT simulator)
- [ ] Signed out of regular Apple ID on device
- [ ] Products.storekit added to Xcode project
- [ ] StoreKit Configuration selected in scheme
- [ ] Clean build performed after changes
- [ ] Running via Xcode (not just flutter run)

### Device Setup
- [ ] iOS 12.2 or later
- [ ] Signed OUT of Apple ID in Settings
- [ ] No VPN or proxy blocking App Store
- [ ] Good internet connection
- [ ] Region/country matches App Store Connect

## Testing Approaches

### Approach 1: Wait for App Store Connect (Recommended for Production)
**Timeline:** 24-48 hours
**Steps:**
1. Verify products are "Ready to Submit" in App Store Connect
2. Wait 24-48 hours
3. Test on physical device
4. Sign in with sandbox account when prompted during purchase

**Pros:**
- Tests real App Store Connect integration
- Validates actual production setup

### Approach 2: Use Local StoreKit Configuration (Immediate Testing)
**Timeline:** Immediate
**Steps:**
1. Products.storekit already created at: `ios/Products.storekit`
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Add file to project (if not already)
4. Edit Scheme → Options → StoreKit Configuration → "Products"
5. Clean build and run on physical device
6. No Apple ID needed for testing

**Pros:**
- Works immediately
- No waiting for Apple servers
- Test purchase flows without real money

**Cons:**
- Doesn't test real App Store integration
- Need to switch to real testing later

## Expected Logs When Working

### Success - StoreKit Configuration:
```
flutter: IAP: Loading products {com.assisted.nepika.weekly, com.assisted.nepika.yearly}
flutter: IAP: Successfully loaded 2 products
flutter: IAP: Product - ID: com.assisted.nepika.weekly, Title: Nepika Premium Weekly, Price: $4.99
flutter: IAP: Product - ID: com.assisted.nepika.yearly, Title: Nepika Premium Yearly, Price: $49.99
flutter: IAP: Merged 2 products with StoreKit data
flutter: IAP: Using StoreKit prices for 2 products
```

### Success - App Store Connect:
```
flutter: IAP: Loading products {com.assisted.nepika.weekly, com.assisted.nepika.yearly}
flutter: IAP: Successfully loaded 2 products
flutter: IAP: Product - ID: com.assisted.nepika.weekly, Title: Nepika Premium Weekly, Price: $4.99
flutter: IAP: Product - ID: com.assisted.nepika.yearly, Title: Nepika Premium Yearly, Price: $49.99
flutter: IAP: Merged 2 products with StoreKit data
flutter: IAP: Using StoreKit prices for 2 products
```

## Immediate Action Plan

### Option A: Test with Local StoreKit (Fastest)
```bash
# 1. Open project in Xcode
open ios/Runner.xcworkspace

# 2. In Xcode:
#    - Add ios/Products.storekit to project
#    - Edit Scheme → Run → Options → StoreKit Configuration → "Products"
#    - Select physical device
#    - Product → Clean Build Folder
#    - Product → Run

# 3. Check logs for success
```

### Option B: Wait for App Store Connect (Production-Ready)
```bash
# 1. Verify setup in App Store Connect:
#    - Products: "Ready to Submit" ✓
#    - Subscription Group: "Ready to Submit" ✓
#    - Bundle ID: com.assisted.nepika ✓

# 2. Wait 24-48 hours

# 3. Test on physical device:
cd ios
open Runner.xcworkspace
# Run on device, sign in with sandbox tester when prompted

# 4. Check logs for success
```

## Common Mistakes to Avoid

❌ Testing on simulator without StoreKit Configuration
❌ Using `flutter run` instead of Xcode for initial testing
❌ Not signing out of Apple ID on device
❌ Expecting immediate availability after "Ready to Submit"
❌ Not configuring StoreKit Configuration in Xcode scheme
❌ Mismatched Bundle IDs between Xcode and App Store Connect

## When to Contact Apple Support

If after 48 hours and following all steps above, products still don't load:
1. Products are "Approved" in App Store Connect
2. Testing on physical device with Xcode
3. No StoreKit errors in Xcode console
4. Bundle IDs match perfectly

Then contact: Apple Developer Technical Support

## Next Steps

**Right Now:**
1. Choose testing approach (Local StoreKit or Wait for App Store Connect)
2. Follow the corresponding steps above
3. Test and check logs

**Expected Result:**
```
flutter: IAP: Successfully loaded 2 products
flutter: IAP: Using StoreKit prices for 2 products
```

**When Working:**
- Pricing screen will display real StoreKit prices
- Purchase flow will work correctly
- Server features will display alongside StoreKit prices
