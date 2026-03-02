# Android (Google Play) In-App Purchase (IAP) Setup & Testing Guide

This document outlines the exact, required steps to configure and test Google Play Billing (Subscriptions) for the Nepika app from start to finish. Google requires these steps to be completed before any products can be queried or purchased in the app.

---

## Phase 1: Fixing the Payments Profile (The Blocker)
Just like Apple, Google will completely block your app from seeing the subscriptions if you do not have an active Merchant/Payments Profile linked to the Developer Account.

**1. Log into Google Play Console as the Account Owner**
*   The person who originally paid the $25 Google Developer registration fee must sign in to the [Google Play Console](https://play.google.com/console).

**2. Create & Verify the Payments Profile**
*   On the left menu, scroll down to **Setup** > **Payments profile**.
*   Click **Create payments profile**.
*   Fill out the **Business Information** (Legal Name, Address, Contact Info, Website, etc.).
*   Click **Submit**.
*   Next, click **Add payment method**.
*   Enter your bank account routing and account numbers for payouts.
*   **Wait for the Test Deposit:** Within 3-5 days, Google will send a deposit of less than $1.00 to that bank account. Once it arrives, come back to this page, click **Verify**, and enter the exact amount deposited.
*   *Note: Subscriptions will not work until this Payments Profile is fully active.*

---

## Phase 2: App & Product Configuration
Your app needs to be published on an internal testing track, and the products must be active.

**1. Upload a Signed APK/AAB to the Closed/Internal Testing Track**
*   Google Play Billing **will not work** if the app has never been uploaded to the Play Console.
*   Run: `flutter build appbundle --release`
*   In the Google Play Console, go to **Testing** > **Internal testing**.
*   Create a new release and upload the `.aab` file you just built.
*   Save and Roll out the release.

**2. Create the Subscriptions**
*   Go to **Monetize** > **Products** > **Subscriptions**.
*   Create your two products. The IDs **must exactly match** your Dart code:
    *   `com.assisted.nepika.monthly`
    *   `com.assisted.nepika.yearly`
*   Add the prices, descriptions, and ensure the status is explicitly set to **Active**.

---

## Phase 3: Setup the Sandbox (License) Tester
You need to add a tester allowed to make fake purchases using fake credit cards provided by Google.

**1. Add the Tester Email to License Testing**
*   Go to the **Google Play Console** home screen (All Apps view).
*   On the left sidebar, go to **Setup** > **License testing**.
*   Under "License testers", enter the testing email address (e.g., your personal Gmail or a team member's Gmail).
*   Under "License response", leave it as `RESPOND_NORMALLY`.
*   Click **Save changes**.

**2. Add the Tester to the Internal Testing Track**
*   Go back into your specific Nepika app dashboard.
*   Go to **Testing** > **Internal testing**.
*   Click the **Testers** tab.
*   Check the box next to your team's email list or add the tester email directly.
*   **CRITICAL STEP:** At the bottom, click **Copy Link**. Send this link to the tester. The tester **must** open that link on their Android phone and click **"Accept Invitation"**. If they skip this, the billing won't work in the app.

---

## Phase 4: Run the Test!
Now that everything is wired up, let's trigger the purchase.

**1. Log into the Testing Device**
*   Ensure the Android phone you are using has its primary Google Play Store account logged in as the exact email address you added in Phase 3.

**2. Install the App**
*   You must install the app that you uploaded to the Internal Testing track (usually downloaded directly from the Play Store via that "Accept Invitation" link). 
*   *Alternatively, you can run `flutter run -d "Android"` locally on a cable, but ONLY if the local build has the exact same Application ID, Version Number, and signing keystore as the one uploaded to the Play Console.*

**3. Simulate the Purchase**
*   Navigate to your app's Premium upgrade screen.
*   Tap the "Subscribe" button.
*   Google's payment sheet will pop up.
*   **Verify the fake credit card:** Because you are a License Tester, Google will not show your real credit card. Instead, it will show a drop-down with options like **"Test card, always approves"** or **"Test card, always declines"**.
*   Select the "Test card, always approves" option and complete the purchase.

> **Important Testing Note:** Just like Apple Sandbox, Google Play accelerates time for License Testers. A 1-month subscription will automatically renew every **5 minutes**, up to a maximum of 6 times. Use this time to verify your app unlocks Premium correctly!
