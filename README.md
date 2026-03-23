# TikGood 📚 
> **Version:** 0.0.1+1 (Beta)


> **Take notes on videos — the way it should have always worked.** 
 
TikGood is a TikTok-style video player built specifically for course learners. Watch your videos and take timestamped notes in the same place, without ever pausing to switch apps. 
 
--- 
 
## The Problem It Solves 
 
The traditional workflow for taking notes while watching a course video: 
 
1. Open video player 
2. Pause video 
3. Switch to notes app 
4. Write note 
5. Switch back to video 
6. Repeat 50 times 
 
TikGood collapses all of that into one screen. You watch, you note, you keep going. 
 
--- 
 
## Core Features 
 
### 📝 Timestamped Notes 
Every note you take is automatically stamped with the exact second in the video you were watching. Tap any note later and it jumps you straight back to that moment. 
 
### 4 Note Types 
| Type | Description | 
|------|-------------| 
| **Text** | Plain written note | 
| **Text + Image** | Written note with a photo from your gallery | 
| **Frame Capture** | Snapshot of the exact video frame you're currently watching — no more taking screenshots and pasting them into a notes app | 
| **Voice Memo** | Record yourself explaining a concept in your own words | 
| **Bookmark** | Silent marker — just saves the timestamp, no content required | 
 
### 🎬 TikTok-Style Video Feed 
- Vertical swipe feed, one video at a time 
- **For You tab** — shows videos from all your added courses, including ones you haven't followed 
- **Following tab** — shows only videos from courses you've explicitly followed 
- Double-tap to like (saved in liked videos screen that you can find in profile page)
- Long-press on the right side to play at **2× speed** with animated badge 
- Drag the progress bar to seek; large timestamp display while scrubbing 
- **Resume from where you left off** — the app remembers your position in every video and picks up from there on next launch 
 
### 🔲 Picture-in-Picture (PIP) 
Leave the app and the video keeps playing in a floating window. Works automatically when you background the app from the Home tab. Tap play/pause directly in the PIP window. 
 
### 🖥️ Fullscreen & Landscape Mode 
One tap rotates the player to landscape and enters immersive fullscreen — much better for actually watching course content. 
 
### 📂 Course Management 
- Add courses with their video files 
- Course profile page showing all videos and their names 
- Follow/unfollow courses to control what appears in your Following feed 
- Avatar generated automatically per course 
 
### 🔥 Study Streak & Daily Reminder 
- Tracks your **consecutive study days** — the app knows if you opened it today 
- Set a **daily notification reminder** at your chosen time with psychologically engaging messages to keep you motivated 
- Configure the streak in **Settings → Streak & Reminder** 
 
### 🎯 Session Goals & Persistent Reminder 
- **Set an Intention** — when opening the app, you're prompted to set a clear goal for your study session 
- **Persistent Notification** — your goal stays in your notification tray while you use the app, keeping you focused 
- **Goal History** — view and manage all your past goals in Settings to track your progress over time 
 
--- 
 
## Notes Page 
 
A dedicated page showing every note you've ever taken, organized by video and course. From here you can: 
- Browse all notes across all courses 
- Tap a note to jump to that moment in the video 
- **Export to PDF** — generate a clean PDF of your notes for any course 
 
--- 
 
## Notion Integration 
 
For people who already live in Notion and don't want their notes stuck in another app. 
 
Connect your Notion workspace once in Settings and TikGood will automatically mirror your notes there: 
 
- One **sub-page per course** inside your chosen Notion page 
- Each video gets an **expandable toggle block** with its name 
- All notes appear underneath, with their timestamp 
- Frame captures are uploaded to **Cloudinary** and embedded as images in Notion (Notion's API doesn't support direct image uploads) 
- Voice memos are not synced (Notion API limitation) 
 
> You'll need a Notion API key and a Cloudinary API key. Both are free tiers. A short tutorial video is linked inside the app showing how to get each one. 
 
--- 
 
## 🔒 Platform & Distribution Notes  

- The **TikTok hooking feature** is **only available in the GitHub version** of the app.  
- This feature will **NOT be included in the Google Play Store release** due to platform policy restrictions.  

--- 
 
## 🚀 Upcoming Features 
 
These features are actively being worked on and will ship in future releases: 
 
| Feature | Status | 
|---------|--------| 
| 🎥 **YouTube Courses** — import a YouTube playlist URL and watch it in TikGood's feed | Coming Soon | 
| 🤖 **AI note summarization** — auto-generate a summary of your notes for each video | Coming Soon | 
| 🌍 **Multi-language support** — use the app in different languages | Coming Soon | 
 
--- 
 
## Tech Stack 
 
| Category | Libraries | 
|----------|-----------| 
| Video playback | `media_kit`, `media_kit_video` | 
| State management | `flutter_bloc` | 
| Local storage | `hive`, `shared_preferences`, `flutter_secure_storage` | 
| Navigation | `go_router` | 
| Notes sync | `notion_db_sdk` | 
| Image hosting | Cloudinary via `http` | 
| Audio recording | `record`, `waveform_flutter` | 
| Speech-to-text | `whisper_flutter_new` | 
| PDF export | `pdf`, `printing` | 
| Video processing | `ffmpeg_kit_flutter_new` | 
| Firebase | Auth, Analytics, Crashlytics, Messaging, Storage | 
| PIP | `android_pip` | 
| Notifications | `flutter_local_notifications`, `firebase_messaging` | 
| Localization | `easy_localization` | 
 
--- 
 
## Project Structure 
 
```

lib/
├── core/
│   ├── database/          # Hive storage service
│   ├── services/          # StreakService, etc.
│   ├── theme/             # App colors & theme
│   └── utils/             # Helpers, cache, FCM, secure storage
├── features/
│   ├── courses/           # Course & video models, add/profile pages
│   ├── following/         # Following feed
│   ├── goals/             # Session goals & persistent notifications
│   ├── home/              # For You feed + AppCubit (main state)
│   ├── liked_videos/      # Liked videos page
│   ├── notes/             # Notes page + Notion service
│   └── settings/          # API keys, preferences, streak
└── widgets/
└── video_player/      # VideoItem, notes sheet, action buttons

```
 
--- 
 
## Platform 
 
**Android only** (PIP and orientation features are Android-specific for now) 

Built with Flutter.