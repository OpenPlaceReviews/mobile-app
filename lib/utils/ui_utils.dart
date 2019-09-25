import 'package:flutter/material.dart';

class UIUtils {
  static ImageIcon getImageIcon(BuildContext context, String name, {Color color}) {
    return ImageIcon(AssetImage("assets/img/$name.png"), color: color == null ? Theme.of(context).accentColor : color);
  }
}
