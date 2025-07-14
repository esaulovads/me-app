import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/profile/screens/onboarding_screen.dart';
import 'features/auth/services/auth_service.dart';
import 'features/profile/services/profile_service.dart';
import 'features/profile/services/performance_monitor.dart';
import 'features/profile/screens/main_screen.dart';

void main() async {
  try {
    print('[INIT] Starting app initialization...');
    
    // Инициализируем Flutter binding перед использованием любых сервисов
    WidgetsFlutterBinding.ensureInitialized();
    print('[INIT] Flutter binding initialized');
    
    // Инициализируем мониторинг производительности
    PerformanceMonitor().initialize();
    print('[INIT] Performance monitor initialized');
    
    print('[INIT] Running app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('[ERROR] Failed to initialize app: $e');
    print('[ERROR] Stack trace: $stackTrace');
    
    // Запускаем приложение без дополнительных сервисов в случае ошибки
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ME App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with PerformanceMonitorMixin {
  final _authService = AuthService();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      await measureAsyncPerformance('Authentication flow', () async {
        // 1. Аутентифицируем пользователя
        final userId = await _authService.authenticate();
        
        // 2. Проверяем заполненность профиля
        final profileService = ProfileService(userId: userId);
        final isProfileComplete = await profileService.isProfileComplete();

        if (mounted) {
          // 3. Направляем пользователя на соответствующий экран
          if (isProfileComplete) {
            // Если профиль заполнен - показываем основной экран
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => MainScreen(userId: userId),
              ),
            );
          } else {
            // Если профиль не заполнен - показываем опросник
            final profile = await profileService.getProfile();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => OnboardingScreen(
                  userId: userId,
                  initialProfile: profile,
                ),
              ),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return measurePerformance('AuthWrapper build', () {
      if (_error != null) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Произошла ошибка:\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _isLoading = true;
                    });
                    _authenticate();
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          ),
        );
      }

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    });
  }
}
