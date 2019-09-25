import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/opr_context.dart';

import 'themes/opr_sizes.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int diskCacheSize = -1;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final poiTileProvider = OPRContext.instance.poiTileProvider;
    var diskCacheSize = poiTileProvider.getDiskCacheSize();
    diskCacheSize.then((size) {
      this.diskCacheSize = size;
      setState(() {});
    });
    var cacheSize = this.diskCacheSize == -1 ? "..." : filesize(this.diskCacheSize);
    final buttons = <Widget>[
      _buildButton(context, ImageIcon(AssetImage("assets/img/ic_trash.png")), "Clear cache", cacheSize, () {
        var emptyCache = poiTileProvider.emptyCache();
        emptyCache.then((_) {
          this.diskCacheSize = -1;
          setState(() {});
        });
      }),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40, left: 16, bottom: 16, right: 16),
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.left,
          ),
        ),
        /*
        Padding(
          padding: const EdgeInsets.only(top: 0, left: 16, bottom: 16, right: 16),
          child: Text(
              'We are working on providing this functionality. For now, you can join our telegram channels or official forum.',
              style: Theme.of(context).textTheme.display1),
        ),
         */
        Column(
          children: buttons,
        )
      ],
    );
  }

  Widget _buildButton(BuildContext context, Widget icon, String title, String description, VoidCallback onPress) {
    return FlatButton(
      padding: const EdgeInsets.all(0),
      textColor: Theme.of(context).accentColor,
      onPressed: () {
        if (onPress != null) {
          onPress();
        }
      },
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(
                  left: OPRSizes.content_padding,
                  right: OPRSizes.content_padding,
                  top: OPRSizes.content_padding_half,
                  bottom: OPRSizes.content_padding_half),
              child: ConstrainedBox(
                constraints: new BoxConstraints(
                  minHeight: OPRSizes.list_row_min_height,
                ),
                child: Row(
                  children: <Widget>[
                    icon,
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(left: OPRSizes.text_content_padding, top: 8, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: Theme.of(context).textTheme.display2),
                            Text(description, style: Theme.of(context).textTheme.subhead)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
