// ====================================================================
// 應用程式根節點 (Application Root)
// ====================================================================
// 這個檔案包含應用程式的最上層 Widget

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'utils/logger.dart';

// 主應用程式類別(Main Application Class)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 設置應用程式方向
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        // 在這裡添加其他的 Provider
      ],
      child: MaterialApp.router(
        title: '營養分析系統',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          AppLogger.instance.d('Building app with route: ${GoRouter.of(context).currentConfiguration.uri.toString()}');
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}
