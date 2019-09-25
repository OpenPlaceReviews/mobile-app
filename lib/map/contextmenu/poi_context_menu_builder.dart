import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:location/location.dart';
import 'package:latlong/latlong.dart';
import 'package:mobile/models/poi.dart';
import 'package:mobile/opr_context.dart';
import 'package:mobile/themes/opr_colors.dart';
import 'package:mobile/themes/opr_sizes.dart';
import 'package:mobile/utils/algorithms.dart';
import 'package:mobile/utils/opening_hours_parser.dart';
import 'package:mobile/utils/opr_formatter.dart';

import 'context_menu_builder.dart';

class POIContextMenuBuilder extends ContextMenuBuilder {
  POIContextMenuBuilder(BuildContext context, POI poi) : super(context, poi);

  RichText _getOpeningHoursInfo(String openingHours, TextStyle textStyle) {
    final openingHoursInfo = OpeningHoursParser.getInfo(openingHours);
    final colorOpen = OPRColors.ctxMenuAmenityOpenedTextColor;
    final colorClosed = OPRColors.ctxMenuAmenityClosedTextColor;
    final spans = <TextSpan>[];
    for (var info in openingHoursInfo) {
      spans.add(
        TextSpan(text: info.getInfo(), style: TextStyle(color: info.isOpened() ? colorOpen : colorClosed)),
      );
    }
    if (spans.isNotEmpty) {
      return RichText(
        text: TextSpan(
          style: textStyle,
          children: spans,
        ),
      );
    } else {
      return null;
    }
  }

  @override
  Widget buildHeader() {
    var name = poi.getName();
    var type = poi.getType();
    final saved = false;

    final lines = <Widget>[];
    lines.add(Text(
      name,
      style: Theme.of(context).textTheme.headline,
      textAlign: TextAlign.left,
    ));
    lines.add(Text(
      type,
      style: Theme.of(context).textTheme.subhead,
      textAlign: TextAlign.start,
    ));

    final infoLine = <Widget>[];
    LocationData location = OPRContext.instance.locationProvider.location;
    final openingHours = poi.tags["opening_hours"];
    if (location != null && poi.location != null) {
      final distance = OPRFormatter.formatDistance(
          Distance().distance(new LatLng(location.latitude, location.longitude), poi.location));
      final text = "$distance${openingHours != null ? " • " : ""}";
      infoLine.add(Text(
        text,
        style: Theme.of(context).textTheme.subhead,
        textAlign: TextAlign.start,
      ));
    }
    if (openingHours != null) {
      var openingHoursInfo = _getOpeningHoursInfo(openingHours, Theme.of(context).textTheme.subhead);
      if (openingHoursInfo != null) {
        infoLine.add(Expanded(child: openingHoursInfo));
      }
    }

    lines.add(Row(children: infoLine));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor,
            blurRadius: 1.0, // has the effect of softening the shadow
            spreadRadius: 1.0, // has the effect of extending the shadow
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(OPRSizes.content_padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines,
              ),
            ),
          ),
          /*
          OutlineButton(
            child: buildRowImg(saved ? "ic_action_bookmark" : "ic_action_bookmark_outline",
                color: Theme.of(context).accentColor),
            onPressed: null,
            shape: CircleBorder(side: BorderSide(color: Colors.grey)),
          ),
           */
        ],
      ),
    );
  }

  @override
  List<Widget> buildRows() {
    var rows = <Widget>[];

    var city = "";
    var country = "";
    var housenumber = "";
    var postcode = "";
    var street = "";

    final openingHours = poi.tags["opening_hours"];
    var openingHoursInfo;
    if (openingHours != null) {
      openingHoursInfo = _getOpeningHoursInfo(openingHours, Theme.of(context).textTheme.title);
    }

    poi.tags.forEach((t, v) {
      if (t == "name") {
        // skip;
      } else if (t == "phone") {
        rows.add(buildUrlRow(buildRowImg("ic_call"), v, "tel://$v"));
      } else if (t == "email") {
        rows.add(buildUrlRow(buildRowIcon(Icons.email), v, "mailto:$v"));
      } else if (t == "operator") {
        rows.add(buildTextRow(buildRowIcon(Icons.person), v));
      } else if (t == "website") {
        rows.add(buildUrlRow(buildRowImg("ic_world_globe"), v, v));
      } else if (t == "opening_hours") {
        if (openingHoursInfo != null) {
          rows.add(buildCollapsableRowWidget("opening_hours", buildRowImg("ic_clock"), openingHoursInfo,
              Text(v, style: Theme.of(context).textTheme.title)));
        } else {
          rows.add(buildTextRow(buildRowImg("ic_clock"), v));
        }
      } else if (t.startsWith("addr:country")) {
        country = v;
      } else if (t.startsWith("addr:city")) {
        city = v;
      } else if (t.startsWith("addr:postcode")) {
        postcode = v;
      } else if (t.startsWith("addr:street")) {
        street = v;
      } else if (t.startsWith("addr:housenumber")) {
        housenumber = v;
      } else if (t == "amenity") {
        // get image
      } else {
        rows.add(buildTitleDescrRow(
            buildRowImg("ic_info"), Algorithms.capitalizeFirstLetterAndLowercase(t).replaceAll("_", " "), v));
      }
    });
    var addr = StringBuffer();
    if (street.isNotEmpty) {
      addr.write(street);
      if (housenumber.isNotEmpty) {
        addr.write(", ");
        addr.write(housenumber);
      }
    }
    if (postcode.isNotEmpty) {
      if (addr.isNotEmpty) {
        addr.write(", ");
      }
      addr.write(postcode);
    }
    if (city.isNotEmpty) {
      if (postcode.isNotEmpty) {
        addr.write(", ");
      }
      addr.write(city);
    }
    if (country.isNotEmpty) {
      if (addr.isNotEmpty) {
        addr.write(", ");
      }
      addr.write(country);
    }
    if (addr.isNotEmpty) {
      rows.add(buildTextRow(buildRowIcon(Icons.home), addr.toString()));
    }
    return rows;
  }
}
