# Statch App Assets

## Splash Screen Images

For the native splash screen to work, add the following images:

### `splash_logo.png` (Light Mode)
- Size: 512x512 pixels (will be scaled automatically)
- Background: Transparent
- Content: App logo in dark/green color for visibility on white background

### `splash_logo_dark.png` (Dark Mode)
- Size: 512x512 pixels (will be scaled automatically)
- Background: Transparent
- Content: App logo in white/green color for visibility on black background

## Recommended Logo Design

The Statch logo should feature:
- A stylized "S" or upward trending chart line
- The Emerald Green brand color (#00C805)
- Clean, modern design that works at small sizes

## Generating Splash Screen

After adding the images, run:

```bash
flutter pub run flutter_native_splash:create
```

This will generate the native splash screen for Android and iOS.
