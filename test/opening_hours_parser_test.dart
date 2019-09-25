import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mobile/utils/opening_hours_parser.dart';

void main() {
  test("Test opening hours parser", () {
    var openingHoursParserTest = OpeningHoursParserTest();
    openingHoursParserTest.testOpeningHours();
  });
}

class OpeningHoursParserTest {
  /// test if the calculated opening hours are what you expect
  ///
  /// @param time
  ///            the time to test in the format "dd.MM.yyyy HH:mm"
  /// @param hours
  ///            the OpeningHours object
  /// @param expected
  ///            the expected state
  testOpened(String time, OpeningHours hours, bool expected) {
    DateFormat format = new DateFormat("dd.MM.yyyy HH:mm");
    final cal = format.parse(time);
    bool calculated = hours.isOpenedForTimeV2(cal, OpeningHours.allSequences);
    final fmt =
        "  ${((calculated != expected) ? "NOT " : "")}ok: Expected $time: $expected = $calculated (rule ${hours.getCurrentRuleTimeWithSequenceIndex(cal, OpeningHours.allSequences)})\n";
    print("$fmt\n");
    expect(calculated, expected, reason: fmt);
  }

  /// test if the calculated opening hours are what you expect
  ///
  /// @param time        the time to test in the format "dd.MM.yyyy HH:mm"
  /// @param hours       the OpeningHours object
  /// @param expected    the expected string in format:
  ///                         "Open from HH:mm"     - open in 5 hours
  ///                         "Will open at HH:mm"  - open in 2 hours
  ///                         "Open till HH:mm"     - close in 5 hours
  ///                         "Will close at HH:mm" - close in 2 hours
  ///                         "Will open on HH:mm (Mo,Tu,We,Th,Fr,Sa,Su)" - open in >5 hours
  ///                         "Will open tomorrow at HH:mm" - open in >5 hours tomorrow
  ///                         "Open 24/7"           - open 24/7
  _testInfo(String time, OpeningHours hours, String expected) {
    _testInfoWithSequenceIndex(time, hours, expected, OpeningHours.allSequences);
  }

  /// test if the calculated opening hours are what you expect
  ///
  /// @param time        the time to test in the format "dd.MM.yyyy HH:mm"
  /// @param hours       the OpeningHours object
  /// @param expected    the expected string in format:
  ///                         "Open from HH:mm"     - open in 5 hours
  ///                         "Will open at HH:mm"  - open in 2 hours
  ///                         "Open till HH:mm"     - close in 5 hours
  ///                         "Will close at HH:mm" - close in 2 hours
  ///                         "Will open on HH:mm (Mo,Tu,We,Th,Fr,Sa,Su)" - open in >5 hours
  ///                         "Will open tomorrow at HH:mm" - open in >5 hours tomorrow
  ///                         "Open 24/7"           - open 24/7
  /// @param sequenceIndex sequence index of rules separated by ||
  _testInfoWithSequenceIndex(String time, OpeningHours hours, String expected, int sequenceIndex) {
    DateFormat format = new DateFormat("dd.MM.yyyy HH:mm");
    final cal = format.parse(time);

    String description;
    bool result;
    if (sequenceIndex == OpeningHours.allSequences) {
      final info = hours.getCombinedInfoWithDateTime(cal);
      description = info.getInfo();
      result = expected.toLowerCase() == description.toLowerCase();
    } else {
      final infos = hours.getInfoWithDateTime(cal);
      final info = infos[sequenceIndex];
      description = info.getInfo();
      result = expected.toLowerCase() == description.toLowerCase();
    }

    String fmt =
        "  ${(!result ? "NOT " : "")}ok: Expected $time ($expected): $description (rule ${hours.getCurrentRuleTimeWithSequenceIndex(cal, sequenceIndex)})\n";
    print("$fmt\n");
    expect(result, true, reason: fmt);
  }

  _testParsedAndAssembledCorrectly(String timeString, OpeningHours hours) {
    String assembledString = hours.toString();
    bool isCorrect = assembledString.toLowerCase() == timeString.toLowerCase();
    String fmt = "  ${(!isCorrect ? "NOT " : "")}ok: Expected: \"$timeString\" got: \"$assembledString\"\n";
    print("$fmt\n");
    expect(isCorrect, true, reason: fmt);
  }

