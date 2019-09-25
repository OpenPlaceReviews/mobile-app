import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/i18n/messages.dart';
import 'package:mobile/message_provider.dart';
import 'package:mobile/models/poi.dart';
import 'package:mobile/themes/opr_sizes.dart';
import 'package:mobile/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

import 'poi_context_menu_builder.dart';

abstract class ContextMenuBuilder {
  final BuildContext context;
  final POI poi;
  final Messages messages;
  PersistentBottomSheetController menuController;
  final collapsedStates = <String, bool>{};

  ContextMenuBuilder(this.context, this.poi) : messages = MessageProvider.of(context);

  Widget buildHeader();

  List<Widget> buildRows();

  List<Widget> build() {
    var list = <Widget>[];
    list.add(buildHeader());
    var rows = buildRows();
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        list.add(Divider(
          indent: OPRSizes.list_text_div_indent,
          height: 1,
          color: Theme.of(context).dividerColor,
        ));
      }
      list.add(rows[i]);
    }
    list.add(Divider(
      indent: 0,
      height: 1,
      color: Theme.of(context).dividerColor,
    ));
    return list;
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  _copyToClipboard(String text) async {
    Clipboard.setData(new ClipboardData(text: text));
    showToast("${messages.copiedToClipbpoard}:\n$text", context: context);
  }

  _onExpandCollapse(String id) {
    if (!collapsedStates.containsKey(id)) {
      collapsedStates[id] = true;
    }
    collapsedStates[id] = !collapsedStates[id];
    if (menuController != null) {
      menuController.setState(() {});
    }
  }

  Widget buildRowImg(String name, {Color color}) {
    return UIUtils.getImageIcon(context, name,
        color: color == null ? Theme.of(context).textTheme.subhead.color : color);
  }

  Widget buildRowIcon(IconData data, {Color color}) {
    return Icon(data, size: 24, color: color == null ? Theme.of(context).textTheme.subhead.color : color);
  }

  Widget _buildRow(Widget icon, Widget contentWidget, {VoidCallback onPress, VoidCallback onLongPress}) {
    return new GestureDetector(
      child: FlatButton(
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
                          padding: const EdgeInsets.only(left: OPRSizes.text_content_padding),
                          child: contentWidget,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      onLongPress: () {
        if (onLongPress != null) {
          onLongPress();
        }
      },
    );
  }

  Widget buildTextRow(Widget icon, String text) {
    return _buildRow(icon, Text(text, style: Theme.of(context).textTheme.title),
        onLongPress: () => _copyToClipboard(text));
  }

  Widget buildUrlRow(Widget icon, String text, String url) {
    return _buildRow(icon, Text(text, style: Theme.of(context).textTheme.button),
        onPress: () => _launchURL(url), onLongPress: () => _copyToClipboard(text));
  }

  Widget buildTitleDescrRow(Widget icon, String descr, String text) {
    return _buildRow(
        icon,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(descr, style: Theme.of(context).textTheme.subtitle),
            Text(text, style: Theme.of(context).textTheme.title),
          ],
        ),
        onLongPress: () => _copyToClipboard("$descr\n$text"));
  }

  Widget buildCollapsableRow(String id, Widget icon, String text, Widget collapsableWidget, {bool collapsed = false}) {
    return buildCollapsableRowWidget(id, icon, Text(text, style: Theme.of(context).textTheme.title), collapsableWidget,
        collapsed: collapsed);
  }

  Widget buildCollapsableRowWidget(String id, Widget icon, Widget title, Widget collapsableWidget, {bool collapsed = true}) {
    if (!collapsedStates.containsKey(id)) {
      collapsedStates[id] = collapsed;
    }
    bool collapsedState = collapsedStates[id];
    var arrowImg = buildRowImg(collapsedState ? "ic_arrow_down" : "ic_arrow_up", color: Theme.of(context).accentColor);
    var list = <Widget>[];
    list.add(
      ConstrainedBox(
        constraints: new BoxConstraints(
          minHeight: OPRSizes.list_row_min_height,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Container(
                child: title,
              ),
            ),
            arrowImg,
          ],
        ),
      ),
    );
    if (!collapsedState) {
      list.add(
        ConstrainedBox(
          constraints: new BoxConstraints(
            minHeight: OPRSizes.list_row_min_height,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  child: collapsableWidget,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildRow(icon, Column(crossAxisAlignment: CrossAxisAlignment.start, children: list),
        onPress: () => _onExpandCollapse(id));
  }

  static ContextMenuBuilder getController(BuildContext context, Object obj) {
    if (obj is POI) {
      return POIContextMenuBuilder(context, obj);
    }
    return null;
  }
}
