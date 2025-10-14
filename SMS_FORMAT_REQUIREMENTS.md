# SMS Auto-Capture Requirements for Android

## Current Issue
The SMS listener is timing out because the incoming SMS doesn't match the format required by Google's SMS Retriever API.

## App Signature
Your app's signature hash: **`pRsNh+4imYr`**

## Required SMS Format for Android

The SMS **MUST** be sent in this exact format:

```
<#> Your OTP code is 163051
Do not share this code. It will expire in 5 minutes.
pRsNh+4imYr
```

### Format Requirements:
1. **Start with `<#>`** - This tells Android this is an auto-retrievable SMS
2. **OTP text** - Can be customized, must contain the 6-digit code
3. **App signature on new line** - Must be `pRsNh+4imYr` on its own line at the end
4. **Total SMS length** - Must be under 140 characters including the signature

## Alternative Format (Shorter)

If the message is too long, use this shorter version:

```
<#> Your OTP code is 163051
pRsNh+4imYr
```

## Backend Implementation

### Current Backend Call
When sending OTP via your backend API (`/api/v1/auth/users/send-otp`), ensure the `appSignature` field is being used correctly.

### Example API Request Body:
```json
{
  "phone": "+917300629250",
  "otpId": "941fcf59-0780-4305-a376-9a6b1f1fb9fd",
  "appSignature": "pRsNh+4imYr"
}
```

### Backend SMS Template:
```
<#> Your OTP code is {OTP_CODE}
Do not share this code. It will expire in 5 minutes.
{APP_SIGNATURE}
```

Where:
- `{OTP_CODE}` = The 6-digit OTP (e.g., 163051)
- `{APP_SIGNATURE}` = The app signature received from the API (pRsNh+4imYr)

## For iOS
iOS uses a different auto-fill mechanism. The format can be simpler:

```
Your OTP code is 163051
Do not share this code. It will expire in 5 minutes.
```

iOS doesn't require the `<#>` prefix or app signature.

## Testing

### How to Test Android Auto-Capture:
1. Ensure backend sends SMS with correct format
2. Send OTP request from app
3. Check Flutter logs for: `OtpService: ========== SMS CODE RECEIVED ==========`
4. If you see this log, the SMS was detected correctly
5. If you see `OtpService: ⏱️ Timeout reached`, the SMS format is incorrect

### Manual Testing:
You can test by sending an SMS manually from another phone in this exact format:

```
<#> Your OTP code is 123456
pRsNh+4imYr
```

## Important Notes

1. **SMS must arrive within 5 minutes** of calling the auto-capture API
2. **Signature is case-sensitive** - Must be exactly `pRsNh+4imYr`
3. **No extra spaces** - The signature line should have no leading/trailing spaces
4. **Newlines matter** - The signature must be on its own line

## Debugging

Check the Flutter debug console for these messages:
- ✅ Success: `OtpService: ========== SMS CODE RECEIVED ==========`
- ❌ Timeout: `OtpService: ⏱️ Timeout reached after 45 seconds`
- ⚠️ Wrong format: `OtpService: ❌ No valid 6-digit OTP found`

## References
- [Google SMS Retriever API](https://developers.google.com/identity/sms-retriever/overview)
- [Computing Your App's Hash String](https://developers.google.com/identity/sms-retriever/verify#computing_your_apps_hash_string)