  testOpeningHours() {
    // initialization
    OpeningHoursParser.instance;

    // 0. not properly supported
    // hours = _parseOpenedHours("Mo-Su (sunrise-00:30)-(sunset+00:30)");

    OpeningHours hours = _parseOpenedHours("2019 Apr 1 - 2020 Apr 1");
    print("$hours\n");
    testOpened("01.04.2018 15:00", hours, false);
    testOpened("01.04.2019 15:00", hours, true);
    testOpened("01.04.2020 15:00", hours, true);

    hours = _parseOpenedHours("2019 Apr 15 -  2020 Mar 1");
    print("$hours\n");
    testOpened("01.04.2018 15:00", hours, false);
    testOpened("01.04.2019 15:00", hours, false);
    testOpened("15.04.2019 15:00", hours, true);
    testOpened("15.09.2019 15:00", hours, true);
    testOpened("15.02.2020 15:00", hours, true);
    testOpened("15.03.2020 15:00", hours, false);
    testOpened("15.04.2020 15:00", hours, false);

    hours = _parseOpenedHours("2019 Jul 23 05:00-24:00; 2019 Jul 24-2019 Jul 26 00:00-24:00; 2019 Jul 27 00:00-18:00");
    print("$hours\n");
    testOpened("23.07.2018 15:00", hours, false);
    testOpened("23.07.2019 15:00", hours, true);
    testOpened("23.07.2019 04:00", hours, false);
    testOpened("23.07.2020 15:00", hours, false);
    testOpened("25.07.2018 15:00", hours, false);
    testOpened("24.07.2019 15:00", hours, true);
    testOpened("25.07.2019 04:00", hours, true);
    testOpened("26.07.2019 15:00", hours, true);
    testOpened("25.07.2020 15:00", hours, false);
    testOpened("27.07.2018 15:00", hours, false);
    testOpened("27.07.2019 15:00", hours, true);
    testOpened("27.07.2019 19:00", hours, false);
    testOpened("27.07.2020 15:00", hours, false);

    hours = _parseOpenedHours("2019 Sep 1 - 2022 Apr 1");
    print("$hours\n");
    testOpened("01.02.2018 15:00", hours, false);
    testOpened("29.05.2019 15:00", hours, false);
    testOpened("05.09.2019 11:00", hours, true);
    testOpened("05.02.2020 11:00", hours, true);
    testOpened("03.06.2020 11:00", hours, false);
    testOpened("05.02.2021 11:00", hours, true);
    testOpened("05.02.2022 11:00", hours, true);
    testOpened("05.02.2023 11:00", hours, false);

    hours = _parseOpenedHours("2019 Apr 15 - 2019 Sep 1: Mo-Fr 00:00-24:00");
    print("$hours\n");
    testOpened("06.04.2019 15:00", hours, false);
    testOpened("29.05.2019 15:00", hours, true);
    testOpened("25.07.2019 11:00", hours, true);
    testOpened("12.07.2018 11:00", hours, false);
    testOpened("18.07.2020 11:00", hours, false);
    testOpened("28.07.2021 11:00", hours, false);

    hours = _parseOpenedHours("2019 Sep 1 - 2020 Apr 1");
    print("$hours\n");
    testOpened("01.04.2019 15:00", hours, false);
    testOpened("29.05.2019 15:00", hours, false);
    testOpened("05.09.2019 11:00", hours, true);
    testOpened("05.02.2020 11:00", hours, true);
    testOpened("05.06.2020 11:00", hours, false);
    testOpened("05.02.2021 11:00", hours, false);

    hours = _parseOpenedHours("2019 Apr 15 - 2019 Sep 1");
    print("$hours\n");
    testOpened("01.04.2019 15:00", hours, false);
    testOpened("29.05.2019 15:00", hours, true);
    testOpened("27.07.2019 15:00", hours, true);
    testOpened("05.09.2019 11:00", hours, false);
    testOpened("05.06.2018 11:00", hours, false);
    testOpened("05.06.2020 11:00", hours, false);

    hours = _parseOpenedHours("Apr 15 - Sep 1");
    print("$hours\n");
    testOpened("01.04.2019 15:00", hours, false);
    testOpened("29.05.2019 15:00", hours, true);
    testOpened("27.07.2019 15:00", hours, true);
    testOpened("05.09.2019 11:00", hours, false);

    hours = _parseOpenedHours("Apr 15 - Sep 1: Mo-Fr 00:00-24:00");
    print("$hours\n");
    testOpened("01.04.2019 15:00", hours, false);
    testOpened("29.05.2019 15:00", hours, true);
    testOpened("24.07.2019 15:00", hours, true);
    testOpened("27.07.2019 15:00", hours, false);
    testOpened("05.09.2019 11:00", hours, false);

    hours = _parseOpenedHours("Apr 05-Oct 24: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("26.08.2018 15:00", hours, false);
    testOpened("29.03.2019 15:00", hours, false);
    testOpened("05.04.2019 11:00", hours, true);

    hours = _parseOpenedHours("Oct 24-Apr 05: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("26.08.2018 15:00", hours, false);
    testOpened("29.03.2019 15:00", hours, true);
    testOpened("26.04.2019 11:00", hours, false);

    hours = _parseOpenedHours("Oct 24-Apr 05, Jun 10-Jun 20, Jul 6-12: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("26.08.2018 15:00", hours, false);
    testOpened("02.01.2019 15:00", hours, false);
    testOpened("29.03.2019 15:00", hours, true);
    testOpened("26.04.2019 11:00", hours, false);

    hours = _parseOpenedHours("Apr 05-24: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("12.10.2018 11:00", hours, false);
    testOpened("12.04.2019 15:00", hours, true);
    testOpened("27.04.2019 15:00", hours, false);

    hours = _parseOpenedHours("Apr 5: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("05.04.2019 15:00", hours, true);
    testOpened("06.04.2019 15:00", hours, false);

    hours = _parseOpenedHours("Apr 24-05: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("12.10.2018 11:00", hours, false);
    testOpened("12.04.2018 15:00", hours, false);

    hours = _parseOpenedHours("Apr: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("12.10.2018 11:00", hours, false);
    testOpened("12.04.2019 15:00", hours, true);

    hours = _parseOpenedHours("Apr-Oct: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("09.11.2018 11:00", hours, false);
    testOpened("12.10.2018 11:00", hours, true);
    testOpened("24.08.2018 15:00", hours, true);
    testOpened("09.03.2018 15:00", hours, false);

    hours = _parseOpenedHours("Apr, Oct: Fr 08:00-16:00");
    print("$hours\n");
    testOpened("09.11.2018 11:00", hours, false);
    testOpened("12.10.2018 11:00", hours, true);
    testOpened("24.08.2018 15:00", hours, false);
    testOpened("12.04.2019 15:00", hours, true);

    // test basic case
    hours = _parseOpenedHours("Mo-Fr 08:30-14:40"); //$NON-NLS-1$
    print("$hours\n");
    testOpened("09.08.2012 11:00", hours, true);
    testOpened("09.08.2012 16:00", hours, false);
    hours = _parseOpenedHours("mo-fr 07:00-19:00; sa 12:00-18:00");

    String string = "Mo-Fr 11:30-15:00, 17:30-23:00; Sa, Su, PH 11:30-23:00";
    hours = _parseOpenedHours(string);
    _testParsedAndAssembledCorrectly(string, hours);
    print("$hours\n");
    testOpened("7.09.2015 14:54", hours, true); // monday
    testOpened("7.09.2015 15:05", hours, false);
    testOpened("6.09.2015 16:05", hours, true);

    // two time and date ranges
    hours = _parseOpenedHours("Mo-We, Fr 08:30-14:40,15:00-19:00"); //$NON-NLS-1$
    print("$hours\n");
    testOpened("08.08.2012 14:00", hours, true);
    testOpened("08.08.2012 14:50", hours, false);
    testOpened("10.08.2012 15:00", hours, true);

    // test exception on general schema
    hours = _parseOpenedHours("Mo-Sa 08:30-14:40; Tu 08:00 - 14:00"); //$NON-NLS-1$
    print("$hours\n");
    testOpened("07.08.2012 14:20", hours, false);
    testOpened("07.08.2012 08:15", hours, true); // Tuesday

    // test off value
    hours = _parseOpenedHours("Mo-Sa 09:00-18:25; Th off"); //$NON-NLS-1$
    print("$hours\n");
    testOpened("08.08.2012 12:00", hours, true);
    testOpened("09.08.2012 12:00", hours, false);

    // test 24/7
    hours = _parseOpenedHours("24/7"); //$NON-NLS-1$
    print("$hours\n");
    testOpened("08.08.2012 23:59", hours, true);
    testOpened("08.08.2012 12:23", hours, true);
    testOpened("08.08.2012 06:23", hours, true);

    // some people seem to use the following syntax:
    hours = _parseOpenedHours("Sa-Su 24/7");
    print("$hours\n");
    hours = _parseOpenedHours("Mo-Fr 9-19");
    print("$hours\n");
    hours = _parseOpenedHours("09:00-17:00");
    print("$hours\n");
    hours = _parseOpenedHours("sunrise-sunset");
    print("$hours\n");
    hours = _parseOpenedHours("10:00+");
    print("$hours\n");
    hours = _parseOpenedHours("Su-Th sunset-24:00, 04:00-sunrise; Fr-Sa sunset-sunrise");
    print("$hours\n");
    testOpened("12.08.2012 04:00", hours, true);
    testOpened("12.08.2012 23:00", hours, true);
    testOpened("08.08.2012 12:00", hours, false);
    testOpened("08.08.2012 05:00", hours, true);

    // test simple day wrap
    hours = _parseOpenedHours("Mo 20:00-02:00");
    print("$hours\n");
    testOpened("05.05.2013 10:30", hours, false);
    testOpened("05.05.2013 23:59", hours, false);
    testOpened("06.05.2013 10:30", hours, false);
    testOpened("06.05.2013 20:30", hours, true);
    testOpened("06.05.2013 23:59", hours, true);
    testOpened("07.05.2013 00:00", hours, true);
    testOpened("07.05.2013 00:30", hours, true);
    testOpened("07.05.2013 01:59", hours, true);
    testOpened("07.05.2013 20:30", hours, false);

    // test maximum day wrap
    hours = _parseOpenedHours("Su 10:00-10:00");
    print("$hours\n");
    testOpened("05.05.2013 09:59", hours, false);
    testOpened("05.05.2013 10:00", hours, true);
    testOpened("05.05.2013 23:59", hours, true);
    testOpened("06.05.2013 00:00", hours, true);
    testOpened("06.05.2013 09:59", hours, true);
    testOpened("06.05.2013 10:00", hours, false);

    // test day wrap as seen on OSM
    hours = _parseOpenedHours("Tu-Th 07:00-2:00; Fr 17:00-4:00; Sa 18:00-05:00; Su,Mo off");
    print("$hours\n");
    testOpened("05.05.2013 04:59", hours, true); // sunday 05.05.2013
    testOpened("05.05.2013 05:00", hours, false);
    testOpened("05.05.2013 12:30", hours, false);
    testOpened("06.05.2013 10:30", hours, false);
    testOpened("07.05.2013 01:00", hours, false);
    testOpened("07.05.2013 20:25", hours, true);
    testOpened("07.05.2013 23:59", hours, true);
    testOpened("08.05.2013 00:00", hours, true);
    testOpened("08.05.2013 02:00", hours, false);

    // test day wrap as seen on OSM
    hours = _parseOpenedHours("Mo-Th 09:00-03:00; Fr-Sa 09:00-04:00; Su off");
    testOpened("11.05.2015 08:59", hours, false);
    testOpened("11.05.2015 09:01", hours, true);
    testOpened("12.05.2015 02:59", hours, true);
    testOpened("12.05.2015 03:00", hours, false);
    testOpened("16.05.2015 03:59", hours, true);
    testOpened("16.05.2015 04:01", hours, false);
    testOpened("17.05.2015 01:00", hours, true);
    testOpened("17.05.2015 04:01", hours, false);

    hours = _parseOpenedHours("Tu-Th 07:00-2:00; Fr 17:00-4:00; Sa 18:00-05:00; Su,Mo off");
    testOpened("11.05.2015 08:59", hours, false);
    testOpened("11.05.2015 09:01", hours, false);
    testOpened("12.05.2015 01:59", hours, false);
    testOpened("12.05.2015 02:59", hours, false);
    testOpened("12.05.2015 03:00", hours, false);
    testOpened("13.05.2015 01:59", hours, true);
    testOpened("13.05.2015 02:59", hours, false);
    testOpened("16.05.2015 03:59", hours, true);
    testOpened("16.05.2015 04:01", hours, false);
    testOpened("17.05.2015 01:00", hours, true);
    testOpened("17.05.2015 05:01", hours, false);

    // tests single month value
    hours = _parseOpenedHours("May: 07:00-19:00");
    print("$hours\n");
    testOpened("05.05.2013 12:00", hours, true);
    testOpened("05.05.2013 05:00", hours, false);
    testOpened("05.05.2013 21:00", hours, false);
    testOpened("05.01.2013 12:00", hours, false);
    testOpened("05.01.2013 05:00", hours, false);

    // tests multi month value
    hours = _parseOpenedHours("Apr-Sep 8:00-22:00; Oct-Mar 10:00-18:00");
    print("$hours\n");
    testOpened("05.03.2013 15:00", hours, true);
    testOpened("05.03.2013 20:00", hours, false);

    testOpened("05.05.2013 20:00", hours, true);
    testOpened("05.05.2013 23:00", hours, false);

    testOpened("05.10.2013 15:00", hours, true);
    testOpened("05.10.2013 20:00", hours, false);

    // Test time with breaks
    hours = _parseOpenedHours("Mo-Fr: 9:00-13:00, 14:00-18:00");
    print("$hours\n");
    testOpened("02.12.2015 12:00", hours, true);
    testOpened("02.12.2015 13:30", hours, false);
    testOpened("02.12.2015 16:00", hours, true);

    testOpened("05.12.2015 16:00", hours, false);

    hours = _parseOpenedHours("Mo-Su 07:00-23:00; Dec 25 08:00-20:00");
    print("$hours\n");
    testOpened("25.12.2015 07:00", hours, false);
    testOpened("24.12.2015 07:00", hours, true);
    testOpened("24.12.2015 22:00", hours, true);
    testOpened("25.12.2015 08:00", hours, true);
    testOpened("25.12.2015 22:00", hours, false);

    hours = _parseOpenedHours("Mo-Su 07:00-23:00; Dec 25 off");
    print("$hours\n");
    testOpened("25.12.2015 14:00", hours, false);
    testOpened("24.12.2015 08:00", hours, true);

    // easter itself as public holiday is not supported
    hours = _parseOpenedHours("Mo-Su 07:00-23:00; Easter off; Dec 25 off");
    print("$hours\n");
    testOpened("25.12.2015 14:00", hours, false);
    testOpened("24.12.2015 08:00", hours, true);

    // test time off (not days
    hours = _parseOpenedHours("Mo-Fr 08:30-17:00; 12:00-12:40 off;");
    print("$hours\n");
    testOpened("07.05.2017 14:00", hours, false); // Sunday
    testOpened("06.05.2017 12:15", hours, false); // Saturday
    testOpened("05.05.2017 14:00", hours, true); // Friday
    testOpened("05.05.2017 12:15", hours, false);
    testOpened("05.05.2017 12:00", hours, false);
    testOpened("05.05.2017 11:45", hours, true);

    // Test holidays
    String hoursString = "mo-fr 11:00-21:00; PH off";
    hours = OpeningHoursParser.parseOpenedHoursHandleErrors(hoursString);
    _testParsedAndAssembledCorrectly(hoursString, hours);

    // test open from/till
    hours = _parseOpenedHours("Mo-Fr 08:30-17:00; 12:00-12:40 off;");
    print("$hours\n");
    _testInfo("15.01.2018 09:00", hours, "Open till 12:00");
    _testInfo("15.01.2018 11:00", hours, "Will close at 12:00");
    _testInfo("15.01.2018 12:00", hours, "Will open at 12:40");

    hours = _parseOpenedHours("Mo-Fr: 9:00-13:00, 14:00-18:00");
    print("$hours\n");
    _testInfo("15.01.2018 08:00", hours, "Will open at 09:00");
    _testInfo("15.01.2018 09:00", hours, "Open till 13:00");
    _testInfo("15.01.2018 12:00", hours, "Will close at 13:00");
    _testInfo("15.01.2018 13:10", hours, "Will open at 14:00");
    _testInfo("15.01.2018 14:00", hours, "Open till 18:00");
    _testInfo("15.01.2018 16:00", hours, "Will close at 18:00");
    _testInfo("15.01.2018 18:10", hours, "Will open tomorrow at 09:00");

    hours = _parseOpenedHours("Mo-Sa 02:00-10:00; Th off");
    print("$hours\n");
    _testInfo("15.01.2018 23:00", hours, "Will open tomorrow at 02:00");

    hours = _parseOpenedHours("Mo-Sa 23:00-02:00; Th off");
    print("$hours\n");
    _testInfo("15.01.2018 22:00", hours, "Will open at 23:00");
    _testInfo("15.01.2018 23:00", hours, "Open till 02:00");
    _testInfo("16.01.2018 00:30", hours, "Will close at 02:00");
    _testInfo("16.01.2018 02:00", hours, "Open from 23:00");

    hours = _parseOpenedHours("Mo-Sa 08:30-17:00; Th off");
    print("$hours\n");
    _testInfo("17.01.2018 20:00", hours, "Will open on 08:30 Fri.");
    _testInfo("18.01.2018 05:00", hours, "Will open tomorrow at 08:30");
    _testInfo("20.01.2018 05:00", hours, "Open from 08:30");
    _testInfo("21.01.2018 05:00", hours, "Will open tomorrow at 08:30");
    _testInfo("22.01.2018 02:00", hours, "Open from 08:30");
    _testInfo("22.01.2018 04:00", hours, "Open from 08:30");
    _testInfo("22.01.2018 07:00", hours, "Will open at 08:30");
    _testInfo("23.01.2018 10:00", hours, "Open till 17:00");
    _testInfo("23.01.2018 16:00", hours, "Will close at 17:00");

    hours = _parseOpenedHours("24/7");
    print("$hours\n");
    _testInfo("24.01.2018 02:00", hours, "Open 24/7");

    hours = _parseOpenedHours("Mo-Su 07:00-23:00, Fr 08:00-20:00");
    print("$hours\n");
    testOpened("15.01.2018 06:45", hours, false);
    testOpened("15.01.2018 07:45", hours, true);
    testOpened("15.01.2018 23:45", hours, false);
    testOpened("19.01.2018 07:45", hours, false);
    testOpened("19.01.2018 08:45", hours, true);
    testOpened("19.01.2018 20:45", hours, false);

    // test fallback case
    hours = _parseOpenedHours(
        "07:00-01:00 open \"Restaurant\" || Mo 00:00-04:00,07:00-04:00; Tu-Th 07:00-04:00; Fr 07:00-24:00; Sa,Su 00:00-24:00 open \"McDrive\"");
    print("$hours\n");
    testOpened("22.01.2018 00:30", hours, true);
    testOpened("22.01.2018 08:00", hours, true);
    testOpened("22.01.2018 03:30", hours, true);
    testOpened("22.01.2018 05:00", hours, false);
    testOpened("23.01.2018 05:00", hours, false);
    testOpened("27.01.2018 05:00", hours, true);
    testOpened("28.01.2018 05:00", hours, true);

    _testInfoWithSequenceIndex("22.01.2018 05:00", hours, "Will open at 07:00 - Restaurant", 0);
    _testInfoWithSequenceIndex("26.01.2018 00:00", hours, "Will close at 01:00 - Restaurant", 0);
    _testInfoWithSequenceIndex("22.01.2018 05:00", hours, "Will open at 07:00 - McDrive", 1);
    _testInfoWithSequenceIndex("22.01.2018 00:00", hours, "Open till 04:00 - McDrive", 1);
    _testInfoWithSequenceIndex("22.01.2018 02:00", hours, "Will close at 04:00 - McDrive", 1);
    _testInfoWithSequenceIndex("27.01.2018 02:00", hours, "Open till 24:00 - McDrive", 1);

    hours = _parseOpenedHours("07:00-03:00 open \"Restaurant\" || 24/7 open \"McDrive\"");
    print("$hours\n");
    testOpened("22.01.2018 02:00", hours, true);
    testOpened("22.01.2018 17:00", hours, true);
    _testInfoWithSequenceIndex("22.01.2018 05:00", hours, "Will open at 07:00 - Restaurant", 0);
    _testInfoWithSequenceIndex("22.01.2018 04:00", hours, "Open 24/7 - McDrive", 1);

    hours = _parseOpenedHours("Mo-Fr 12:00-15:00, Tu-Fr 17:00-23:00, Sa 12:00-23:00, Su 14:00-23:00");
    print("$hours\n");
    testOpened("16.02.2018 14:00", hours, true);
    testOpened("16.02.2018 16:00", hours, false);
    testOpened("16.02.2018 17:00", hours, true);
    _testInfo("16.02.2018 9:45", hours, "Open from 12:00");
    _testInfo("16.02.2018 12:00", hours, "Open till 15:00");
    _testInfo("16.02.2018 14:00", hours, "Will close at 15:00");
    _testInfo("16.02.2018 16:00", hours, "Will open at 17:00");
    _testInfo("16.02.2018 18:00", hours, "Open till 23:00");

    hours = _parseOpenedHours("Mo-Fr 10:00-21:00; Sa 12:00-23:00; PH \"Wird auf der Homepage bekannt gegeben.\"");
    _testParsedAndAssembledCorrectly(
        "Mo-Fr 10:00-21:00; Sa 12:00-23:00; PH - Wird auf der Homepage bekannt gegeben.", hours);
    print("$hours\n");
  }

  OpeningHours _parseOpenedHours(String string) {
    return OpeningHoursParser.parseOpenedHours(string);
  }
}
