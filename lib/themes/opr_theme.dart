import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/themes/opr_themes.dart';

class _OPRTheme extends InheritedWidget {
  final OPRThemeState data;

  _OPRTheme({
    this.data,
    Key key,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(_OPRTheme oldWidget) {
    return true;
  }
}

class OPRTheme extends StatefulWidget {
  final Widget child;
  final OPRThemeKeys initialThemeKey;

  const OPRTheme({
    Key key,
    this.initialThemeKey,
    @required this.child,
  }) : super(key: key);

  @override
  OPRThemeState createState() => new OPRThemeState();

  static OPRThemeData of(BuildContext context) {
    _OPRTheme inherited = (context.inheritFromWidgetOfExactType(_OPRTheme) as _OPRTheme);
    return inherited.data.theme;
  }

  static OPRThemeState instanceOf(BuildContext context) {
    _OPRTheme inherited = (context.inheritFromWidgetOfExactType(_OPRTheme) as _OPRTheme);
    return inherited.data;
  }
}

class OPRThemeState extends State<OPRTheme> {
  OPRThemeData _theme;

  OPRThemeData get theme => _theme;

  @override
  void initState() {
    _theme = OPRThemes.getThemeFromKey(widget.initialThemeKey);
    super.initState();
  }

  void changeThemeOnInit(OPRThemeKeys themeKey) {
    _theme = OPRThemes.getThemeFromKey(themeKey);
  }

  void changeTheme(OPRThemeKeys themeKey) {
    setState(() {
      _theme = OPRThemes.getThemeFromKey(themeKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new _OPRTheme(
      data: this,
      child: widget.child,
    );
  }
}
