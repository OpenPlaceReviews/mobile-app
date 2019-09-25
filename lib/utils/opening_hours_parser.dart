import 'dart:core';

import 'package:intl/intl.dart';
import 'package:quiver/strings.dart';

import 'algorithms.dart';

final int _lowTimeLimit = 120;
final int _withoutTimeLimit = -1;
final int _currentDayTimeLimit = -2;

/// Class used to parse opening hours
/// <p/>
/// the method "parseOpenedHours" will parse an OSM opening_hours string and
/// return an object of the type OpeningHours. That object can be used to check
/// if the OSM feature is open at a certain time.
class OpeningHoursParser {
  static final _daysStr = <String>[];
  static final _localDaysStr = <String>[];
  static final _monthsStr = <String>[];
  static final _localMothsStr = <String>[];
  static final _additionalStrings = <String, String>{};

  static final OpeningHoursParser _instance = OpeningHoursParser._privateConstructor();

  static OpeningHoursParser get instance => _instance;

  OpeningHoursParser._privateConstructor() {
    var dateFormatSymbols = DateFormat("en_US").dateSymbols;
    _monthsStr.addAll(dateFormatSymbols.SHORTMONTHS);
    _daysStr.addAll(getLettersStringArray(dateFormatSymbols.SHORTWEEKDAYS, 2));

    dateFormatSymbols = DateFormat().dateSymbols;
    _localMothsStr.addAll(dateFormatSymbols.SHORTMONTHS);
    _localDaysStr.addAll(getLettersStringArray(dateFormatSymbols.SHORTWEEKDAYS, 3));

    _additionalStrings["off"] = "off";
    _additionalStrings["is_open"] = "Open";
    _additionalStrings["is_open_24_7"] = "Open 24/7";
    _additionalStrings["will_open_at"] = "Will open at";
    _additionalStrings["open_from"] = "Open from";
    _additionalStrings["will_close_at"] = "Will close at";
    _additionalStrings["open_till"] = "Open till";
    _additionalStrings["will_open_tomorrow_at"] = "Will open tomorrow at";
    _additionalStrings["will_open_on"] = "Will open on";
  }

  /// Set additional localized strings like "off", etc.
  static void _setAdditionalString(String key, String value) {
    _additionalStrings[key] = value;
  }

  /// Default values for sunrise and sunset. Might be computed afterwards, not final.
  static var _sunrise = "07:00";
  static var _sunset = "21:00";

  /// Hour of when you would expect a day to be ended.
  /// This is to be used when no end hour is known (like pubs that open at a certain time,
  /// but close at a variable time, depending on the number of clients).
  /// OsmAnd needs to show a value, so there is some arbitrary default value chosen.
  static var _endOfDay = "24:00";

  static List<String> getLettersStringArray(List<String> strings, int letters) {
    var newStrings = List<String>(strings.length);
    for (int i = 0; i < strings.length; i++) {
      if (strings[i] != null) {
        if (strings[i].length > letters) {
          newStrings[i] = Algorithms.capitalizeFirstLetter(strings[i].substring(0, letters));
        } else {
          newStrings[i] = Algorithms.capitalizeFirstLetter(strings[i]);
        }
      }
    }
    return newStrings;
  }

  static int _getDayIndex(int i) {
    return (i + 1) % 7;
  }

  static parseRuleV2(String r, int sequenceIndex, List<OpeningHoursRule> rules) {
    String comment;
    int q1Index = r.indexOf('"');
    if (q1Index >= 0) {
      int q2Index = r.indexOf('"', q1Index + 1);
      if (q2Index >= 0) {
        comment = r.substring(q1Index + 1, q2Index);
        var a = r.substring(0, q1Index);
        var b = "";
        if (r.length > q2Index + 1) {
          b = r.substring(q2Index + 1);
        }
        r = a + b;
      }
    }
    r = r.toLowerCase().trim();

    final daysStr = ["mo", "tu", "we", "th", "fr", "sa", "su"];
    final monthsStr = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"];
    final holidayStr = ["ph", "sh", "easter"];
    final sunrise = "07:00";
    final sunset = "21:00";
    final endOfDay = "24:00";
    r = r.replaceAll('(', ' '); // avoid "(mo-su 17:00-20:00"
    r = r.replaceAll(')', ' ');
    String localRuleString =
        r.replaceAll("sunset", sunset).replaceAll("sunrise", sunrise).replaceAll("\\+", "-" + endOfDay);
    final basic = BasicOpeningHourRule.withSequenceIndex(sequenceIndex);
    basic.setComment(comment);
    final days = basic.getDays();
    final months = basic.getMonths();
    //bool[][] dayMonths = basic.getDayMonths();
    if ("24/7" == localRuleString) {
      days.fillRange(0, days.length, true);
      basic._hasDays = true;
      months.fillRange(0, months.length, true);
      basic.addTimeRange(0, 24 * 60);
      rules.add(basic);
      return;
    }
    final tokens = <_Token>[];
    int startWord = 0;
    for (int i = 0; i <= localRuleString.length; i++) {
      var ch = (i == localRuleString.length ? ' ' : localRuleString[i]);
      bool delimiter = false;
      _Token del;
      if (isWhitespace(ch.codeUnitAt(0))) {
        delimiter = true;
      } else if (ch == ':') {
        del = _Token(_TokenType.tokenColon, ":");
      } else if (ch == '-') {
        del = _Token(_TokenType.tokenDash, "-");
      } else if (ch == ',') {
        del = _Token(_TokenType.tokenComma, ",");
      }
      if (delimiter || del != null) {
        String wrd = localRuleString.substring(startWord, i).trim();
        if (wrd.length > 0) {
          tokens.add(_Token(_TokenType.tokenUnknown, wrd));
        }
        startWord = i + 1;
        if (del != null) {
          tokens.add(del);
        }
      }
    }
    // recognize day of week
    for (final t in tokens) {
      if (t.type == _TokenType.tokenUnknown) {
        _findInArray(t, daysStr, _TokenType.tokenDayWeek);
      }
      if (t.type == _TokenType.tokenUnknown) {
        _findInArray(t, monthsStr, _TokenType.tokenMonth);
      }
      if (t.type == _TokenType.tokenUnknown) {
        _findInArray(t, holidayStr, _TokenType.tokenHoliday);
      }
      if (t.type == _TokenType.tokenUnknown && ("off" == t.text || "closed" == t.text)) {
        t.type = _TokenType.tokenOffOn;
        t.mainNumber = 0;
      }
      if (t.type == _TokenType.tokenUnknown && ("24/7" == t.text || "open" == t.text)) {
        t.type = _TokenType.tokenOffOn;
        t.mainNumber = 1;
      }
    }
    // recognize hours minutes ( Dec 25: 08:30-20:00)
    for (int i = tokens.length - 1; i >= 0; i--) {
      if (tokens[i].type == _TokenType.tokenColon) {
        if (i > 0 && i < tokens.length - 1) {
          if (tokens[i - 1].type == _TokenType.tokenUnknown &&
              tokens[i - 1].mainNumber != -1 &&
              tokens[i + 1].type == _TokenType.tokenUnknown &&
              tokens[i + 1].mainNumber != -1) {
            tokens[i].mainNumber = 60 * tokens[i - 1].mainNumber + tokens[i + 1].mainNumber;
            tokens[i].type = _TokenType.tokenHourMinutes;
            tokens.removeAt(i + 1);
            tokens.removeAt(i - 1);
          }
        }
      }
    }
    // recognize other numbers
    bool monthSpecified = false;
    for (_Token t in tokens) {
      if (t.type == _TokenType.tokenMonth) {
        monthSpecified = true;
        break;
      }
    }
    for (int i = 0; i < tokens.length; i++) {
      _Token t = tokens[i];
      if (t.type == _TokenType.tokenUnknown && t.mainNumber >= 0) {
        if (monthSpecified && t.mainNumber <= 31) {
          t.type = _TokenType.tokenDayMonth;
          t.mainNumber = t.mainNumber - 1;
        } else if (t.mainNumber > 1000) {
          t.type = _TokenType.tokenYear;
        }
      }
    }
    _buildRule(basic, tokens, rules);
  }

