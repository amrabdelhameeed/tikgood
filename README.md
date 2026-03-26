# TikGood 📚 
> **Version:** 0.0.1+1 (Beta)

> **Take notes on videos — the way it should have always worked.** TikGood is a TikTok-style video player built specifically for course learners. Watch your videos and take timestamped notes in the same place, without ever pausing to switch apps. 
 
--- 
 
## 💡 The Problem It Solves 
 
The traditional workflow for taking notes while watching a course video: 
 
1. Open video player 
2. Pause video 
3. Switch to notes app 
4. Write note 
5. Switch back to video 
6. Repeat 50 times 
 
TikGood collapses all of that into one screen. You watch, you note, you keep going. 
 
--- 
 
## ✨ Core Features 
 
### 📝 Timestamped Notes 
Every note you take is automatically stamped with the exact second in the video you were watching. Tap any note later and it jumps you straight back to that moment. 
 
### 🛠 4 Note Types 
| Type | Description | 
|------|-------------| 
| **Text** | Plain written note | 
| **Text + Image** | Written note with a photo from your gallery | 
| **Frame Capture** | Snapshot of the exact video frame you're currently watching | 
| **Voice Memo** | Record yourself explaining a concept in your own words | 
| **Bookmark** | Silent marker — just saves the timestamp, no content required | 
 
### 🎬 TikTok-Style Video Feed 
- **Vertical swipe feed**, one video at a time. 
- **For You tab** — shows videos from all your added courses. 
- **Following tab** — shows only videos from courses you've explicitly followed. 
- **Double-tap to like** — saved in your liked videos screen in the profile page.
- **Long-press (Right side)** — play at **2× speed** with an animated badge. 
- **Smart Scrubbing** — Drag the progress bar to seek; large timestamp display while scrubbing. 
- **Resume Playback** — The app remembers your position in every video and picks up from there. 
 
### 🔲 Picture-in-Picture (PIP) 
Leave the app and the video keeps playing in a floating window. Works automatically when you background the app from the Home tab. 
 
### 🖥️ Fullscreen & Landscape Mode 
One tap rotates the player to landscape and enters immersive fullscreen — much better for watching course content. 
 
--- 
 
## 📂 Course & Goal Management 
 
### Course Management 
- Add courses with local video files. 
- Course profile page showing all videos and names. 
- Follow/unfollow courses to control your Following feed. 
- Avatar generated automatically per course. 
 
### 🔥 Study Streak & Daily Reminder 
- Tracks your **consecutive study days**. 
- Set a **daily notification reminder** with psychologically engaging messages. 
- Configure in **Settings → Streak & Reminder**. 
 
### 🎯 Session Goals 
- **Set an Intention** — Prompted to set a clear goal when opening the app. 
- **Persistent Notification** — Your goal stays in the notification tray to keep you focused. 
- **Goal History** — View and manage all past goals in Settings. 
 
--- 
 
## 🔌 Notion Integration 
 
Connect your Notion workspace to automatically mirror your notes: 
- One **sub-page per course** inside your chosen Notion page. 
- Each video gets an **expandable toggle block** with its name. 
- **Frame captures** are uploaded to Cloudinary and embedded as images. 

 
## 🔒 Platform & Distribution 
 
- **Android Only:** (PIP and orientation features are currently Android-specific). 
- **GitHub Version:** Includes the **TikTok hooking feature**. 
- **Play Store Version:** Does **NOT** include hooking features due to platform policy restrictions. 
 
--- 
 
## 🚀 Upcoming Features 
 
| Feature | Status | 
|---------|--------| 
| 🎥 **YouTube Courses** | Import YouTube playlist URLs into the feed | 
| 🤖 **AI Note Summarization** | Auto-generate summaries for each video | 
| 🌍 **Multi-language Support** | App localization for global users | 
| 🌙 **Light Mode** | Support for system and manual light themes | 
| ⚡ **TikTok UI Elements** | More interactive elements like the native TikTok interface | 
| 📱 **Home Screen Widget** | Add widget support to view current goal from home screen | 
 
--- 
 
## 🛠 Tech Stack 
 
| Category | Libraries | 
|----------|-----------| 
| Video playback | `media_kit`, `media_kit_video` | 
| State management | `flutter_bloc` | 
| Local storage | `hive`, `shared_preferences`, `flutter_secure_storage` | 
| Navigation | `go_router` | 
| Notes sync | `notion_db_sdk` | 
| Image hosting | Cloudinary via `http` | 
| Audio | `record` | 
| PDF export | `pdf`, `printing` | 
| Processing | `ffmpeg_kit_flutter_new` | 
| Firebase | Auth, Analytics, Crashlytics, Messaging, Storage | 
| UI/UX | `android_pip`, `flutter_local_notifications`, `easy_localization` | 
 
--- 
 
## 🏗 Project Structure 
 
```text
lib/
├── core/
│   ├── database/          # Hive storage service
│   ├── services/          # StreakService, Notifications, etc.
│   ├── theme/             # App colors & theme
│   └── utils/             # Helpers, FCM, secure storage
├── features/
│   ├── courses/           # Course & video models, add/profile pages
│   ├── following/         # Following feed logic
│   ├── goals/             # Session goals & persistent notifications
│   ├── home/              # For You feed + AppCubit (main state)
│   ├── liked_videos/      # Liked videos page
│   ├── notes/             # Notes page + Notion service
│   └── settings/          # API keys, preferences, streak
└── widgets/
    └── video_player/      # VideoItem, notes sheet, action buttons