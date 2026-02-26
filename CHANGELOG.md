## [2.0.0]
- `s_packages` dependency upgraded to ^3.0.0

## 1.0.2 - 2026-02-18
- `pubspec.yaml`'s package description updated

## 1.0.1 - 2026-02-18
- README updated

## 1.0.0 - 2026-02-18

- **NEW `s_metar` sub-package of the `s_packages` pub package**:
  - **METAR parsing**: Full support for aviation routine weather reports with `Metar(String code)` constructor
  - **TAF parsing**: Terminal Aerodrome Forecast support with `Taf(String code)` constructor
  - **Wind data**:
    - Speed in multiple units: knots, m/s, km/h, mph via `speedInKnot`, `speedInMps`, `speedInKph`, `speedInMiph`
    - Gust speed in same units via `gustInKnot`, `gustInMps`, `gustInKph`, `gustInMiph`
    - Direction in degrees and cardinal direction (N, NE, E, etc.)
    - Wind variation range (from/to degrees)
    - Beaufort scale number (0-12) and description via `beaufort` and `beaufortDescription`
    - `isCalm` boolean flag for calm wind conditions (00000KT)
  - **Visibility**:
    - Prevailing and minimum visibility in meters, kilometers, sea miles, and feet
    - `isMaximum` flag for visibility ≥10 km
    - CAVOK detection
  - **Weather phenomena**:
    - Intensity, descriptor, precipitation, obscuration, and other phenomena
    - `precipitationCodes` list for compound weather (e.g., RASN → ['RA', 'SN'])
    - Recent weather parsing
  - **Cloud layers**:
    - Cover amount with ICAO code (`coverCode`: FEW/SCT/BKN/OVC/NSC) and translation
    - Height in feet, meters, and kilometers
    - Cloud type codes (CB, TCU) with `cloudTypeCode` and `cloudType`
    - Oktas (eighths of sky coverage)
    - `ceiling` property (true when ≤1500 ft and BKN/OVC)
  - **Temperature data**:
    - Temperature and dewpoint in Celsius, Fahrenheit, Kelvin, and Rankine
    - Derived meteorological quantities:
      - `relativeHumidity` percentage
      - `dewpointSpread` in °C
      - `heatIndex` in °C (valid when temp ≥27°C and RH ≥40%)
      - `windChill(double? windSpeedKph)` in °C (valid when temp ≤10°C and wind ≥4.8 km/h)
  - **Pressure**:
    - Support for 7 units: hPa, inHg, mbar, Pa, kPa, bar, atm via `inHPa`, `inInHg`, `inMbar`, `inPa`, `inKPa`, `inBar`, `inAtm`
  - **Flight rules**: Automatic VFR/MVFR/IFR/LIFR/VLIFR classification via `flightRules` property
  - **CAVOK validation**: `shouldBeCavok()` method checks if conditions meet CAVOK criteria
  - **Additional METAR fields**: Runway visual range (RVR), windshear, sea state, runway state, weather trends (TEMPO/BECMG)
  - **TAF features**: Valid period, change indicators (FM/TEMPO/BECMG/PROB), max/min temperature forecasts, change period details
  - **Serialization**: `asMap()` method for JSON-serializable output
  - **GroupList utilities**: `asList()` method for converting group lists (clouds, weather, etc.) to `List<Map<String, Object?>>`
  - **Flexible parsing**: Optional `year` and `month` parameters for accurate timestamp resolution, `truncate` option for remark handling
  - **Unparsed groups tracking**: `unparsedGroups` property lists any METAR/TAF groups that weren't recognized
  - **Live METAR/TAF fetching**:
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
  - **Example app integration**:
    - Added interactive `s_metar` example screen with 3-tab interface:
      - METAR tab: preset samples (EGLL, KJFK, Winter, CAVOK) + custom input with live parsing
      - TAF tab: editable TAF code with live parsing
      - Live Fetch tab: ICAO input, date/time picker, and real-time API fetching
    - Expandable cards showing parsed weather data (wind, visibility, clouds, temperatures, pressure)
    - Registered in package examples registry under "Networking" category