  static _buildRule(BasicOpeningHourRule basic, List<_Token> tokens, List<OpeningHoursRule> rules) {
    // order MONTH MONTH_DAY DAY_WEEK HOUR_MINUTE OPEN_OFF
    _TokenType currentParse = _TokenType.tokenUnknown;
    _TokenType currentParseParent = _TokenType.tokenUnknown;
    var listOfPairs = <List<_Token>>[];
    var presentTokens = <_TokenType>{};
    var currentPair = List<_Token>(2);
    listOfPairs.add(currentPair);
    _Token prevToken;
    _Token prevYearToken;
    int indexP = 0;
    for (int i = 0; i <= tokens.length; i++) {
      _Token t = i == tokens.length ? null : tokens[i];
      if (i == 0 && t != null && t.type == _TokenType.tokenUnknown) {
        // skip rule if the first token unknown
        return;
      }
      if (t == null || _getTokenTypeOrd(t.type) > _getTokenTypeOrd(currentParse)) {
        presentTokens.add(currentParse);
        if (currentParse == _TokenType.tokenMonth ||
            currentParse == _TokenType.tokenDayMonth ||
            currentParse == _TokenType.tokenDayWeek ||
            currentParse == _TokenType.tokenHoliday) {
          bool tokenDayMonth = currentParse == _TokenType.tokenDayMonth;
          List<bool> array =
              (currentParse == _TokenType.tokenMonth) ? basic.getMonths() : tokenDayMonth ? null : basic.getDays();
          for (var pair in listOfPairs) {
            if (pair[0] != null && pair[1] != null) {
              _Token firstMonthToken = pair[0].parent;
              _Token lastMonthToken = pair[1].parent;
              if (tokenDayMonth && firstMonthToken != null) {
                if (lastMonthToken != null && lastMonthToken.mainNumber != firstMonthToken.mainNumber) {
                  var p = <_Token>[firstMonthToken, lastMonthToken];
                  _fillRuleArray(basic.getMonths(), p);

                  var t1 = _Token.withMainNumber(_TokenType.tokenDayMonth, pair[0].mainNumber);
                  var t2 = _Token.withMainNumber(_TokenType.tokenDayMonth, 30);
                  p = <_Token>[t1, t2];
                  array = basic.getDayMonths(firstMonthToken.mainNumber);
                  _fillRuleArray(array, p);

                  t1 = _Token.withMainNumber(_TokenType.tokenDayMonth, 0);
                  t2 = _Token.withMainNumber(_TokenType.tokenDayMonth, pair[1].mainNumber);
                  p = <_Token>[t1, t2];
                  array = basic.getDayMonths(lastMonthToken.mainNumber);
                  _fillRuleArray(array, p);

                  if (firstMonthToken.mainNumber <= lastMonthToken.mainNumber) {
                    for (int month = firstMonthToken.mainNumber + 1; month < lastMonthToken.mainNumber; month++) {
                      var dayMonths = basic.getDayMonths(month);
                      dayMonths.fillRange(0, dayMonths.length, true);
                    }
                  } else {
                    for (int month = firstMonthToken.mainNumber + 1; month < 12; month++) {
                      var dayMonths = basic.getDayMonths(month);
                      dayMonths.fillRange(0, dayMonths.length, true);
                    }
                    for (int month = 0; month < lastMonthToken.mainNumber; month++) {
                      var dayMonths = basic.getDayMonths(month);
                      dayMonths.fillRange(0, dayMonths.length, true);
                    }
                  }
                } else {
                  array = basic.getDayMonths(firstMonthToken.mainNumber);
                  _fillRuleArray(array, pair);
                }
              } else if (array != null) {
                _fillRuleArray(array, pair);
              }
              int ruleYear = basic._year;
              if ((ruleYear > 0 || prevYearToken != null) && firstMonthToken != null && lastMonthToken != null) {
                int length = lastMonthToken.mainNumber > firstMonthToken.mainNumber
                    ? lastMonthToken.mainNumber - firstMonthToken.mainNumber
                    : 12 - firstMonthToken.mainNumber + lastMonthToken.mainNumber;
                int month = firstMonthToken.mainNumber;
                int endYear = prevYearToken != null ? prevYearToken.mainNumber : ruleYear;
                int startYear = ruleYear > 0 ? ruleYear : endYear;
                int year = startYear;
                if (basic._firstYearMonths == null) {
                  basic._firstYearMonths = List<int>.filled(12, 0);
                }
                var yearMonths = basic._firstYearMonths;
                int k = 0;
                while (k <= length) {
                  yearMonths[month++] = year;
                  if (month > 11) {
                    month = 0;
                    year = endYear;
                    if (basic._lastYearMonths == null) {
                      basic._lastYearMonths = List<int>.filled(12, 0);
                    }
                    yearMonths = basic._lastYearMonths;
                  }
                  k++;
                }
                if (endYear - startYear > 1) {
                  basic._fullYears = endYear - startYear - 1;
                }
                if (endYear > startYear && firstMonthToken.mainNumber >= lastMonthToken.mainNumber) {
                  //basic.dayMonths = null;
                  basic._months.fillRange(0, basic._months.length, true);
                }
              }
            } else if (pair[0] != null) {
              if (pair[0].type == _TokenType.tokenHoliday) {
                if (pair[0].mainNumber == 0) {
                  basic._publicHoliday = true;
                } else if (pair[0].mainNumber == 1) {
                  basic._schoolHoliday = true;
                } else if (pair[0].mainNumber == 2) {
                  basic._easter = true;
                }
              } else if (pair[0].mainNumber >= 0) {
                _Token firstMonthToken = pair[0].parent;
                if (tokenDayMonth && firstMonthToken != null) {
                  array = basic.getDayMonths(firstMonthToken.mainNumber);
                }
                if (array != null) {
                  array[pair[0].mainNumber] = true;
                  if (prevYearToken != null) {
                    basic._year = prevYearToken.mainNumber;
                  }
                }
              }
            }
          }
        } else if (currentParse == _TokenType.tokenHourMinutes) {
          for (var pair in listOfPairs) {
            if (pair[0] != null && pair[1] != null) {
              basic.addTimeRange(pair[0].mainNumber, pair[1].mainNumber);
            }
          }
        } else if (currentParse == _TokenType.tokenOffOn) {
          var l = listOfPairs[0];
          if (l[0] != null && l[0].mainNumber == 0) {
            basic._off = true;
          }
        } else if (currentParse == _TokenType.tokenYear) {
          var l = listOfPairs[0];
          if (l[0] != null && l[0].mainNumber > 1000) {
            prevYearToken = l[0];
          }
        }
        listOfPairs.clear();
        currentPair = List<_Token>(2);
        indexP = 0;
        listOfPairs.add(currentPair);
        currentPair[indexP++] = t;
        if (t != null) {
          currentParse = t.type;
          currentParseParent = currentParse;
          if (t.type == _TokenType.tokenDayMonth && prevToken != null && prevToken.type == _TokenType.tokenMonth) {
            t.parent = prevToken;
            currentParseParent = prevToken.type;
          }
        }
      } else if (_getTokenTypeOrd(t.type) < _getTokenTypeOrd(currentParseParent) && indexP == 0 && tokens.length > i) {
        BasicOpeningHourRule newRule = BasicOpeningHourRule.withSequenceIndex(basic.getSequenceIndex());
        newRule.setComment(basic.getComment());
        _buildRule(newRule, tokens.sublist(i, tokens.length), rules);
        tokens = tokens.sublist(0, i + 1);
      } else if (t.type == _TokenType.tokenComma) {
        if (tokens.length > i + 1 &&
            tokens[i + 1] != null &&
            _getTokenTypeOrd(tokens[i + 1].type) < _getTokenTypeOrd(currentParseParent)) {
          indexP = 0;
        } else {
          currentPair = List<_Token>(2);
          indexP = 0;
          listOfPairs.add(currentPair);
        }
      } else if (t.type == _TokenType.tokenDash) {
      } else if (t.type == _TokenType.tokenYear) {
        prevYearToken = t;
      } else if (_getTokenTypeOrd(t.type) == _getTokenTypeOrd(currentParse)) {
        if (indexP < 2) {
          currentPair[indexP++] = t;
          if (t.type == _TokenType.tokenDayMonth && prevToken != null && prevToken.type == _TokenType.tokenMonth) {
            t.parent = prevToken;
          }
        }
      }
      prevToken = t;
    }
    if (!presentTokens.contains(_TokenType.tokenMonth)) {
      var months = basic.getMonths();
      months.fillRange(0, months.length, true);
    }
    if (!presentTokens.contains(_TokenType.tokenDayWeek) &&
        !presentTokens.contains(_TokenType.tokenHoliday) &&
        !presentTokens.contains(_TokenType.tokenDayMonth)) {
      var days = basic.getDays();
      days.fillRange(0, days.length, true);
      basic._hasDays = true;
    } else if (presentTokens.contains(_TokenType.tokenDayWeek)) {
      basic._hasDays = true;
    }
    rules.insert(0, basic);
  }

