# 🏨 Qora - Hotel Booking App with AI Voice Assistant

A modern Flutter hotel booking application featuring a **Realtime Agentic Voice Assistant** powered by OpenAI's Realtime API.

---

## ✨ Features

### 🏨 Hotel Booking

- Browse hotels by location and dates
- View detailed hotel information
- Book rooms with guest information
- Payment processing
- Booking confirmation and history

### 🎙️ **NEW: Realtime Voice Assistant**

- **Natural conversation** for hotel booking
- **Agentic AI** that understands context and goals
- **Automatic navigation** - AI controls the app
- **8 smart functions** for complete booking flows
- **Real-time audio** streaming via WebRTC
- **Hands-free booking** experience

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.9.2+
- OpenAI API key with Realtime API access
- Android Studio

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/mur-ii/qora.git
   cd qora
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run --dart-define=OPENAI_API_KEY=sk-proj-your-key-here
   ```

### Voice Assistant Setup

For detailed voice assistant setup, see:

- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute setup guide
- **[ENV_SETUP.md](ENV_SETUP.md)** - API key configuration
- **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)** - Complete docs index

---

## 📖 Documentation

| Document                                                   | Purpose                                      |
| ---------------------------------------------------------- | -------------------------------------------- |
| **[DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)**       | 📚 Start here - Complete documentation index |
| **[QUICKSTART.md](QUICKSTART.md)**                         | ⚡ Get running in 5 minutes                  |
| **[ARCHITECTURE.md](ARCHITECTURE.md)**                     | 🏗️ System architecture diagrams              |
| **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** | ✅ What was built                            |
| **[IMPLEMENTATION_NOTES.md](IMPLEMENTATION_NOTES.md)**     | 🔧 Technical deep dive                       |
| **[ENV_SETUP.md](ENV_SETUP.md)**                           | 🔑 API key configuration                     |

---

## 🎯 Voice Assistant Demo

```
You: "Find me a hotel in Bali"
AI: "Sure! When would you like to check in?"

You: "December 25th for 3 nights, 2 guests"
AI: [Automatically searches and navigates to hotel list]
    "I found 2 hotels in Bali. Would you like to see details?"

You: "Show me the first one"
AI: [Navigates to hotel detail page]
    "This is the Grand Luxury Hotel. It has a pool, spa..."

You: "Book a deluxe room"
AI: [Creates booking and navigates to summary]
    "I've created a booking. Please confirm to finalize."

You: "Confirm it"
AI: "Your booking is confirmed! Confirmation number: CONF-12345"
```

---

## 🏗️ Architecture

### Clean Architecture (3 Layers)

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (BLoC, Pages, Widgets)                 │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│            Data Layer                    │
│  (Repositories, DataSources, Services)  │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│          Domain Layer                    │
│  (Entities, UseCases, Repositories)     │
└─────────────────────────────────────────┘
```

### Tech Stack

- **Frontend**: Flutter 3.9.2+
- **State Management**: BLoC Pattern
- **Navigation**: GoRouter
- **Voice AI**: OpenAI Realtime API
- **Audio**: WebRTC (flutter_webrtc)
- **Architecture**: Clean Architecture

---

## 📂 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── di/                  # Dependency injection
│   ├── router/              # App routing
│   ├── services/            # Core services (navigation)
│   ├── theme/               # App theme
│   └── widgets/             # Shared widgets
└── features/
    ├── auth/                # Authentication
    ├── booking/             # Booking management
    ├── home/                # Home screen
    ├── hotel_detail/        # Hotel details
    ├── hotel_list/          # Hotel listings
    ├── profile/             # User profile
    ├── search/              # Search functionality
    └── voice_assistant/     # 🎙️ NEW: Voice AI
        ├── di/              # DI container
        ├── domain/          # Business logic
        ├── data/            # Data layer
        └── presentation/    # UI layer
```

---

## 🧪 Testing

### Run Tests

```bash
flutter test
```

### Test Voice Assistant

1. Launch app
2. Tap "Voice Assistant" button on home screen
3. Grant microphone permission
4. Tap "Start Voice Assistant"
5. Speak: "Find hotels in Paris"
6. Verify:
   - Connection status turns green
   - AI responds with voice
   - App navigates automatically

---

## 🔧 Configuration

### Environment Variables

```bash
# Required for voice assistant
OPENAI_API_KEY=sk-proj-your-key-here
```

### Platform Configuration

**Android** (already configured):

- Microphone permission
- Internet permission
- Audio settings permission
- Bluetooth permission

---

## 📱 Features by Screen

### Home Screen

- Search hotels by location/dates
- Browse promotions
- Explore destinations
- **🎙️ Voice Assistant** floating button

### Voice Assistant Screen

- Real-time conversation interface
- Connection status indicator
- Agent status bar (booking progress)
- Message history with timestamps
- Start/Stop control

### Hotel List

- Search results with filters
- Hotel cards with ratings
- Price display
- Quick booking

### Hotel Detail

- Image gallery
- Amenities list
- Room types
- Reviews
- Book now button

### Booking Flow

- Guest information form
- Payment processing
- Confirmation screen

---

## 🔐 Security

- ✅ API keys via environment variables
- ✅ Runtime permission requests
- ✅ Secure WebRTC (DTLS-SRTP)
- ✅ HTTPS for all API calls
- ✅ Input validation on all functions

---

## 🚀 Deployment

### Android

```bash
flutter build apk --dart-define=OPENAI_API_KEY=your-key
```

### Pre-Deployment Checklist

See [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md#-final-checklist)

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow clean architecture principles
4. Add tests for new features
5. Update documentation
6. Submit pull request

---

## 📄 License

This project is private. All rights reserved.

---

## 👥 Authors

- **mur-ii** - Initial work and voice assistant implementation

---

## 🙏 Acknowledgments

- **OpenAI** - Realtime API
- **Flutter Team** - Flutter framework
- **flutter_webrtc** - WebRTC plugin
- **BLoC Library** - State management

---

## 📞 Support

For issues related to:

- **Voice Assistant**: See [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
- **General App**: Open an issue on GitHub
- **API Keys**: See [ENV_SETUP.md](ENV_SETUP.md)

---

## 🔗 Links

- **Documentation**: [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md)
- **Quick Start**: [QUICKSTART.md](QUICKSTART.md)
- **Architecture**: [ARCHITECTURE.md](ARCHITECTURE.md)
- **OpenAI Realtime API**: https://platform.openai.com/docs/guides/realtime

---

**Built with ❤️ using Flutter and OpenAI Realtime API**
