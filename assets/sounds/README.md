# Alarm Sounds

## Adding a Custom Alarm Sound

To add a custom alarm sound to your app:

1. Find an MP3 audio file that you want to use as your alarm sound
2. Rename it to `alarm.mp3`
3. Place it in this directory (`assets/sounds/alarm.mp3`)
4. Rebuild your app with `flutter clean && flutter build`

## Default Behavior

If no custom alarm sound is provided, the app will use:
- The device's default notification sound
- Vibration patterns
- Visual notifications with stop button

## Recommended Audio Properties

For the best alarm experience:
- **Format**: MP3
- **Duration**: 10-30 seconds (will loop automatically)
- **Volume**: Moderate to loud
- **File size**: Under 1MB for app performance

## Legal Note

Make sure you have the rights to use any audio file you add to your app. Consider using royalty-free alarm sounds or sounds you've created yourself. 