  static _fillRuleArray(List<bool> array, List<_Token> pair) {
    if (pair[0].mainNumber <= pair[1].mainNumber) {
      for (int j = pair[0].mainNumber; j <= pair[1].mainNumber && j < array.length; j++) {
        array[j] = true;
      }
    } else {
      // overflow
      for (int j = pair[0].mainNumber; j < array.length; j++) {
        array[j] = true;
      }
      for (int j = 0; j <= pair[1].mainNumber; j++) {
        array[j] = true;
      }
    }
  }

  static _findInArray(_Token t, List<String> list, _TokenType tokenType) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] == t.text) {
        t.type = tokenType;
        t.mainNumber = i;
        break;
      }
    }
  }

  static List<List<String>> splitSequences(String format) {
    if (format == null) {
      return null;
    }
    var res = <List<String>>[];
    var sequences = format.split("\|\|");
    for (String seq in sequences) {
      seq = seq.trim();
      if (seq.isEmpty) {
        continue;
      }

      var rules = <String>[];
      bool comment = false;
      var sb = StringBuffer();
      for (int i = 0; i < seq.length; i++) {
        var c = seq[i];
        if (c == '"') {
          comment = !comment;
          sb.write(c);
        } else if (c == ';' && !comment) {
          if (sb.isNotEmpty) {
            String s = sb.toString().trim();
            if (s.isNotEmpty) {
              rules.add(s);
            }
            sb.clear();
          }
        } else {
          sb.write(c);
        }
      }
      if (sb.isNotEmpty) {
        rules.add(sb.toString());
        sb.clear();
      }
      res.add(rules);
    }
    return res;
  }

  /// Parse an opening_hours string from OSM to an OpeningHours object which can be used to check
  ///
  /// @param r the string to parse
  /// @return BasicRule if the String is successfully parsed and UnparseableRule otherwise
  static parseRules(String r, int sequenceIndex, List<OpeningHoursRule> rules) {
    parseRuleV2(r, sequenceIndex, rules);
  }

  /// parse OSM opening_hours string to an OpeningHours object
  ///
  /// @param format the string to parse
  /// @return null when parsing was unsuccessful
  static OpeningHours parseOpenedHours(String format) {
    if (format == null) {
      return null;
    }
    OpeningHours rs = OpeningHours();
    rs.setOriginal(format);
    // split the OSM string in multiple rules
    List<List<String>> sequences = splitSequences(format);
    for (int i = 0; i < sequences.length; i++) {
      List<String> rules = sequences[i];
      var basicRules = <BasicOpeningHourRule>[];
      for (String r in rules) {
        // check if valid
        var rList = <OpeningHoursRule>[];
        parseRules(r, i, rList);
        for (OpeningHoursRule rule in rList) {
          if (rule is BasicOpeningHourRule) {
            basicRules.add(rule);
          }
        }
      }
      String basicRuleComment;
      if (sequences.length > 1) {
        for (BasicOpeningHourRule bRule in basicRules) {
          if (!Algorithms.isEmpty(bRule.getComment())) {
            basicRuleComment = bRule.getComment();
            break;
          }
        }
      }
      if (!Algorithms.isEmpty(basicRuleComment)) {
        for (BasicOpeningHourRule bRule in basicRules) {
          bRule.setComment(basicRuleComment);
        }
      }
      rs.addRules(basicRules);
    }
    rs.setSequenceCount(sequences.length);
    return rs._rules.length > 0 ? rs : null;
  }

  /// parse OSM opening_hours string to an OpeningHours object.
  /// Does not return null when parsing unsuccessful. When parsing rule is unsuccessful,
  /// such rule is stored as UnparseableRule.
  ///
  /// @param format the string to parse
  /// @return the OpeningHours object
  static OpeningHours parseOpenedHoursHandleErrors(String format) {
    if (format == null) {
      return null;
    }
    final rs = OpeningHours();
    rs.setOriginal(format);
    List<List<String>> sequences = splitSequences(format);
    for (int i = sequences.length - 1; i >= 0; i--) {
      List<String> rules = sequences[i];
      for (var r in rules) {
        r = r.trim();
        if (r.length == 0) {
          continue;
        }
        // check if valid
        var rList = <OpeningHoursRule>[];
        parseRules(r, i, rList);
        rs.addRules(rList);
      }
    }
    rs.setSequenceCount(sequences.length);
    return rs;
  }

  static List<Info> getInfo(String format) {
    final openingHours = OpeningHoursParser.parseOpenedHours(format);
    if (openingHours == null) {
      return null;
    } else {
      return openingHours.getInfo();
    }
  }

  static _formatTime(int h, int t, StringBuffer b) {
    if (h < 10) {
      b.write("0");
    }
    b.write(h);
    b.write(":");
    if (t < 10) {
      b.write("0");
    }
    b.write(t);
  }

  static void _formatTimeMinutes(int minutes, StringBuffer sb) {
    int hour = (minutes / 60).floor();
    int time = minutes - hour * 60;
    _formatTime(hour, time, sb);
  }
}

class Info {
  bool _opened = false;
  bool _opened24_7 = false;
  String _openingTime;
  String _nearToOpeningTime;
  String _closingTime;
  String _nearToClosingTime;
  String _openingTomorrow;
  String _openingDay;
  String _ruleString;

  bool isOpened() {
    return _opened;
  }

  bool isOpened24_7() {
    return _opened24_7;
  }

  String getInfo() {
    var additionalStrings = OpeningHoursParser._additionalStrings;
    if (isOpened24_7()) {
      if (!Algorithms.isEmpty(_ruleString)) {
        return "${additionalStrings["is_open"]} $_ruleString";
      } else {
        return additionalStrings["is_open_24_7"];
      }
    } else if (!Algorithms.isEmpty(_nearToOpeningTime)) {
      return additionalStrings["will_open_at"] + " " + _nearToOpeningTime;
    } else if (!Algorithms.isEmpty(_openingTime)) {
      return "${additionalStrings["open_from"]} $_openingTime";
    } else if (!Algorithms.isEmpty(_nearToClosingTime)) {
      return "${additionalStrings["will_close_at"]} $_nearToClosingTime";
    } else if (!Algorithms.isEmpty(_closingTime)) {
      return "${additionalStrings["open_till"]} $_closingTime";
    } else if (!Algorithms.isEmpty(_openingTomorrow)) {
      return "${additionalStrings["will_open_tomorrow_at"]} $_openingTomorrow";
    } else if (!Algorithms.isEmpty(_openingDay)) {
      return "${additionalStrings["will_open_on"]} $_openingDay.";
    } else if (!Algorithms.isEmpty(_ruleString)) {
      return _ruleString;
    } else {
      return "";
    }
  }
}

