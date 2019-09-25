import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile/community.dart';
import 'package:mobile/map.dart';
import 'package:mobile/settings.dart';

import 'map/poi_tile_provider.dart';
import 'message_provider.dart';
import 'opr_context.dart';
import 'themes/opr_theme.dart';
import 'themes/opr_themes.dart';
import 'utils/location_provider.dart';
import 'utils/ui_utils.dart';

class HomePage extends StatefulWidget {
  static const String route = '/';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static const String route = '/';

  final CachedPOITileProvider poiTileProvider;
  final LocationProvider locationProvider;

  List<Widget> widgetOptions;

  _HomePageState()
      : poiTileProvider = OPRContext.instance.poiTileProvider,
        locationProvider = OPRContext.instance.locationProvider {
    widgetOptions = <Widget>[
      MapPage(poiTileProvider, locationProvider),
      CommunityPage(),
      SettingsPage(),
    ];
  }

  int selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void changeTheme(BuildContext buildContext, OPRThemeKeys key) {
    OPRTheme.instanceOf(buildContext).changeTheme(key);
  }

  @override
  Widget build(BuildContext context) {
    final messages = MessageProvider.of(context);
    var unselectedBottomBarItemColor = OPRTheme.of(context).unselectedBottomBarItemColor;
    final selectedOptionStyle =
        TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).accentColor);
    final unselectedOptionStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.normal);

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: widgetOptions[selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 10, offset: Offset(0, 15), spreadRadius: 10.0)]),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: UIUtils.getImageIcon(context, "ic_explore_outlined", color: unselectedBottomBarItemColor),
              activeIcon: UIUtils.getImageIcon(context, "ic_explore_outlined"),
              title: Text(messages.menuExplore),
            ),
            BottomNavigationBarItem(
              icon: UIUtils.getImageIcon(context, "ic_account", color: unselectedBottomBarItemColor),
              activeIcon: UIUtils.getImageIcon(context, "ic_account"),
              title: Text(messages.menuCommunity),
            ),
            /*
            BottomNavigationBarItem(
              icon: UIUtils.getImageIcon(context, "ic_action_bookmark",
                  color: unselectedBottomBarItemColor),
              activeIcon: UIUtils.getImageIcon(context, "ic_action_bookmark"),
              title: Text(messages.menuSaved),
            ),
             */
            BottomNavigationBarItem(
              icon: UIUtils.getImageIcon(context, "ic_action_settings", color: unselectedBottomBarItemColor),
              activeIcon: UIUtils.getImageIcon(context, "ic_action_settings"),
              title: Text(messages.menuSettings),
            ),
          ],
          currentIndex: selectedIndex,
          backgroundColor: Theme.of(context).bottomAppBarColor,
          selectedItemColor: Theme.of(context).accentColor,
          unselectedItemColor: unselectedBottomBarItemColor,
          onTap: onItemTapped,
          selectedLabelStyle: selectedOptionStyle,
          unselectedLabelStyle: unselectedOptionStyle,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
