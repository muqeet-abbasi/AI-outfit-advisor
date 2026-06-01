<div align="center">

<img src="assets/icon/app_icon.png" alt="StyleAI Logo" width="100" height="100" style="border-radius: 20px"/>

<h1>StyleAI</h1>

<p>AI-powered outfit advisor built with Flutter & Google Gemini Vision</p>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Gemini](https://img.shields.io/badge/Gemini-2.5_Flash-4285F4?style=flat-square&logo=google&logoColor=white)](https://ai.google.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)](https://flutter.dev)

</div>

---

## 📱 Demo

<!-- Replace the URL below with your actual video URL -->
> 🎬 **[Watch Full Demo Video](YOUR_VIDEO_URL_HERE)**

[![StyleAI Demo](https://img.youtube.com/vi/YOUR_VIDEO_ID/maxresdefault.jpg)](https://www.youtube.com/watch?v=YOUR_VIDEO_ID)

> **Tip:** Upload your screen recording to YouTube, then paste the video ID above.  
> Or drag a GIF directly into this README on GitHub.

---

## ✦ Screenshots

<div align="center">

| Splash | Home | Analyze | Result |
|--------|------|---------|--------|
| <img src="assets/screenshots/splash.png" width="180"/> | <img src="assets/screenshots/home.png" width="180"/> | <img src="assets/screenshots/analyze.png" width="180"/> | <img src="assets/screenshots/result.png" width="180"/> |

| Style Chat | Outfit Battle | Occasion Planner | Wardrobe Vault |
|------------|---------------|-----------------|----------------|
| <img src="assets/screenshots/chat.png" width="180"/> | <img src="assets/screenshots/compare.png" width="180"/> | <img src="assets/screenshots/planner.png" width="180"/> | <img src="assets/screenshots/vault.png" width="180"/> |

</div>

> Add your screenshots to `assets/screenshots/` and they will appear here automatically.

---

## 🤖 What is StyleAI?

StyleAI is a full-featured AI outfit advisor that uses **Google Gemini Vision** to analyze your outfit from a single photo and deliver instant, expert-level fashion feedback — no stylist required.

**Snap your look. Get your score. Dress better.**

---

## ✨ Features

### 🧠 AI Analysis
- **Style Score** — Rated 0–100 with full breakdown
- **Style Persona** — A creative label for your aesthetic (e.g. *Urban Minimalist*)
- **Color Palette Analysis** — How well your colors work together
- **Fit Assessment** — Honest feedback on proportion and silhouette
- **Occasion Match** — Where your outfit works best
- **Seasonal Advice** — How to adapt your look for any weather

### 💬 Style Chat
Multi-turn conversation with Gemini about your outfit — ask anything:
*"How do I style this for winter?" · "What shoes go with this?" · "How to dress this up?"*

### ⚔️ Outfit Battle
Upload two looks — AI compares them head to head and picks the winner with a detailed verdict, score bar, and reasoning.

### 📅 Occasion Planner
Type any event or pick from presets — AI generates a complete outfit plan with key pieces, color palette, accessories, and what to avoid.

### 🗂️ Wardrobe Vault
Save your analyzed outfits locally with tags, score filters, and favorites. Your personal style history in one place.

### 🎨 Design
Arctic Chrome design system — pure white, ice blue, and ink black throughout. Minimal, sharp, and animated.

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| Language | Dart |
| AI Model | Gemini 2.5 Flash |
| Vision API | Gemini Vision via REST |
| Local Storage | SharedPreferences |
| Animations | flutter_animate |
| Image Picker | image_picker |
| HTTP | http |
| Fonts | Google Fonts — Outfit |
| ID Generation | uuid |

---

## 📁 Project Structure

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart              # Arctic Chrome design system
├── models/
│   ├── outfit_analysis.dart        # Parsed AI response model
│   └── saved_outfit.dart           # Vault item model
├── services/
│   ├── gemini_service.dart         # Gemini Vision API
│   └── vault_service.dart          # Local storage service
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── main_shell.dart             # Bottom nav shell
│   ├── home_screen.dart
│   ├── analyze_screen.dart
│   ├── result_screen.dart
│   ├── style_chat_screen.dart      # Multi-turn AI chat
│   ├── compare_screen.dart         # Outfit Battle
│   ├── occasion_planner_screen.dart
│   ├── history_screen.dart         # Wardrobe Vault
│   ├── vault_detail_screen.dart
│   └── profile_screen.dart
└── widgets/
    ├── loading_overlay.dart        # AI scan animation
    └── suggestion_chip.dart
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.x installed → [Install Flutter](https://docs.flutter.dev/get-started/install)
- A free Gemini API key → [Get API Key](https://aistudio.google.com)

### 1. Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/style-ai-flutter.git
cd style-ai-flutter
```

### 2. Get your free Gemini API key

```
1. Go to https://aistudio.google.com
2. Click "Get API Key" → "Create API key in new project"
3. Copy your key
```

> ⚠️ Free tier limits: **20 requests/day · 5 RPM** on Gemini 2.5 Flash

### 3. Add your API key

Open `lib/services/gemini_service.dart` and replace:

```dart
static const String apiKey = 'YOUR_GEMINI_API_KEY_HERE';
```

### 4. Install dependencies

```bash
flutter pub get
```

### 5. Run the app

```bash
flutter run
```

---

## ⚙️ Permissions

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>StyleAI needs camera access to photograph your outfit</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>StyleAI needs photo library access to select your outfit</string>
```

---

## 📦 Dependencies

```yaml
dependencies:
  flutter_animate: ^4.5.0
  google_fonts: ^6.1.0
  image_picker: ^1.0.7
  http: ^1.2.1
  shared_preferences: ^2.2.2
  permission_handler: ^11.3.0
  uuid: ^4.3.3
  path_provider: ^2.1.3
```

---

## 🔑 API Usage & Limits

This app uses **Gemini 2.5 Flash** on the free tier.

| Tier | Requests/Day | RPM |
|------|-------------|-----|
| Free | 20 | 5 |
| Paid (Tier 1) | 1,000+ | 15+ |

To increase limits, add billing at [aistudio.google.com](https://aistudio.google.com).

The app includes automatic retry logic — 3 attempts with exponential backoff — to handle `503` and `429` errors gracefully.

---

## 🧠 How It Works

```
User uploads photo
        ↓
Image encoded as base64
        ↓
Sent to Gemini Vision API with structured prompt
        ↓
Gemini returns structured JSON response
        ↓
App parses JSON → OutfitAnalysis model
        ↓
Result displayed across 3 tabs: Overview · Analysis · Suggestions
```

---

## 🤝 Contributing

Contributions are welcome. To contribute:

```bash
1. Fork the repo
2. Create a feature branch  →  git checkout -b feature/your-feature
3. Commit your changes      →  git commit -m "Add your feature"
4. Push to the branch       →  git push origin feature/your-feature
5. Open a Pull Request
```

---

## 📄 License

```
MIT License — free to use, modify, and distribute.
See LICENSE file for details.
```

---

## 🙏 Acknowledgements

- [Google Gemini](https://deepmind.google/technologies/gemini/) — Vision AI
- [Flutter](https://flutter.dev) — Cross-platform framework
- [flutter_animate](https://pub.dev/packages/flutter_animate) — Animations
- [Outfit Font](https://fonts.google.com/specimen/Outfit) — Google Fonts

---

<div align="center">

**Built with Flutter · Powered by Gemini Vision**

⭐ Star this repo if you found it useful

</div>
