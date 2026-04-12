# Ghar Ka Khana – Kitchen App

A Flutter mobile application for home cooks to manage their kitchen business, handle orders, and track earnings.

## Features

- 📱 **Phone Authentication** - Login with phone number and OTP verification
- 👨‍🍳 **Kitchen Profile** - Create and manage your kitchen profile
- 🍽️ **Menu Management** - Add, edit, and delete menu items
- 📦 **Order Management** - Accept/reject orders and update status
- 💰 **Earnings Tracking** - View daily earnings and transaction history
- 🔄 **Availability Toggle** - Go online/offline with a simple switch
- 🎨 **Material Design 3** - Clean and modern UI

## Screenshots

The app includes:
- Phone login and OTP verification screens
- Kitchen profile creation and viewing
- Menu list with add/delete functionality
- Orders list with tabs for pending, active, and completed
- Order details with accept/reject actions
- Earnings dashboard with daily summary
- Home dashboard with quick stats

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code with Flutter extensions
- Android Emulator or physical device

### Installation

1. Clone or download this repository
2. Navigate to the project directory:
   ```bash
   cd Cloud_Kitchen
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Demo Credentials

- **Phone Number**: Any 10-digit number starting with 6-9
- **OTP**: 123456 (fixed for demo)

## Project Structure

```
lib/
├── models/              # Data models (Cook, MenuItem, Order, Earnings)
├── services/            # Business logic and data services
├── screens/             # UI screens organized by feature
├── widgets/             # Reusable widgets
├── utils/               # Constants, theme, and dummy data
└── main.dart            # App entry point
```

## Technologies Used

- **Flutter** - UI framework
- **Material Design 3** - Design system
- **SharedPreferences** - Local data storage
- **Dart** - Programming language

## Key Features Explained

### Authentication
- Phone number validation
- OTP verification with resend timer
- Persistent login sessions

### Menu Management
- Add items with name, description, price, quantity, and category
- Delete items with confirmation
- View all menu items in a clean list

### Order Management
- View orders in three tabs: Pending, Active, Completed
- Accept or reject pending orders
- Update order status through the workflow
- View detailed order information

### Earnings
- Daily earnings summary
- Transaction history
- Statistics like average order value and acceptance rate

## Code Quality

- ✅ Well-commented code for beginners
- ✅ Clean architecture with separation of concerns
- ✅ Consistent naming conventions
- ✅ Proper error handling
- ✅ Loading states for async operations

## Future Enhancements

- Backend integration (Firebase/REST API)
- Image upload for menu items
- Push notifications for new orders
- Order history and analytics
- Customer ratings and reviews

## License

This is a demo project for educational purposes.

## Author

Created as a beginner-friendly Flutter application demonstrating best practices in mobile app development.
