# s_metar

A Flutter/Dart package for parsing **METAR** and **TAF** aeronautical weather reports from aviation meteorological stations worldwide.

## Features

### METAR parsing
- **Wind** — direction (degrees, cardinal, variable), speed & gusts in kt/m/s/km/h/mph, Beaufort scale, `isCalm` flag
- **Visibility** — prevailing and minimum visibility in all units; `isMaximum` flag for 9999 (≥10 km); CAVOK detection
- **Weather** — intensity, descriptor, precipitation (including compound codes like `RASN`, `FZRASN`), obscuration, other phenomena
- **Clouds** — cover (raw ICAO code + translation), height in ft/m/km, oktas, cloud type (CB, TCU)
- **Temperatures** — temperature & dewpoint with relative humidity, dewpoint spread, heat index (NOAA), wind chill
- **Pressure** — altimeter/QNH in hPa/inHg/mbar/bar/Pa/kPa/atm
- **Runway Visual Range (RVR)** — up to 3 runway ranges with trend
- **Recent weather**, **windshear**, **sea state**, **runway state**
- **Weather trends** — TEMPO/BECMG trend groups
- **Flight rules** — VLIFR / LIFR / IFR / MVFR / VFR derived automatically
- **`shouldBeCavok()`** — analyses current conditions to determine if CAVOK applies


### TAF parsing
- Valid period, AMD/COR modifier, NIL/CANCELLED
- Wind, visibility, weather and clouds as above
- Max/min temperature forecasts
- Change periods: FM, TEMPO, BECMG, PROB30, PROB40

### Live METAR/TAF fetching
  - Added `MetarTafFetcher` class for fetching live weather data from aviationweather.gov API
  - Added `MetarTafResult` class for typed fetch results with parsed `Metar`/`Taf` objects and raw data
  - ICAO code validation: ensures 4-character codes (first char letter, rest alphanumeric) via `isValidIcao()`
  - DateTime validation: rejects future dates and returns descriptive error
  - Integration with `s_client` API for HTTP requests with automatic retry and error handling
- **CORS proxy support for web builds**:
  - `proxyUrls` static list for configurable proxy URLs (default: two Cloudflare Workers for redundancy)
  - `customProxyUrls` parameter on `fetch()` for per-request proxy override
  - Automatic proxy fallback: tries each proxy in order, switches on rate limit (429/503 status codes)
  - Direct API fallback when all proxies fail
- **Deployment resources**:
  - Cloudflare Worker implementation in `lib/s_metar/deployment/cloudflare-worker.js`
  - Vercel Edge Function implementation in `lib/s_metar/deployment/vercel-edge-function.js`
  - Comprehensive deployment guide in `lib/s_metar/deployment/README.md`
  - Usage examples in `lib/s_metar/deployment/USAGE_EXAMPLES.dart`

### Example app integration
- Added interactive `s_metar` example screen with 3-tab interface:
  - METAR tab: preset samples (EGLL, KJFK, Winter, CAVOK) + custom input with live parsing
  - TAF tab: editable TAF code with live parsing
  - Live Fetch tab: ICAO input, date/time picker, and real-time API fetching
- Expandable cards showing parsed weather data (wind, visibility, clouds, temperatures, pressure)
- Registered in package examples registry under "Networking" category

## Installation

```yaml
dependencies:
  s_metar: ^1.0.0
```

## Quick start

### Basic usage

```dart
import 'package:s_metar/s_metar.dart';

// Parse a METAR
final metar = Metar('METAR EGLL 181220Z 25015G28KT 220V280 9999 FEW020 BKN080 15/08 Q1012 NOSIG');

print(metar.wind.speedInKnot);          // 15.0
print(metar.wind.gustInKnot);           // 28.0
print(metar.wind.beaufort);             // 6
print(metar.temperatures.relativeHumidity);  // ~62 %
print(metar.pressure.inHPa);           // 1012.0
print(metar.flightRules);              // 'VFR'

// Parse a TAF
final taf = Taf('TAF EGLL 181100Z 1812/1918 25015KT 9999 FEW025 '
    'TEMPO 1812/1816 5000 RASN BKN012 '
    'BECMG 1901/1903 30008KT');

print(taf.valid.periodFrom);
print(taf.changesForecasted.length);   // 2
```

### Advanced usage

```dart
import 'package:s_metar/s_metar.dart';

// --- Derived temperature quantities ---
final metar = Metar('METAR EGLL 181220Z 25015G28KT 220V280 9999 FEW020 BKN080 15/08 Q1012 NOSIG');
final t = metar.temperatures;

print(t.dewpointSpread);               // 7.0 °C  (< 3 → fog risk warning)
print(t.relativeHumidity);             // ~62 %
print(t.heatIndex);                    // null (only applicable above 27 °C)
print(t.windChill(metar.wind.speedInKph)); // wind-chill in °C

// --- Compound precipitation codes ---
final winter = Metar('METAR EGLL 181220Z 05010KT 2500 -RASN BKN008 OVC015 03/01 Q0992');
for (final w in winter.weathers.items) {
  print(w.code);                       // '-RASN'
  print(w.precipitationCodes);         // ['RA', 'SN']
}

// --- Cloud ceiling & CAVOK ---
print(metar.clouds.ceiling);           // false (no BKN/OVC ≤ 1500 ft)
print(metar.prevailingVisibility.cavok); // false
print(metar.shouldBeCavok());          // true/false – auto-analysed

// --- US altimeter (inHg) ---
final us = Metar('METAR KJFK 181220Z 27010KT 10SM FEW020 BKN100 18/10 A2992');
print(us.pressure.inInHg);             // 29.92
print(us.pressure.inHPa);             // ~1013.2

// --- TAF change periods ---
final taf = Taf(
  'TAF EGLL 181100Z 1812/1918 25015KT 9999 FEW025 '
  'TEMPO 1812/1816 5000 RASN BKN012 '
  'BECMG 1901/1903 30008KT '
  'PROB40 TEMPO 1906/1910 3000 DZ BKN006',
);

for (final cp in taf.changesForecasted.items) {
  print(cp.changeIndicator.code);      // TEMPO / BECMG / PROB40 TEMPO
  print(cp.flightRules);              // IFR / MVFR / VFR …
}

// --- Live fetch (requires network) ---
final result = await MetarTafFetcher.fetch(
  icao: 'EGLL',
  dateTime: DateTime.now().toUtc(),
);

if (result.isSuccess) {
  print(result.rawMetar);             // raw METAR string
  print(result.metar?.flightRules);   // parsed flight rules
  print(result.taf?.changesForecasted.length);
}
```

## Example app

See the `example/` directory for a full interactive demo — pick from preset METARs, enter
your own code, browse every parsed field, and fetch live reports by ICAO code.

![s_metar interactive demo](https://raw.githubusercontent.com/SoundSliced/s_metar/main/example/assets/example.gif)

```bash
cd example
flutter run
```

## License

MIT — see the `LICENSE` file.

## Repository

https://github.com/SoundSliced/s_metar
