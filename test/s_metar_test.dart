import 'package:flutter_test/flutter_test.dart';
import 'package:s_metar/s_metar.dart';

void main() {
  // ---------------------------------------------------------------------------
  // METAR tests
  // ---------------------------------------------------------------------------

  group('Metar — basic parsing', () {
    late Metar metar;

    setUp(() {
      metar = Metar(
        'METAR EGLL 181220Z 25015G28KT 220V280 9999 FEW020 BKN080 15/08 Q1012 NOSIG',
        year: 2026,
        month: 2,
      );
    });

    test('station', () {
      expect(metar.station.code, 'EGLL');
    });

    test('wind speed in knots', () {
      expect(metar.wind.speedInKnot, 15.0);
    });

    test('wind gust in knots', () {
      expect(metar.wind.gustInKnot, 28.0);
    });

    test('wind direction cardinal', () {
      expect(metar.wind.cardinalDirection, 'WSW');
    });

    test('wind is not calm', () {
      expect(metar.wind.isCalm, isFalse);
    });

    test('prevailing visibility 9999 is maximum', () {
      expect(metar.prevailingVisibility.inMeters, 10000.0);
      expect(metar.prevailingVisibility.inMeters! >= 10000, isTrue);
    });

    test('temperature in Celsius', () {
      expect(metar.temperatures.temperatureInCelsius, 15.0);
    });

    test('dewpoint in Celsius', () {
      expect(metar.temperatures.dewpointInCelsius, 8.0);
    });

    test('relative humidity is reasonable', () {
      final rh = metar.temperatures.relativeHumidity;
      expect(rh, isNotNull);
      expect(rh!, greaterThan(40));
      expect(rh, lessThan(100));
    });

    test('dewpoint spread', () {
      final spread = metar.temperatures.dewpointSpread;
      expect(spread, closeTo(7.0, 0.01));
    });

    test('pressure in hPa', () {
      expect(metar.pressure.inHPa, closeTo(1012.0, 0.5));
    });

    test('pressure in Pa', () {
      expect(metar.pressure.inPa, closeTo(101200.0, 50));
    });

    test('pressure in kPa', () {
      expect(metar.pressure.inKPa, closeTo(101.2, 0.1));
    });

    test('flight rules', () {
      expect(metar.flightRules, isNotNull);
    });

    test('cloud cover code', () {
      expect(metar.clouds.items.first.coverCode, 'FEW');
    });
  });

  // ---------------------------------------------------------------------------
  // METAR — calm wind
  // ---------------------------------------------------------------------------

  group('Metar — calm wind', () {
    test('isCalm is true for 00000KT', () {
      final m = Metar(
        'METAR EGLL 181220Z 00000KT 9999 NSC 20/15 Q1013',
        year: 2026,
        month: 2,
      );
      expect(m.wind.isCalm, isTrue);
      expect(m.wind.speedInKnot, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // METAR — US statute-mile visibility
  // ---------------------------------------------------------------------------

  group('Metar — US SM visibility', () {
    test('10SM converts to ~16093 m', () {
      final m = Metar(
        'METAR KJFK 181220Z 27010KT 10SM FEW020 BKN100 18/10 A2992',
        year: 2026,
        month: 2,
      );
      // 10 SM × 1.60934 km/SM × 1000 = 16093.4 m
      expect(m.prevailingVisibility.inMeters, closeTo(16093.4, 200));
    });

    test('altimeter A2992 converts correctly to hPa', () {
      final m = Metar(
        'METAR KJFK 181220Z 27010KT 10SM FEW020 18/10 A2992',
        year: 2026,
        month: 2,
      );
      // 2992 / 100 * inhgToHpa ≈ 1013.2 hPa
      expect(m.pressure.inHPa, closeTo(1013.2, 1.0));
    });
  });

  // ---------------------------------------------------------------------------
  // METAR — compound weather (RASN etc.)
  // ---------------------------------------------------------------------------

  group('Metar — compound precipitation', () {
    test('RASN precipitation codes contains RA and SN', () {
      final m = Metar(
        'METAR EGLL 181220Z 25015KT 3000 RASN BKN010 05/03 Q0998',
        year: 2026,
        month: 2,
      );
      final codes = m.weathers.items.first.precipitationCodes;
      expect(codes, containsAll(['RA', 'SN']));
    });

    test('RASN precipitation string contains rain and snow', () {
      final m = Metar(
        'METAR EGLL 181220Z 25015KT 3000 RASN BKN010 05/03 Q0998',
        year: 2026,
        month: 2,
      );
      final prec = m.weathers.items.first.precipitation;
      expect(prec, contains('rain'));
      expect(prec, contains('snow'));
    });
  });

  // ---------------------------------------------------------------------------
  // METAR — shouldBeCavok
  // ---------------------------------------------------------------------------

  group('Metar — shouldBeCavok', () {
    test('returns true when conditions meet CAVOK criteria', () {
      // No clouds, no weather, visibility ≥ 10 km
      final m = Metar(
        'METAR EGLL 181220Z 27010KT 9999 NSC 18/10 Q1020',
        year: 2026,
        month: 2,
      );
      expect(m.shouldBeCavok(), isTrue);
    });

    test('returns false below min visibility', () {
      final m = Metar(
        'METAR EGLL 181220Z 27010KT 2000 NSC 18/10 Q1020',
        year: 2026,
        month: 2,
      );
      expect(m.shouldBeCavok(), isFalse);
    });

    test('returns false with significant weather', () {
      final m = Metar(
        'METAR EGLL 181220Z 27010KT 9999 RA NSC 18/10 Q1020',
        year: 2026,
        month: 2,
      );
      expect(m.shouldBeCavok(), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // TAF tests
  // ---------------------------------------------------------------------------

  group('Taf — basic parsing', () {
    late Taf taf;

    setUp(() {
      taf = Taf(
        'TAF EGLL 181100Z 1812/1918 25015KT 9999 FEW025 '
        'TEMPO 1812/1816 5000 RASN BKN012 '
        'BECMG 1901/1903 30008KT',
        year: 2026,
        month: 2,
      );
    });

    test('station', () {
      expect(taf.station.code, 'EGLL');
    });

    test('wind speed', () {
      expect(taf.wind.speedInKnot, 15.0);
    });

    test('prevailing visibility isMaximum', () {
      expect(taf.prevailingVisibility.inMeters! >= 10000, isTrue);
    });

    test('change periods count', () {
      expect(taf.changesForecasted.length, 2);
    });

    test('TEMPO change has weather', () {
      final tempo = taf.changesForecasted.items.firstWhere(
        (c) => c.changeIndicator.code?.contains('TEMPO') ?? false,
      );
      expect(tempo.weathers.length, greaterThan(0));
    });
  });

  // ---------------------------------------------------------------------------
  // Speed — basic tests
  // ---------------------------------------------------------------------------

  group('Speed — calm wind', () {
    test('isCalm is true for 00000KT', () {
      final m = Metar(
        'METAR EGLL 181220Z 00000KT 9999 NSC 20/15 Q1013',
        year: 2026,
        month: 2,
      );
      expect(m.wind.isCalm, isTrue);
      expect(m.wind.speedInKnot, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // GroupList — asList()
  // ---------------------------------------------------------------------------

  group('GroupList asList()', () {
    test('clouds asList returns a List', () {
      final m = Metar(
        'METAR EGLL 181220Z 25015KT 9999 FEW020 BKN080 15/08 Q1012',
        year: 2026,
        month: 2,
      );
      final list = m.clouds.asList();
      expect(list, isA<List>());
      expect(list.length, 2);
      expect(list.first, isA<Map>());
    });
  });
}
