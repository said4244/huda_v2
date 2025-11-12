# Speech-End Detection Test Guide

## Overview
This guide helps you verify that the new speech-end detection system is working correctly.

## What's Been Implemented

### Server Changes
- Avatar agent now emits `avatar_speech_started` and `avatar_speech_ended` events
- Uses `handle.wait_for_playout()` for precise timing
- Handles both user messages and initial greeting

### Client Changes
- ConnectionManager listens for data events and active speaker changes
- TavusAvatar provides `sendMessageAndWait()` helper method
- ExerciseIntroWidget uses event-driven sequencing instead of fixed delays

## Testing Steps

### 1. Server Test
```bash
cd server
python test_avatar_agent.py
```
- Look for console messages: `[agent] speech playout finished; EOS sent`
- Server should emit JSON data packets with `{"type": "avatar_speech_ended"}`

### 2. Flutter Integration Test
1. Run the example app:
   ```bash
   cd example
   flutter run -d web
   ```

2. In a lesson with `sendMessages`, observe:
   - Avatar speaks first message
   - Next video/message waits until avatar finishes
   - No more hard-coded delays based on word count

### 3. Verification Points

#### Server Console
Look for these messages:
```
[agent] starting speech: [message text]
[agent] speech playout finished; EOS sent
```

#### Client Console/Logs
Look for these log messages:
```
Avatar speech ended (server signal)
Received avatar_speech_ended event, completing wait
```

#### UI Behavior
- Videos play immediately after avatar stops speaking
- No artificial delays between avatar messages
- Microphone feedback completes before continuing

## Expected Timeline

### Before (with fixed delays)
```
1. Send message
2. Wait ~3 seconds (word count × 0.5s)
3. Play next video
```

### After (with speech-end detection)
```
1. Send message
2. Wait for actual speech completion (varies by content)
3. Play next video immediately
```

## Troubleshooting

### If speech-end events don't arrive:
- Check server logs for EOS emission
- Verify ConnectionManager is listening to DataReceivedEvent
- Test VAD fallback (should trigger after 600ms of silence)

### If timing seems off:
- Server `wait_for_playout()` should be authoritative
- Client timeout (15s) should be backup safety net
- VAD detection provides secondary fallback

### Common Issues:
1. **Missing EOS events**: Check server environment variables and LiveKit connection
2. **Timeout errors**: Increase timeout in `sendMessageAndWait` calls
3. **VAD false positives**: Avatar speaking detection relies on participant identity matching

## Success Criteria

✅ Avatar agent emits speech-end events to LiveKit room  
✅ Client receives and processes data events correctly  
✅ ExerciseIntroWidget waits for real speech completion  
✅ Videos play immediately after avatar stops speaking  
✅ Fallback VAD detection works when server signals fail  
✅ Existing `sendTextMessage` calls still work normally  

## Performance Notes

- Server: Minimal overhead from additional data packet publishing
- Client: StreamSubscription management for event listening
- UI: Replaces Timer-based delays with event-driven waiting
- Network: Small JSON data packets for speech state signaling
