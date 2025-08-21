# NewsApp

![Swift](https://img.shields.io/badge/Swift-5.7+-FA7343?logo=swift)
![iOS](https://img.shields.io/badge/iOS-15%2B-F56565?logo=apple)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Primary-FFAC45?logo=swift)

> A professional-grade iOS news application built with **Swift** and **SwiftUI** for portfolio demonstration. Showcases modern iOS development practices including authentication flows, media-rich content rendering, and subscription business models.

## 🌟 Features

- **Secure Authorization**
  - Sign-in/Sign-up with email
  - Password recovery feature

- **News Experience**
  - Infinite-scrolling news feed with pull-to-refresh
  - Article detail screen supporting:
    - Embedded images with pinch-to-zoom
    - Native video players
    - Social media post embeddings (Youtube/Instagram etc)
  - Dedicated full-screen image viewer

- **Monetization System**
  - Tiered content access (free/premium)
  - In-app purchase for individual articles
  - Subscription management (monthly/annual)
  - Restore purchases functionality

- **Interactive Polling**
  - Authenticated voting for political events
  - Identity verification layer
  - Real-time results visualization

- **User Customization**
  - Language switching (multi-language support)
  - Notification preferences
  - Dark/light mode compatibility
  - Accessibility features

## 🛠 Tech Stack

| Category       | Technologies                                                                 |
|----------------|----------------------------------------------------------------------------|
| Core           | Swift 5.0+, SwiftUI, Combine                                               |
| Architecture   | MVVM, Coordinator Pattern, State Management                                |
| Networking     | Async/Await, URLSession, Codable                                           |
| Persistence    | UserDefaults, Core Data (for offline caching)                              |
| Security       | Keychain Services, Firebase Auth                                           |
| Analytics      | Firebase Analytics (for portfolio demonstration)                           |

## 🚀 Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nurmaj/NewsApp.git
