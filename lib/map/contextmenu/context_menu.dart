import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile/models/poi.dart';
import 'package:stopper/stopper.dart';

import 'context_menu_builder.dart';

class ContextMenu {
  final BuildContext context;
  final ContextMenuBuilder builder;
  final POI poi;
  PersistentBottomSheetController menuController;

  ContextMenu(this.context, this.poi) : this.builder = ContextMenuBuilder.getController(context, poi);

  void showContextMenu() {
    final h = MediaQuery.of(context).size.height;
    final contextMenuKey = GlobalKey();
    menuController = showStopper(
      key: contextMenuKey,
      context: context,
      stops: [0.4 * h, h],
      builder: (context, scrollController, scrollPhysics, stop) {
        return Container(
          decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 6, offset: Offset(0, -6), spreadRadius: -6.0)]),
          child: ClipRRect(
            borderRadius: stop == 0
                ? BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  )
                : BorderRadius.only(),
            clipBehavior: Clip.antiAlias,
            child: Container(
              color: Theme.of(context).backgroundColor,
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverList(
                    delegate: SliverChildListDelegate(builder.build()),
                  )
                ],
                controller: scrollController,
                physics: scrollPhysics,
              ),
            ),
          ),
        );
      },
    );
    builder.menuController = menuController;
  }
}