/// Interface to represent a single rule
/// <p/>
/// A rule consist out of
/// - a collection of days/dates
/// - a time range
abstract class OpeningHoursRule {
  /// Check if, for this rule, the feature is opened for time "cal"
  ///
  /// @param cal           the time to check
  /// @param checkPrevious only check for overflowing times (after midnight) or don't check for it
  /// @return true if the feature is open
  bool isOpenedForTimeCheckPrev(DateTime cal, bool checkPrevious);

  /// Check if, for this rule, the feature is opened for time "cal"
  /// @param cal
  /// @return true if the feature is open
  bool isOpenedForTime(DateTime cal);

  /// Check if the previous day before "cal" is part of this rule
  ///
  /// @param cal; the time to check
  /// @return true if the previous day is part of the rule
  bool containsPreviousDay(DateTime cal);

  /// Check if the day of "cal" is part of this rule
  ///
  /// @param cal the time to check
  /// @return true if the day is part of the rule
  bool containsDay(DateTime cal);

  /// Check if the next day after "cal" is part of this rule
  ///
  /// @param cal the time to check
  /// @return true if the next day is part of the rule
  bool containsNextDay(DateTime cal);

  /// Check if the month of "cal" is part of this rule
  ///
  /// @param cal the time to check
  /// @return true if the month is part of the rule
  bool containsMonth(DateTime cal);

  /// Check if the year of "cal" is part of this rule
  ///
  /// @param cal the time to check
  /// @return true if the year is part of the rule
  bool containsYear(DateTime cal);

  /// @return true if the rule overlap to the next day
  bool hasOverlapTimes();

  /// Check if r rule times overlap with this rule times at "cal" date.
  ///
  /// @param cal the date to check
  /// @param r the rule to check
  /// @return true if the this rule times overlap with r times
  bool hasOverlapTimesRule(DateTime cal, OpeningHoursRule r);

  /// @param cal
  /// @return true if rule applies for current time
  bool contains(DateTime cal);

  int getSequenceIndex();

  String toRuleString();

  String toLocalRuleString();

  bool isOpened24_7();

  String getTime(DateTime cal, bool checkAnotherDay, int limit, bool opening);
}

/// implementation of the basic OpeningHoursRule
/// <p/>
/// This implementation only supports month, day of weeks and numeral times, or the value "off"
class BasicOpeningHourRule extends OpeningHoursRule {
  /// represents the list on which days it is open.
  /// Day number 0 is MONDAY
  final _days = List<bool>.filled(7, false);
  bool _hasDays = false;

  /// represents the list on which month it is open.
  /// Day number 0 is JANUARY.
  final _months = List<bool>.filled(12, false);

  /// represents the list on which year / month it is open.
  List<int> _firstYearMonths;
  List<int> _lastYearMonths;
  int _fullYears = 0;
  int _year = 0;

  /// represents the list on which day it is open.
  List<List<bool>> _dayMonths;

  /// lists of equal size representing the start and end times
  final _startTimes = <int>[];
  final _endTimes = <int>[];

  bool _publicHoliday = false;
  bool _schoolHoliday = false;
  bool _easter = false;

  /// Flag that means that time is off
  bool _off = false;

  /// Additional information or limitation.
  /// https://wiki.openstreetmap.org/wiki/Key:opening_hours/specification#explain:comment
  String _comment;

  int _sequenceIndex;

  BasicOpeningHourRule() {
    _sequenceIndex = 0;
  }

  BasicOpeningHourRule.withSequenceIndex(this._sequenceIndex);

  int getSequenceIndex() {
    return _sequenceIndex;
  }

  /// return an array representing the days of the rule
  ///
  /// @return the days of the rule
  List<bool> getDays() {
    return _days;
  }

  /// @return the day months of the rule
  List<bool> getDayMonths(int month) {
    if (_dayMonths == null) {
      _dayMonths = List.generate(12, (_) => new List.filled(31, false));
    }
    return _dayMonths[month];
  }

  bool hasDayMonths() {
    return _dayMonths != null;
  }

  /// return an array representing the months of the rule
  ///
  /// @return the months of the rule
  List<bool> getMonths() {
    return _months;
  }

  bool appliesToPublicHolidays() {
    return _publicHoliday;
  }

  bool appliesEaster() {
    return _easter;
  }

  bool appliesToSchoolHolidays() {
    return _schoolHoliday;
  }

  String getComment() {
    return _comment;
  }

  setComment(String comment) {
    _comment = comment;
  }

  /// set a single start time, erase all previously added start times
  ///
  /// @param s startTime to set
  setStartTime(int s) {
    _setSingleValueForArrayList(_startTimes, s);
    if (_endTimes.length != 1) {
      _setSingleValueForArrayList(_endTimes, 0);
    }
  }

  /// set a single end time, erase all previously added end times
  ///
  /// @param e endTime to set
  setEndTime(int e) {
    _setSingleValueForArrayList(_endTimes, e);
    if (_startTimes.length != 1) {
      _setSingleValueForArrayList(_startTimes, 0);
    }
  }

  /// Set single start time. If position exceeds index of last item by one
  /// then new value will be added.
  /// If value is between 0 and last index, then value in the position p will be overwritten
  /// with new one.
  /// Else exception will be thrown.
  ///
  /// @param s        - value
  /// @param position - position to add
  setStartTimePos(int s, int position) {
    if (position == _startTimes.length) {
      _startTimes.add(s);
      _endTimes.add(0);
    } else {
      _startTimes[position] = s;
    }
  }

  /// Set single end time. If position exceeds index of last item by one
  /// then new value will be added.
  /// If value is between 0 and last index, then value in the position p will be overwritten
  /// with new one.
  /// Else exception will be thrown.
  ///
  /// @param s        - value
  /// @param position - position to add
  setEndTimePos(int s, int position) {
    if (position == _startTimes.length) {
      _endTimes.add(s);
      _startTimes.add(0);
    } else {
      _endTimes[position] = s;
    }
  }

  /// get a single start time
  ///
  /// @return a single start time
  int getStartTime() {
    if (_startTimes.length == 0) {
      return 0;
    }
    return _startTimes[0];
  }

  /// get a single start time in position
  ///
  /// @param position position to get value from
  /// @return a single start time
  int getStartTimePos(int position) {
    return _startTimes[position];
  }

  /// get a single end time
  ///
  /// @return a single end time
  int getEndTime() {
    if (_endTimes.length == 0) {
      return 0;
    }
    return _endTimes[0];
  }

  /// get a single end time in position
  ///
  /// @param position position to get value from
  /// @return a single end time
  int getEndTimePos(int position) {
    return _endTimes[position];
  }

  /// get all start times as independent list
  ///
  /// @return all start times
  List<int> getStartTimes() {
    return _startTimes;
  }

  /// get all end times as independent list
  ///
  /// @return all end times
  List<int> getEndTimes() {
    return _endTimes;
  }

  /// Check if the weekday of time "cal" is part of this rule
  ///
  /// @param cal the time to check
  /// @return true if this day is part of the rule
  @override
  bool containsDay(DateTime cal) {
    int i = cal.weekday;
    int d = (i - 1) % 7;
    if (_days[d]) {
      return true;
    }
    return false;
  }

  @override
  bool containsNextDay(DateTime cal) {
    int i = cal.weekday;
    int p = i % 7;
    if (_days[p]) {
      return true;
    }
    return false;
  }

  /// Check if the previous weekday of time "cal" is part of this rule
  ///
  /// @param cal the time to check
  /// @return true if the previous day is part of the rule
  @override
  bool containsPreviousDay(DateTime cal) {
    int i = cal.weekday;
    int p = (i - 2) % 7;
    if (_days[p]) {
      return true;
    }
    return false;
  }

  /// Check if the month of "cal" is part of this rule
  ///
  /// @param cal the time to check
  /// @return true if the month is part of the rule
  @override
  bool containsMonth(DateTime cal) {
    int month = cal.month - 1;
    int year = cal.year;
    return containsYear(cal) && _months[month];
  }

