import 'package:intl/intl.dart';

class Messages {
  String get appName => Intl.message('OpenPlaceReviews', name: 'appName');
  String get menuExplore => Intl.message('Explore', name: 'menuExplore');
  String get menuCommunity => Intl.message('Community', name: 'menuCommunity');
  String get menuSaved => Intl.message('Saved', name: 'menuSaved');
  String get menuSettings => Intl.message('Settings', name: 'menuSettings');
  String get copiedToClipbpoard => Intl.message('Copied to clipboard', name: 'copiedToClipbpoard');
}