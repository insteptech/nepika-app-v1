# Deploying Nepika to TestFlight
Follow these steps to deploy your latest build to TestFlight.

## Prerequisites
- **Apple Developer Account**: Ensure you are signed in to Xcode with your Apple ID.
- **Signing Identity**: Ensure you have a valid distribution certificate and provisioning profile (managed automatically by Xcode is recommended).

## Step 1: Build the iOS Archive (IPA)
We have already bumped the version to `1.0.1+3` in `pubspec.yaml`.

Run the following command in your terminal to build the release archive:

```bash
flutter build ipa --release --export-options-plist=ios/Runner/ExportOptions.plist
```
*(Note: If you don't have an `ExportOptions.plist`, simple `flutter build ipa` is fine, or continue to Step 2 to upload via Xcode).*

**Recommended Approach:** Since automated upload can be tricky without setup, we will use Xcode to handle the upload.

Run:
```bash
flutter build ios --release
```
This prepares the iOS project.

## Step 2: Archive and Upload via Xcode
1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In Xcode, select **Any iOS Device (arm64)** as the destination (top bar, where simulator list is).
3. Go to **Product > Archive**.
4. Wait for the build to complete. The **Organizer** window will open.
5. Select your latest archive (Version `1.0.1+3`).
6. Click **Distribute App**.
7. Select **TestFlight & App Store** -> **Next**.
8. Select **Upload** -> **Next**.
9. Select your Team (Nepika/Assisted) -> **Next**.
10. Ensure "Upload your app's symbols" and "Manage Version and Build Number" are checked -> **Next**.
11. Select **Automatically manage signing** -> **Next**.
12. Review the summary and click **Upload**.

## Step 3: TestFlight Release
1. Once uploaded, go to [App Store Connect](https://appstoreconnect.apple.com).
2. Go to **My Apps** -> **Nepika**.
3. Click on the **TestFlight** tab.
4. You should see your new build processing.
5. Once processed, it may show "Missing Compliance". Click "Manage", select "No" for encryption (unless you added specific crypto features), and Start Testing.
6. Add External Testers or Internal Testers to release it.

## Troubleshooting
- **Signing Errors**: Go to Xcode -> Signing & Capabilities -> Select your Team. Ensure "Automatically manage signing" is checked.
- **Version Exists**: Ensure you incremented the build number (we did this for you: `1.0.1+3`).