  bool containsYear(DateTime cal) {
    if (_year == 0 && _firstYearMonths == null) {
      return true;
    }
    int month = cal.month - 1;
    int year = cal.year;
    if (_firstYearMonths != null && _firstYearMonths[month] == year ||
        _lastYearMonths != null && _lastYearMonths[month] == year ||
        _firstYearMonths == null && _lastYearMonths == null && _year == year) {
      return true;
    }
    if (_fullYears > 0 && _year > 0) {
      for (int i = 1; i <= _fullYears; i++) {
        if (_year + i == year) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if this rule says the feature is open at time "cal"
  ///
  /// @param cal the time to check
  /// @return false in all other cases, also if only day is wrong
  @override
  bool isOpenedForTimeCheckPrev(DateTime cal, bool checkPrevious) {
    int d = _getCurrentDay(cal);
    int p = _getPreviousDay(d);
    int time = _getCurrentTimeInMinutes(cal); // Time in minutes
    for (int i = 0; i < _startTimes.length; i++) {
      int startTime = this._startTimes[i];
      int endTime = this._endTimes[i];
      if (startTime < endTime || endTime == -1) {
        // one day working like 10:00-20:00 (not 20:00-04:00)
        if (_days[d] && !checkPrevious) {
          if (time >= startTime && (endTime == -1 || time <= endTime)) {
            return !_off;
          }
        }
      } else {
        // opening_hours includes day wrap like
        // "We 20:00-03:00" or "We 07:00-07:00"
        if (time >= startTime && _days[d] && !checkPrevious) {
          return !_off;
        } else if (time < endTime && _days[p] && checkPrevious) {
          // check in previous day
          return !_off;
        }
      }
    }
    return false;
  }

  int _getCurrentDay(DateTime cal) {
    int i = cal.weekday;
    return (i - 1) % 7;
  }

  int _getPreviousDay(int currentDay) {
    int p = currentDay - 1;
    if (p < 0) {
      p += 7;
    }
    return p;
  }

  int _getNextDay(int currentDay) {
    int n = currentDay + 1;
    if (n > 6) {
      n -= 7;
    }
    return n;
  }

  int _getCurrentTimeInMinutes(DateTime cal) {
    return cal.hour * 60 + cal.minute;
  }

  @override
  String toRuleString() {
    return _toRuleString(OpeningHoursParser._daysStr, OpeningHoursParser._monthsStr);
  }

  String _toRuleString(List<String> dayNames, List<String> monthNames) {
    final b = StringBuffer();
    bool allMonths = true;
    for (int i = 0; i < _months.length; i++) {
      if (!_months[i]) {
        allMonths = false;
        break;
      }
    }
    bool allDays = !hasDayMonths();
    if (!allDays) {
      bool dash = false;
      bool first = true;
      int monthAdded = -1;
      int dayAdded = -1;
      int excludedMonthEnd = -1;
      int excludedDayEnd = -1;
      int excludedMonthStart = -1;
      int excludedDayStart = -1;
      if (_dayMonths[0][0] && _dayMonths[11][30]) {
        int prevMonth = 0;
        int prevDay = 0;
        for (int month = 0; month < _dayMonths.length; month++) {
          for (int day = 0; day < _dayMonths[month].length; day++) {
            if (day == 1) {
              prevMonth = month;
            }
            if (!_dayMonths[month][day]) {
              excludedMonthEnd = prevMonth;
              excludedDayEnd = prevDay;
              break;
            }
            prevDay = day;
          }
          if (excludedDayEnd != -1) {
            break;
          }
        }
        prevMonth = _dayMonths.length - 1;
        prevDay = _dayMonths[prevMonth].length - 1;
        for (int month = _dayMonths.length - 1; month >= 0; month--) {
          for (int day = _dayMonths[month].length - 1; day >= 0; day--) {
            if (day == _dayMonths[month].length - 2) {
              prevMonth = month;
            }
            if (!_dayMonths[month][day]) {
              excludedMonthStart = prevMonth;
              excludedDayStart = prevDay;
              break;
            }
            prevDay = day;
          }
          if (excludedDayStart != -1) {
            break;
          }
        }
      }
      bool yearAdded = false;
      for (int month = 0; month < _dayMonths.length; month++) {
        for (int day = 0; day < _dayMonths[month].length; day++) {
          if (excludedDayStart != -1 && excludedDayEnd != -1) {
            if (month < excludedMonthEnd || (month == excludedMonthEnd && day <= excludedDayEnd)) {
              continue;
            } else if (month > excludedMonthStart || (month == excludedMonthStart && day >= excludedDayStart)) {
              continue;
            }
          }
          if (_dayMonths[month][day]) {
            if (day == 0 && dash && _dayMonths[month][1]) {
              continue;
            }
            if (day > 0 &&
                _dayMonths[month][day - 1] &&
                ((day < _dayMonths[month].length - 1 && _dayMonths[month][day + 1]) ||
                    (day == _dayMonths[month].length - 1 &&
                        month < _dayMonths.length - 1 &&
                        _dayMonths[month + 1][0]))) {
              if (!dash) {
                dash = true;
                if (!first) {
                  b.write("-");
                }
              }
              continue;
            }
            if (first) {
              first = false;
            } else if (!dash) {
              b.write(", ");
              monthAdded = -1;
            }
            yearAdded = _appendYearString(b, dash ? _lastYearMonths : _firstYearMonths, month);
            if (monthAdded != month || yearAdded) {
              b.write(monthNames[month]);
              b.write(" ");
              monthAdded = month;
            }
            dayAdded = day + 1;
            b.write(dayAdded);
            dash = false;
          }
        }
      }
      if (excludedDayStart != -1 && excludedDayEnd != -1) {
        if (first) {
          first = false;
        } else if (!dash) {
          b.write(", ");
        }
        _appendYearString(b, _firstYearMonths, excludedMonthStart);
        b.write(monthNames[excludedMonthStart]);
        b.write(" ");
        b.write(excludedDayStart + 1);
        b.write("-");
        _appendYearString(b, _lastYearMonths, excludedMonthEnd);
        b.write(monthNames[excludedMonthEnd]);
        b.write(" ");
        b.write(excludedDayEnd + 1);
      } else if (yearAdded && !dash && monthAdded != -1 && _lastYearMonths != null) {
        b.write("-");
        _appendYearString(b, _lastYearMonths, monthAdded);
        b.write(monthNames[monthAdded]);
        if (dayAdded != -1) {
          b.write(" ");
          b.write(dayAdded);
        }
      }
      if (!first) {
        b.write(" ");
      }
    } else if (!allMonths) {
      _addArray(_months, monthNames, b);
    }

    // Day
    _appendDaysStringDays(b, dayNames);
    // Time
    if (_startTimes == null || _startTimes.length == 0) {
      if (isOpened24_7()) {
        b.clear();
        b.write("24/7 ");
      }
      if (_off) {
        b.write(OpeningHoursParser._additionalStrings["off"]);
      }
    } else {
      if (isOpened24_7()) {
        b.clear();
        b.write("24/7");
      } else {
        for (int i = 0; i < _startTimes.length; i++) {
          int startTime = _startTimes[i];
          int endTime = _endTimes[i];
          if (i > 0) {
            b.write(", ");
          }
          int stHour = (startTime / 60).floor();
          int stTime = startTime - stHour * 60;
          int enHour = (endTime / 60).floor();
          int enTime = endTime - enHour * 60;
          OpeningHoursParser._formatTime(stHour, stTime, b);
          b.write("-");
          OpeningHoursParser._formatTime(enHour, enTime, b);
        }
        if (_off) {
          b.write(" ");
          b.write(OpeningHoursParser._additionalStrings["off"]);
        }
      }
    }
    if (!Algorithms.isEmpty(_comment)) {
      if (b.length > 0) {
        if (b.toString()[b.length - 1] != ' ') {
          b.write(" ");
        }
        b.write("- ");
        b.write(_comment);
      } else {
        b.write(_comment);
      }
    }
    return b.toString();
  }

  bool _appendYearString(StringBuffer b, List<int> yearMonths, int month) {
    if (yearMonths != null && yearMonths[month] > 0) {
      b.write(yearMonths[month]);
      b.write(" ");
      return true;
    } else if (_year > 0) {
      b.write(_year);
      b.write(" ");
      return true;
    }
    return false;
  }

  _addArray(List<bool> array, List<String> arrayNames, StringBuffer b) {
    bool dash = false;
    bool first = true;
    for (int i = 0; i < array.length; i++) {
      if (array[i]) {
        if (i > 0 && array[i - 1] && i < array.length - 1 && array[i + 1]) {
          if (!dash) {
            dash = true;
            b.write("-");
          }
          continue;
        }
        if (first) {
          first = false;
        } else if (!dash) {
          b.write(", ");
        }
        b.write(arrayNames == null ? (i + 1) : arrayNames[i]);
        dash = false;
      }
    }
    if (!first) {
      b.write(" ");
    }
  }

  @override
  String toLocalRuleString() {
    return _toRuleString(OpeningHoursParser._localDaysStr, OpeningHoursParser._localMothsStr);
  }

  @override
  bool isOpened24_7() {
    bool opened24_7 = isOpenedEveryDay();

    if (opened24_7) {
      if (_startTimes != null && _startTimes.length > 0) {
        for (int i = 0; i < _startTimes.length; i++) {
          int startTime = _startTimes[i];
          int endTime = _endTimes[i];
          if (startTime == 0 && endTime / 60 == 24) {
            return true;
          }
        }
      } else {
        return true;
      }
    }
    return false;
  }

  bool isOpenedEveryDay() {
    bool openedEveryDay = true;
    for (int i = 0; i < 7; i++) {
      if (!_days[i]) {
        openedEveryDay = false;
        break;
      }
    }
    return openedEveryDay;
  }

  @override
  String getTime(DateTime cal, bool checkAnotherDay, int limit, bool opening) {
    final sb = StringBuffer();
    int d = _getCurrentDay(cal);
    int ad = opening ? _getNextDay(d) : _getPreviousDay(d);
    int time = _getCurrentTimeInMinutes(cal);
    for (int i = 0; i < _startTimes.length; i++) {
      int startTime = _startTimes[i];
      int endTime = _endTimes[i];
      if (opening != _off) {
        if (startTime < endTime || endTime == -1) {
          if (_days[d] && !checkAnotherDay) {
            int diff = startTime - time;
            if (limit == _withoutTimeLimit || (time <= startTime && (diff <= limit || limit == _currentDayTimeLimit))) {
              OpeningHoursParser._formatTimeMinutes(startTime, sb);
              break;
            }
          }
        } else {
          int diff = -1;
          if (time <= startTime && _days[d] && !checkAnotherDay) {
            diff = startTime - time;
          } else if (time > endTime && _days[ad] && checkAnotherDay) {
            diff = 24 * 60 - endTime + time;
          }
          if (limit == _withoutTimeLimit || ((diff != -1 && diff <= limit) || limit == _currentDayTimeLimit)) {
            OpeningHoursParser._formatTimeMinutes(startTime, sb);
            break;
          }
        }
      } else {
        if (startTime < endTime && endTime != -1) {
          if (_days[d] && !checkAnotherDay) {
            int diff = endTime - time;
            if ((limit == _withoutTimeLimit && diff >= 0) || (time <= endTime && diff <= limit)) {
              OpeningHoursParser._formatTimeMinutes(endTime, sb);
              break;
            }
          }
        } else {
          int diff = -1;
          if (time <= endTime && _days[d] && !checkAnotherDay) {
            diff = 24 * 60 - time + endTime;
          } else if (time < endTime && _days[ad] && checkAnotherDay) {
            diff = endTime - time;
          }
          if (limit == _withoutTimeLimit || (diff != -1 && diff <= limit)) {
            OpeningHoursParser._formatTimeMinutes(endTime, sb);
            break;
          }
        }
      }
    }
    var res = sb.toString();
    if (res.length > 0 && !Algorithms.isEmpty(_comment)) {
      res += " - " + _comment;
    }
    return res;
  }

  @override
  String toString() {
    return toRuleString();
  }

  _appendDaysString(StringBuffer builder) {
    _appendDaysStringDays(builder, OpeningHoursParser._daysStr);
  }

  _appendDaysStringDays(StringBuffer builder, List<String> daysNames) {
    bool dash = false;
    bool first = true;
    for (int i = 0; i < 7; i++) {
      if (_days[i]) {
        if (i > 0 && _days[i - 1] && i < 6 && _days[i + 1]) {
          if (!dash) {
            dash = true;
            builder.write("-");
          }
          continue;
        }
        if (first) {
          first = false;
        } else if (!dash) {
          builder.write(", ");
        }
        builder.write(daysNames[OpeningHoursParser._getDayIndex(i)]);
        dash = false;
      }
    }
    if (_publicHoliday) {
      if (!first) {
        builder.write(", ");
      }
      builder.write("PH");
      first = false;
    }
    if (_schoolHoliday) {
      if (!first) {
        builder.write(", ");
      }
      builder.write("SH");
      first = false;
    }
    if (_easter) {
      if (!first) {
        builder.write(", ");
      }
      builder.write("Easter");
      first = false;
    }
    if (!first) {
      builder.write(" ");
    }
  }

  /// Add a time range (startTime-endTime) to this rule
  ///
  /// @param startTime startTime to add
  /// @param endTime   endTime to add
  addTimeRange(int startTime, int endTime) {
    _startTimes.add(startTime);
    _endTimes.add(endTime);
  }

  int timesSize() {
    return _startTimes.length;
  }

  deleteTimeRange(int position) {
    _startTimes.removeAt(position);
    _endTimes.removeAt(position);
  }

  static _setSingleValueForArrayList(List<int> arrayList, int s) {
    if (arrayList.length > 0) {
      arrayList.clear();
    }
    arrayList.add(s);
  }

  @override
  bool isOpenedForTime(DateTime cal) {
    int c = _calculate(cal);
    return c > 0;
  }

  @override
  bool contains(DateTime cal) {
    int c = _calculate(cal);
    return c != 0;
  }

  @override
  bool hasOverlapTimes() {
    for (int i = 0; i < this._startTimes.length; i++) {
      int startTime = this._startTimes[i];
      int endTime = this._endTimes[i];
      if (startTime >= endTime && endTime != -1) {
        return true;
      }
    }
    return false;
  }

  @override
  bool hasOverlapTimesRule(DateTime cal, OpeningHoursRule r) {
    if (_off) {
      return true;
    }
    if (r != null && r.contains(cal) && r is BasicOpeningHourRule) {
      var rule = r;
      if (_startTimes.length > 0 && rule._startTimes.length > 0) {
        for (int i = 0; i < this._startTimes.length; i++) {
          int startTime = this._startTimes[i];
          int endTime = this._endTimes[i];
          if (endTime == -1) {
            endTime = 24 * 60;
          } else if (startTime >= endTime) {
            endTime = 24 * 60 + endTime;
          }
          for (int k = 0; k < rule._startTimes.length; k++) {
            int rStartTime = rule._startTimes[k];
            int rEndTime = rule._endTimes[k];
            if (rEndTime == -1) {
              rEndTime = 24 * 60;
            } else if (rStartTime >= rEndTime) {
              rEndTime = 24 * 60 + rEndTime;
            }
            if ((rStartTime >= startTime && rStartTime < endTime) ||
                (startTime >= rStartTime && startTime < rEndTime)) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  int _calculate(DateTime cal) {
    int month = cal.month - 1;
    if (!containsMonth(cal)) {
      return 0;
    }
    int dmonth = cal.day - 1;
    int i = cal.weekday;
    int day = (i - 1) % 7;
    int previous = (day + 6) % 7;
    bool thisDay = _hasDays || hasDayMonths();
    if (thisDay && hasDayMonths()) {
      thisDay = _dayMonths[month][dmonth];
    }
    if (thisDay && _hasDays) {
      thisDay = _days[day];
    }
    // potential error for Dec 31 12:00-01:00
    bool previousDay = _hasDays || hasDayMonths();
    if (previousDay && hasDayMonths() && dmonth > 0) {
      previousDay = _dayMonths[month][dmonth - 1];
    }
    if (previousDay && _hasDays) {
      previousDay = _days[previous];
    }
    if (!thisDay && !previousDay) {
      return 0;
    }
    int time = cal.hour * 60 + cal.minute; // Time in minutes
    for (i = 0; i < _startTimes.length; i++) {
      int startTime = this._startTimes[i];
      int endTime = this._endTimes[i];
      if (startTime < endTime || endTime == -1) {
        // one day working like 10:00-20:00 (not 20:00-04:00)
        if (time >= startTime && (endTime == -1 || time <= endTime) && thisDay) {
          return _off ? -1 : 1;
        }
      } else {
        // opening_hours includes day wrap like
        // "We 20:00-03:00" or "We 07:00-07:00"
        if (time >= startTime && thisDay) {
          return _off ? -1 : 1;
        } else if (time < endTime && previousDay) {
          return _off ? -1 : 1;
        }
      }
    }
    if (thisDay && (_startTimes == null || _startTimes.isEmpty) && !_off) {
      return 1;
    } else if (thisDay && (_startTimes == null || _startTimes.isEmpty || !_off)) {
      return -1;
    }
    return 0;
  }
}

class UnparseableRule extends OpeningHoursRule {
  final String _ruleString;

  UnparseableRule(this._ruleString);

  @override
  bool isOpenedForTimeCheckPrev(DateTime cal, bool checkPrevious) {
    return false;
  }

  @override
  bool containsPreviousDay(DateTime cal) {
    return false;
  }

  @override
  bool hasOverlapTimes() {
    return false;
  }

  @override
  bool hasOverlapTimesRule(DateTime cal, OpeningHoursRule r) {
    return false;
  }

  @override
  bool containsDay(DateTime cal) {
    return false;
  }

  @override
  bool containsNextDay(DateTime cal) {
    return false;
  }

  @override
  bool containsMonth(DateTime cal) {
    return false;
  }

  @override
  bool containsYear(DateTime cal) {
    return false;
  }

  @override
  String toRuleString() {
    return _ruleString;
  }

  @override
  String toLocalRuleString() {
    return toRuleString();
  }

  @override
  bool isOpened24_7() {
    return false;
  }

  @override
  String getTime(DateTime cal, bool checkAnotherDay, int limit, bool opening) {
    return "";
  }

  @override
  String toString() {
    return toRuleString();
  }

  @override
  bool isOpenedForTime(DateTime cal) {
    return false;
  }

  @override
  bool contains(DateTime cal) {
    return false;
  }

  @override
  int getSequenceIndex() {
    return 0;
  }
}

enum _TokenType {
  tokenUnknown,
  tokenColon,
  tokenComma,
  tokenDash,
// order is important
  tokenYear,
  tokenMonth,
  tokenDayMonth,
  tokenHoliday,
  tokenDayWeek,
  tokenHourMinutes,
  tokenOffOn
}

int _getTokenTypeOrd(_TokenType t) {
  switch (t) {
    case _TokenType.tokenUnknown:
      return 0;
    case _TokenType.tokenColon:
      return 1;
    case _TokenType.tokenComma:
      return 2;
    case _TokenType.tokenDash:
      return 3;
    case _TokenType.tokenYear:
      return 4;
    case _TokenType.tokenMonth:
      return 5;
    case _TokenType.tokenDayMonth:
      return 6;
    case _TokenType.tokenHoliday:
      return 7;
    case _TokenType.tokenDayWeek:
      return 7;
    case _TokenType.tokenHourMinutes:
      return 8;
    case _TokenType.tokenOffOn:
      return 9;
  }
  return 0;
}

class _Token {
  int mainNumber = -1;
  _TokenType type;
  String text;

  _Token parent;

  _Token(this.type, this.text) {
    try {
      mainNumber = int.parse(text);
    } catch (FormatException) {
      // ignore
    }
  }

  _Token.withMainNumber(this.type, this.mainNumber) : text = "$mainNumber";

  String toString() {
    if (parent != null) {
      return "$parent._text [${parent.type.toString()}] ($text [${type.toString()}]) ";
    } else {
      return "$text [${type.toString()}] ";
    }
  }
}

/// This class contains the entire OpeningHours schema and
/// offers methods to check directly weather something is open
///
/// @author sander
class OpeningHours {
  static final int allSequences = -1;

  /// list of the different rules
  List<OpeningHoursRule> _rules;
  String _original;
  int _sequenceCount;

  /// Constructor
  ///
  /// @param rules List of OpeningHoursRule to be given
  OpeningHours.withRules(this._rules);

  /// Empty constructor
  OpeningHours() : this._rules = <OpeningHoursRule>[];

  List<Info> getInfo() {
    return getInfoWithDateTime(DateTime.now());
  }

  List<Info> getInfoWithDateTime(DateTime cal) {
    var res = <Info>[];
    for (int i = 0; i < _sequenceCount; i++) {
      var info = getInfoWithSequenceIndex(cal, i);
      res.add(info);
    }
    return res.isEmpty ? null : res;
  }

  Info getCombinedInfo() {
    return getCombinedInfoWithDateTime(DateTime.now());
  }

  Info getCombinedInfoWithDateTime(DateTime cal) {
    return getInfoWithSequenceIndex(cal, allSequences);
  }

  Info getInfoWithSequenceIndex(DateTime cal, int sequenceIndex) {
    var info = Info();
    bool opened = isOpenedForTimeV2(cal, sequenceIndex);
    info._opened = opened;
    info._ruleString = getCurrentRuleTimeWithSequenceIndex(cal, sequenceIndex);
    if (opened) {
      info._opened24_7 = isOpened24_7(sequenceIndex);
      info._closingTime = getClosingTime(cal, sequenceIndex);
      info._nearToClosingTime = getNearToClosingTime(cal, sequenceIndex);
    } else {
      info._openingTime = getOpeningTime(cal, sequenceIndex);
      info._nearToOpeningTime = getNearToOpeningTime(cal, sequenceIndex);
      info._openingTomorrow = getOpeningTomorrow(cal, sequenceIndex);
      info._openingDay = getOpeningDay(cal, sequenceIndex);
    }
    return info;
  }

  /// add a rule to the opening hours
  ///
  /// @param r rule to add
  addRule(OpeningHoursRule r) {
    _rules.add(r);
  }

  /// add rules to the opening hours
  ///
  /// @param rules to add
  addRules(List<OpeningHoursRule> rules) {
    _rules.addAll(rules);
  }

  int getSequenceCount() {
    return _sequenceCount;
  }

  setSequenceCount(int sequenceCount) {
    _sequenceCount = sequenceCount;
  }

  /// return the list of rules
  ///
  /// @return the rules
  List<OpeningHoursRule> getRules() {
    return _rules;
  }

  List<OpeningHoursRule> getRulesWithSequenceIndex(int sequenceIndex) {
    if (sequenceIndex == allSequences) {
      return _rules;
    } else {
      var sequenceRules = <OpeningHoursRule>[];
      for (OpeningHoursRule r in _rules) {
        if (r.getSequenceIndex() == sequenceIndex) {
          sequenceRules.add(r);
        }
      }
      return sequenceRules;
    }
  }

  /// check if the feature is opened at time "cal"
  ///
  /// @param cal the time to check
  /// @return true if feature is open
  bool isOpenedForTimeV2(DateTime cal, int sequenceIndex) {
    // make exception for overlapping times i.e.
    // (1) Mo 14:00-16:00; Tu off
    // (2) Mo 14:00-02:00; Tu off
    // in (2) we need to check first rule even though it is against specification
    var rules = getRulesWithSequenceIndex(sequenceIndex);
    bool overlap = false;
    for (int i = rules.length - 1; i >= 0; i--) {
      OpeningHoursRule r = rules[i];
      if (r.hasOverlapTimes()) {
        overlap = true;
        break;
      }
    }
    // start from the most specific rule
    for (int i = rules.length - 1; i >= 0; i--) {
      bool checkNext = false;
      OpeningHoursRule rule = rules[i];
      if (rule.contains(cal)) {
        if (i > 0) {
          checkNext = !rule.hasOverlapTimesRule(cal, rules[i - 1]);
        }
        bool open = rule.isOpenedForTime(cal);
        if (open || (!overlap && !checkNext)) {
          return open;
        }
      }
    }
    return false;
  }

  /// check if the feature is opened at time "cal"
  ///
  /// @param cal the time to check
  /// @return true if feature is open
  bool isOpenedForTime(DateTime cal) {
    return isOpenedForTimeV2(cal, allSequences);
  }

  /// check if the feature is opened at time "cal"
  ///
  /// @param cal the time to check
  /// @param sequenceIndex the sequence index to check
  /// @return true if feature is open
  bool isOpenedForTimeWithSequenceIndex(DateTime cal, int sequenceIndex) {
    /*
			 * first check for rules that contain the current day
			 * afterwards check for rules that contain the previous
			 * day with overlapping times (times after midnight)
			 */
    bool isOpenDay = false;
    var rules = getRulesWithSequenceIndex(sequenceIndex);
    for (OpeningHoursRule r in rules) {
      if (r.containsDay(cal) && r.containsMonth(cal)) {
        isOpenDay = r.isOpenedForTimeCheckPrev(cal, false);
      }
    }
    bool isOpenPrevious = false;
    for (OpeningHoursRule r in rules) {
      if (r.containsPreviousDay(cal) && r.containsMonth(cal)) {
        isOpenPrevious = r.isOpenedForTimeCheckPrev(cal, true);
      }
    }
    return isOpenDay || isOpenPrevious;
  }

  bool isOpened24_7(int sequenceIndex) {
    bool opened24_7 = false;
    var rules = getRulesWithSequenceIndex(sequenceIndex);
    for (OpeningHoursRule r in rules) {
      opened24_7 = r.isOpened24_7();
    }
    return opened24_7;
  }

  String getNearToOpeningTime(DateTime cal, int sequenceIndex) {
    return _getTime(cal, _lowTimeLimit, true, sequenceIndex);
  }

  String getOpeningTime(DateTime cal, int sequenceIndex) {
    return _getTime(cal, _currentDayTimeLimit, true, sequenceIndex);
  }

  String getNearToClosingTime(DateTime cal, int sequenceIndex) {
    return _getTime(cal, _lowTimeLimit, false, sequenceIndex);
  }

  String getClosingTime(DateTime cal, int sequenceIndex) {
    return _getTime(cal, _withoutTimeLimit, false, sequenceIndex);
  }

  String getOpeningTomorrow(DateTime calendar, int sequenceIndex) {
    var cal = calendar;
    var openingTime = "";
    final rules = getRulesWithSequenceIndex(sequenceIndex);
    cal = cal.add(Duration(days: 1));
    for (final r in rules) {
      if (r.containsDay(cal) && r.containsMonth(cal)) {
        openingTime = r.getTime(cal, false, _withoutTimeLimit, true);
      }
    }
    return openingTime;
  }

  String getOpeningDay(DateTime calendar, int sequenceIndex) {
    var cal = calendar;
    var openingTime = "";
    final rules = getRulesWithSequenceIndex(sequenceIndex);
    for (int i = 0; i < 7; i++) {
      cal = cal.add(Duration(days: 1));
      for (final r in rules) {
        if (r.containsDay(cal) && r.containsMonth(cal)) {
          openingTime = r.getTime(cal, false, _withoutTimeLimit, true);
        }
      }
      if (!Algorithms.isEmpty(openingTime)) {
        var day = OpeningHoursParser._getDayIndex(cal.weekday - 1);
        openingTime += " " + OpeningHoursParser._localDaysStr[day];
        break;
      }
    }
    return openingTime;
  }

  String _getTime(DateTime cal, int limit, bool opening, int sequenceIndex) {
    var time = _getTimeDay(cal, limit, opening, sequenceIndex);
    if (Algorithms.isEmpty(time)) {
      time = _getTimeAnotherDay(cal, limit, opening, sequenceIndex);
    }
    return time;
  }

  String _getTimeDay(DateTime cal, int limit, bool opening, int sequenceIndex) {
    String atTime = "";
    final rules = getRulesWithSequenceIndex(sequenceIndex);
    OpeningHoursRule prevRule;
    for (final r in rules) {
      if (r.containsDay(cal) && r.containsMonth(cal)) {
        if (atTime.length > 0 && prevRule != null && !r.hasOverlapTimesRule(cal, prevRule)) {
          return atTime;
        } else {
          atTime = r.getTime(cal, false, limit, opening);
        }
      }
      prevRule = r;
    }
    return atTime;
  }

  String _getTimeAnotherDay(DateTime cal, int limit, bool opening, int sequenceIndex) {
    var atTime = "";
    final rules = getRulesWithSequenceIndex(sequenceIndex);
    for (final r in rules) {
      if (((opening && r.containsPreviousDay(cal)) || (!opening && r.containsNextDay(cal))) && r.containsMonth(cal)) {
        atTime = r.getTime(cal, true, limit, opening);
      }
    }
    return atTime;
  }

  String getCurrentRuleTime(DateTime cal) {
    return getCurrentRuleTimeWithSequenceIndex(cal, allSequences);
  }

  String getCurrentRuleTimeWithSequenceIndex(DateTime cal, int sequenceIndex) {
    // make exception for overlapping times i.e.
    // (1) Mo 14:00-16:00; Tu off
    // (2) Mo 14:00-02:00; Tu off
    // in (2) we need to check first rule even though it is against specification
    final rules = getRulesWithSequenceIndex(sequenceIndex);
    String ruleClosed;
    bool overlap = false;
    for (int i = rules.length - 1; i >= 0; i--) {
      OpeningHoursRule r = rules[i];
      if (r.hasOverlapTimes()) {
        overlap = true;
        break;
      }
    }
    // start from the most specific rule
    for (int i = rules.length - 1; i >= 0; i--) {
      bool checkNext = false;
      OpeningHoursRule rule = rules[i];
      if (rule.contains(cal)) {
        if (i > 0) {
          checkNext = !rule.hasOverlapTimesRule(cal, rules[i - 1]);
        }
        bool open = rule.isOpenedForTime(cal);
        if (open || (!overlap && !checkNext)) {
          return rule.toLocalRuleString();
        } else {
          ruleClosed = rule.toLocalRuleString();
        }
      }
    }
    return ruleClosed;
  }

  String getCurrentRuleTimeV1(DateTime cal) {
    String ruleOpen;
    String ruleClosed;
    for (final r in _rules) {
      if (r.containsPreviousDay(cal) && r.containsMonth(cal)) {
        if (r.isOpenedForTimeCheckPrev(cal, true)) {
          ruleOpen = r.toLocalRuleString();
        } else {
          ruleClosed = r.toLocalRuleString();
        }
      }
    }
    for (final r in _rules) {
      if (r.containsDay(cal) && r.containsMonth(cal)) {
        if (r.isOpenedForTimeCheckPrev(cal, false)) {
          ruleOpen = r.toLocalRuleString();
        } else {
          ruleClosed = r.toLocalRuleString();
        }
      }
    }

    if (ruleOpen != null) {
      return ruleOpen;
    }
    return ruleClosed;
  }

  @override
  String toString() {
    final s = StringBuffer();
    if (_rules.isEmpty) {
      return "";
    }
    for (final r in _rules) {
      s.write(r.toString());
      s.write("; ");
    }
    return s.toString().substring(0, s.length - 2);
  }

  String toLocalString() {
    final s = StringBuffer();
    if (_rules.isEmpty) {
      return "";
    }

    for (final r in _rules) {
      s.write(r.toLocalRuleString());
      s.write("; ");
    }

    return s.toString().substring(0, s.length - 2);
  }

  void setOriginal(String original) {
    _original = original;
  }

  String getOriginal() {
    return _original;
  }
}
