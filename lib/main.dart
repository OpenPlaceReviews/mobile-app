import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mobile/message_provider.dart';
import 'package:mobile/opr_context.dart';
import 'package:mobile/themes/opr_theme.dart';
import 'package:mobile/themes/opr_themes.dart';
import 'package:mobile/utils/location_provider.dart';
import 'package:mobile/utils/opening_hours_parser.dart';
import 'package:wakelock/wakelock.dart';

import 'home.dart';

void main() => runApp(
      OPRTheme(
        initialThemeKey: OPRThemeKeys.LIGHT,
        child: OpenPlaceReviewsApp(),
      ),
    );

class OpenPlaceReviewsApp extends StatefulWidget {
  const OpenPlaceReviewsApp({Key key}) : super(key: key);

  @override
  _OpenPlaceReviewsAppState createState() => _OpenPlaceReviewsAppState();
}

class _OpenPlaceReviewsAppState extends State<OpenPlaceReviewsApp> with WidgetsBindingObserver {
  OPRContext _appContext;
  LocationProvider _locationProvider;

  _OpenPlaceReviewsAppState() {
    // app initialization
    OpeningHoursParser.instance;
    _appContext = OPRContext.instance;
    _locationProvider = _appContext.locationProvider;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _locationProvider.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        Wakelock.enable();
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        Wakelock.disable();
        break;
      case AppLifecycleState.suspending:
        break;
    }
//    setState(() {
//    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.platformBrightnessOf(context) == ui.Brightness.dark) {
      OPRTheme.instanceOf(context).changeThemeOnInit(OPRThemeKeys.DARK);
    }

    return MaterialApp(
      title: 'OpenPlaceReviews',
      theme: OPRTheme.of(context).baseTheme,
      home: HomePage(),
      localizationsDelegates: [
        const OpenPlaceReviewsLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'), // English
        const Locale('ru'), // Russian
      ],
    );
  }
}
