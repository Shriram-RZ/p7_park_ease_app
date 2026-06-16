import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import 'app_state.dart';
import 'router.dart';

class ParkFlowApp extends StatelessWidget {
  const ParkFlowApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (_, _) => MaterialApp(
          title: 'ParkFlow',
          debugShowCheckedModeBanner: false,
          theme: PFTheme.light(),
          darkTheme: PFTheme.dark(),
          themeMode: state.themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: appOnGenerateRoute,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final scaled = media.textScaler.scale(1.0).clamp(0.85, 1.25);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(scaled.toDouble()),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}
