# Project Structure

## Feature-Based Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   └── strings.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── text_styles.dart
│   ├── utils/
│   │   ├── extensions.dart
│   │   └── validators.dart
│   ├── errors/
│   │   └── failures.dart
│   └── di/                         
│       └── injection_container.dart 
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   ├── datasources/
│   │   │   └── models/          
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/      
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── bloc/              
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── screens/
│   │       └── widgets/
│   └── home/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           ├── bloc/
│           ├── screens/
│           └── widgets/
├── shared/
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── inputs/
│   │   └── cards/
│   └── services/
│       ├── api_service.dart
│       └── storage_service.dart
└── routes/
    └── app_router.dart
```

## pubspec.yaml Essentials

```yaml
dependencies:
  flutter:
    sdk: flutter

  # UI & Navigation
  cupertino_icons: ^1.0.8
  go_router: ^17.0.1
  lottie: ^3.3.2
  cached_network_image: ^3.4.1
  syncfusion_flutter_datepicker: ^32.1.23
  persistent_bottom_nav_bar: ^6.2.1
  toastification: ^3.0.3
  draggable_float_widget: ^0.1.0

  # Networking & Dependency Injection
  http: ^1.6.0
  get_it: ^7.7.0                     

  # Storage & Data
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  csv: ^6.0.0
  flutter_dotenv: ^5.2.1

  # State management & Core
  flutter_bloc: ^9.1.1
  equatable: ^2.0.8
  intl: ^0.20.2
  logger: ^2.6.2                     

  # Code Generation Annotations 
  freezed_annotation: ^2.4.1         
  json_annotation: ^4.9.0           

  # WebRTC & Voice Assistant
  flutter_webrtc: ^0.12.8
  permission_handler: ^11.3.1
  path_provider: ^2.1.5

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^5.0.0
  build_runner: ^2.4.13
  hive_generator: ^2.0.1
  freezed: ^2.5.2                   
  json_serializable: ^6.8.0          

  # Testing packages
  mocktail: ^1.0.4                   
```

## Feature Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **data/** | Implementation API calls, local storage, DTO/Models, and implementasi repository |
| **domain/** | Business logic, Entities murni, Abstract repository, and Use cases |
| **presentation/** | UI screens, widgets, and BLoC / Cubit (State Management) |
| **core/di/** | Registration dependencies (get_it) for Repository, UseCase, and BLoC |

## Main Entry Point

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables (.env) untuk keamanan API Key AI
  await dotenv.load(fileName: ".env");

  // Inisialisasi Storage (Hive)
  await Hive.initFlutter();
  
  // Inisialisasi Dependency Injection (GetIt)
  await di.init(); 

  runApp(const MyApp());
}

// app.dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          // 'sl' adalah Service Locator dari get_it
          create: (_) => sl<AuthBloc>(), 
        ),
        // Daftarkan BLoC global lainnya di sini jika ada
      ],
      child: MaterialApp.router(
        routerConfig: appRouter, // Konfigurasi go_router
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```