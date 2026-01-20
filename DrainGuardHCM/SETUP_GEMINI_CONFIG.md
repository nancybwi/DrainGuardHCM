# How to Fix Gemini API Configuration

## Problem
The app is getting a 404 error from Gemini API because the model name isn't being passed correctly from `Config.xcconfig` to `Info.plist`.

## Solution: Connect Config.xcconfig to Info.plist

### Step 1: Open Info.plist
1. In Xcode, find `Info.plist` in your project navigator
2. Right-click → "Open As" → "Source Code"

### Step 2: Add These Keys to Info.plist

Add these entries inside the `<dict>` tag:

```xml
<key>GEMINI_API_KEY</key>
<string>$(GEMINI_API_KEY)</string>
<key>GEMINI_MODEL</key>
<string>$(GEMINI_MODEL)</string>
```

**Full Example:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Your existing keys here -->
    
    <!-- Add these for Gemini -->
    <key>GEMINI_API_KEY</key>
    <string>$(GEMINI_API_KEY)</string>
    <key>GEMINI_MODEL</key>
    <string>$(GEMINI_MODEL)</string>
    
    <!-- Rest of your keys -->
</dict>
</plist>
```

### Step 3: Link Config.xcconfig to Your Target

1. Select your project in Xcode (top of navigator)
2. Select your app target (DrainGuardHCM)
3. Go to "Info" tab
4. Under "Configurations", make sure `Config.xcconfig` is selected for both Debug and Release

### Step 4: Clean and Rebuild

1. Product → Clean Build Folder (⇧⌘K)
2. Product → Build (⌘B)
3. Run the app

## Alternative: Hardcode in AIValidationService (Quick Fix)

If you just want to test quickly, you can hardcode the values:

In `AIValidationService.swift`, change the init to:

```swift
init() {
    // Temporary hardcoded values for testing
    self.apiKey = "AIzaSyDXIlDzDfr_J9A9gnA6t35z2vbeq_P-2PQ"
    self.model = "gemini-2.5-flash"
    
    print("🤖 [AI] AIValidationService initialized")
    print("🤖 [AI] Model: \(model)")
}
```

## Verify It's Working

After setup, you should see in the console:

```
🤖 [AI] AIValidationService initialized
🤖 [AI] Model: gemini-2.5-flash
🤖 [API] Sending request to Gemini...
🤖 [API] Model: gemini-2.5-flash
🤖 [API] Full endpoint: https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent
```

NOT:
```
🤖 [API] Full endpoint: https://generativelanguage.googleapis.com/v1beta/models/:generateContent
```

## Available Gemini Models

- `gemini-2.5-flash` ✅ (Recommended - Latest, Fast)
- `gemini-1.5-flash` (Previous version, also fast)
- `gemini-1.5-pro` (Slower, more capable, better reasoning)
- `gemini-2.0-flash-exp` (Experimental, fastest, may change)

