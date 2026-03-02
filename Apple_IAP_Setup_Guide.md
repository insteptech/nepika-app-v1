# Apple In-App Purchase (IAP) Setup & Testing Guide

This document outlines the exact, required steps to configure and test Apple In-App Purchases (Subscriptions) for the Nepika app from start to finish. Apple requires these steps to be completed before any products can be queried or purchased in the app.

---

## Phase 1: Fixing the Account Configuration (The Blocker)
You cannot test or fetch products until this is done.

**1. Log into App Store Connect as the Account Holder**
*   The person who originally paid the Apple Developer Enrollment fee must sign in to [App Store Connect](https://appstoreconnect.apple.com/).
*   Go to **Agreements, Tax, and Banking**.

**2. Sign the Paid Apps Agreement**
*   On the "Paid Apps Agreement" row, click **View and Agree**.
*   Accept the Terms of Service.
*   Fill out the **Bank Account** information (Routing number, Account number, Bank Country).
*   Fill out the **Tax Forms** (Usually a W-8BEN-E for a UK company like Nepika Creative Limited).
*   Wait until the Agreement Status explicitly changes from "New" or "Pending" to **"Active"**. 

---

## Phase 2: App Project Configuration
You must explicitly tell your app that it is legally allowed to ask Apple for money.

**1. Open Xcode**
*   In your terminal, navigate to your flutter project and run: `open ios/Runner.xcworkspace`

**2. Add the In-App Purchase Capability**
*   Click `Runner` on the left sidebar.
*   Click the **Signing & Capabilities** tab in the main window window.
*   Click the **+ Capability** button in the top left.
*   Search for **In-App Purchase** and double-click it to add it to your project list.

---

## Phase 3: Setup the Sandbox User for Testing
You need a fake user account to simulate buying the subscription without using a real credit card.

**1. Create the Sandbox Account**
*   Go back to **App Store Connect**.
*   Click on **Users and Access**.
*   On the left menu under "Sandbox", click **Testers**.
*   Click the blue **[+]** button to add a new tester.
*   Enter a fake Name, a password, and a **brand new email** that has never been used as an Apple ID before (e.g., `nitin+sandbox1@gmail.com`). 
*   Click Save.

**2. Log into the Sandbox Account on your Physical iPhone**
*   Take your real iPhone and open the **Settings** app.
*   Tap on **App Store**.
*   Scroll all the way down to the bottom to **Sandbox Account**.
*   Sign in using the `nitin+sandbox1@gmail.com` email and password you just made in App Store Connect.

---

## Phase 4: Run the Test!
Now that everything is wired up, let's trigger the purchase.

**1. Build the App to your iPhone**
*   Plug your iPhone into your computer.
*   In your terminal, run: `flutter clean`
*   Then run: `flutter run -d "iPhone"` (or whatever the device name is).

**2. View the Subscriptions**
*   Navigate to your app's Premium upgrade screen.
*   Because the Paid Apps Agreement is now active and Xcode has the capability, your `com.assisted.nepika.monthly` and `yearly` prices will successfully load from Apple!

**3. Simulate the Purchase**
*   Tap the "Subscribe" button.
*   Apple's payment sheet will pop up.
*   **Verify** that it says **[Environment: Sandbox]** on the payment sheet.
*   Complete the purchase using the sandbox password. 

> **Important Testing Note:** Because you are using the Sandbox environment, Apple will artificially speed up time. A 1-month subscription will automatically expire and renew every **5 minutes**. You can use this accelerated time to test if the "Premium Content" in your app correctly unlocks and locks as the fake subscription cycles!
