# nepika_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# nepika-app






Hello Apple Review Team,

Thank you for your guidance. Please find our detailed responses below regarding face data processing, storage, retention, deletion, and subscriptions.

1. What face data does the app collect?
The app collects a single facial image uploaded by the user for the purpose of performing a skin-analysis scan.
We do not collect or generate biometric identifiers such as face geometry, depth maps, face templates, or facial recognition data.

We only analyze the image to detect:
• Skin type
• Common skin concerns
• Localized facial areas
• Confidence scores

2. How is the collected face data used?
The uploaded image is used solely to run the skin-analysis pipeline.
From this image, we generate:
• Skin type prediction
• Condition and concern classifications
• Area-specific bounding boxes
• An annotated image with highlighted areas
• Personalized product and routine recommendations

We do not use face data for identity verification, authentication, or tracking.

3. Is face data shared with third parties?
No.
We do not share raw images, annotated images, or analysis results with any third parties.
All processing takes place on our secured AWS infrastructure.

4. Where is face data stored?
• Raw uploaded image: processed in memory only and never stored
• Annotated image: securely stored in AWS S3
• Scan results: stored encrypted in AWS RDS (PostgreSQL)

All data is encrypted both in transit and at rest.

5. How long is face data retained?
We follow a 2-year retention policy:
• Annotated images → up to 2 years
• Scan results → up to 2 years

Exception:
If a user deletes their account, all associated data — including annotated S3 images and analysis results — is permanently deleted immediately.
We have already updated the backend to ensure S3 file deletion occurs during account removal.

6. Where is this described in the Privacy Policy?
The app includes dedicated in-app screens for both the Privacy Policy and Terms of Use, accessible at:
Settings → Privacy Policy
Settings → Terms of Use

The Privacy Policy explicitly includes:
• What face data is collected
• How the face image is processed
• Storage (S3 + RDS)
• Retention
• Deletion on account removal
• No third-party sharing

Relevant Privacy Policy section:

“Face Scan Data:
The app processes user-uploaded facial images to detect skin type and common concerns. The original image is processed in memory and not stored. An annotated version of the image and analysis results are securely stored on our servers. This data is used only to provide skin analysis and personalized recommendations. We do not share face data with third parties. Data is retained for up to two years or deleted immediately upon user-initiated account deletion.”

7. Subscription Terms of Use (EULA)
The full Terms of Use (EULA) are provided within the app under:
Settings → Terms of Use

We will also provide the external link directly in the App Store listing as required.

8. Account Deletion
The app includes a full account deletion flow:
Settings → Delete Account → Select Reason → Confirm

Deletion immediately:
• Removes the user account
• Deletes all scan results
• Deletes all annotated face images from S3
• Deletes all linked records in our RDS database

Thank you for your review. Please let us know if you require any additional clarifications.