import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'i18n/messages.dart';
import 'i18n/messages_all.dart';

class MessageProvider {
  MessageProvider(this.messages);
  final Messages messages;

  static Future<MessageProvider> load(Locale locale) {
    final String name =
        locale.countryCode == null || locale.countryCode.isEmpty ? locale.languageCode : locale.toString();
    final String localeName = Intl.canonicalizedLocale(name);

    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return MessageProvider(Messages());
    });
  }

  static Messages of(BuildContext context) {
    return Localizations.of<MessageProvider>(context, MessageProvider).messages;
  }
}

class OpenPlaceReviewsLocalizationsDelegate
    extends LocalizationsDelegate<MessageProvider> {
  const OpenPlaceReviewsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ru'].contains(locale.languageCode);

  @override
  Future<MessageProvider> load(Locale locale) => MessageProvider.load(locale);

  @override
  bool shouldReload(OpenPlaceReviewsLocalizationsDelegate old) => false;
}
