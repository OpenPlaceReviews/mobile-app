import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'themes/opr_sizes.dart';

class CommunityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      _buildLinkButton(context, ImageIcon(AssetImage("assets/img/ic_world_globe.png")), "Telegram channel - RU",
          "https://t.me/ruopenplacereviews", "https://t.me/ruopenplacereviews"),
      _buildLinkButton(context, ImageIcon(AssetImage("assets/img/ic_world_globe.png")), "Telegram channel - EN",
          "https://t.me/openplacereviews", "https://t.me/openplacereviews"),
      _buildLinkButton(context, ImageIcon(AssetImage("assets/img/ic_forum.png")), "Official Forum",
          "https://forum.openplacereviews.org", "https://forum.openplacereviews.org"),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 40, left: 16, bottom: 16, right: 16),
          child: Text(
            'Community',
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.left,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 0, left: 16, bottom: 16, right: 16),
          child: Text(
              'We are working on providing this functionality. For now, you can join our telegram channels or official forum.',
              style: Theme.of(context).textTheme.display1),
        ),
        Column(
          children: buttons,
        )
      ],
    );
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Widget _buildLinkButton(BuildContext context, Widget icon, String title, String description, String url) {
    return FlatButton(
      padding: const EdgeInsets.all(0),
      textColor: Theme.of(context).accentColor,
      onPressed: () {
        _launchURL(url);
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
