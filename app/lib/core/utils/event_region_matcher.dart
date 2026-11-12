/// US state and territory divisions (canonical display names).
const List<String> usDivisions = [
  "Alabama",
  "Alaska",
  "Arizona",
  "Arkansas",
  "California",
  "Colorado",
  "Connecticut",
  "Delaware",
  "District of Columbia",
  "Florida",
  "Georgia",
  "Hawaii",
  "Idaho",
  "Illinois",
  "Indiana",
  "Iowa",
  "Kansas",
  "Kentucky",
  "Louisiana",
  "Maine",
  "Maryland",
  "Massachusetts",
  "Michigan",
  "Minnesota",
  "Mississippi",
  "Missouri",
  "Montana",
  "Nebraska",
  "Nevada",
  "New Hampshire",
  "New Jersey",
  "New Mexico",
  "New York",
  "North Carolina",
  "North Dakota",
  "Ohio",
  "Oklahoma",
  "Oregon",
  "Pennsylvania",
  "Puerto Rico",
  "Rhode Island",
  "South Carolina",
  "South Dakota",
  "Tennessee",
  "Texas",
  "Utah",
  "Vermont",
  "Virginia",
  "Washington",
  "West Virginia",
  "Wisconsin",
  "Wyoming",
];

/// Canadian province divisions (canonical display names).
const List<String> canadaDivisions = [
  "Alberta",
  "British Columbia",
  "Manitoba",
  "New Brunswick",
  "Newfoundland and Labrador",
  "Nova Scotia",
  "Ontario",
  "Prince Edward Island",
  "Quebec",
  "Saskatchewan",
];

const Map<String, List<String>> _regionDivisionLists = {
  'UNITED STATES': usDivisions,
  'CANADA': canadaDivisions,
  'AUSTRALIA': [
    'Australian Capital Territory',
    'New South Wales',
    'Northern Territory',
    'Queensland',
    'South Australia',
    'Tasmania',
    'Victoria',
    'Western Australia',
  ],
};

/// Shorthand region aliases to support quick lookup (e.g. "USA" -> "United States", "Chinese Taipei" -> "Taiwan")
const Map<String, String> regionAliases = {
  'USA': 'United States',
  'US': 'United States',
  'UK': 'United Kingdom',
  'GB': 'United Kingdom',
  'GREAT BRITAIN': 'United Kingdom',
  'ENGLAND': 'United Kingdom',
  'SCOTLAND': 'United Kingdom',
  'WALES': 'United Kingdom',
  'NORTHERN IRELAND': 'United Kingdom',
  'AU': 'Australia',
  'AUS': 'Australia',
  'CA': 'Canada',
  'CAN': 'Canada',
  'NZ': 'New Zealand',
  'UAE': 'United Arab Emirates',
  'KOR': 'South Korea',
  'JP': 'Japan',
  'GER': 'Germany',
  'DE': 'Germany',
  'FR': 'France',
  'FRA': 'France',
  'MEX': 'Mexico',
  'TW': 'Taiwan',
  'TAIWAN': 'Taiwan',
  'CHINESE TAIPEI': 'Taiwan',
  'CHINESETAIPEI': 'Taiwan',
  'TAIPEI': 'Taiwan',
  'HK': 'Hong Kong',
  'SG': 'Singapore',
  'PH': 'Philippines',
};

/// Shorthand division aliases (e.g. "TX" -> "Texas", "ON" -> "Ontario")
const Map<String, String> divisionAliases = {
  'AL': 'Alabama',
  'AK': 'Alaska',
  'AZ': 'Arizona',
  'AR': 'Arkansas',
  'CA': 'California',
  'CO': 'Colorado',
  'CT': 'Connecticut',
  'DE': 'Delaware',
  'DC': 'District of Columbia',
  'FL': 'Florida',
  'GA': 'Georgia',
  'HI': 'Hawaii',
  'ID': 'Idaho',
  'IL': 'Illinois',
  'IN': 'Indiana',
  'IA': 'Iowa',
  'KS': 'Kansas',
  'KY': 'Kentucky',
  'LA': 'Louisiana',
  'ME': 'Maine',
  'MD': 'Maryland',
  'MA': 'Massachusetts',
  'MI': 'Michigan',
  'MN': 'Minnesota',
  'MS': 'Mississippi',
  'MO': 'Missouri',
  'MT': 'Montana',
  'NE': 'Nebraska',
  'NV': 'Nevada',
  'NH': 'New Hampshire',
  'NJ': 'New Jersey',
  'NM': 'New Mexico',
  'NY': 'New York',
  'NC': 'North Carolina',
  'ND': 'North Dakota',
  'OH': 'Ohio',
  'OK': 'Oklahoma',
  'OR': 'Oregon',
  'PA': 'Pennsylvania',
  'PR': 'Puerto Rico',
  'RI': 'Rhode Island',
  'SC': 'South Carolina',
  'SD': 'South Dakota',
  'TN': 'Tennessee',
  'TX': 'Texas',
  'UT': 'Utah',
  'VT': 'Vermont',
  'VA': 'Virginia',
  'WA': 'Washington',
  'WV': 'West Virginia',
  'WI': 'Wisconsin',
  'WY': 'Wyoming',
  'AB': 'Alberta',
  'BC': 'British Columbia',
  'MB': 'Manitoba',
  'NB': 'New Brunswick',
  'NL': 'Newfoundland and Labrador',
  'NS': 'Nova Scotia',
  'ON': 'Ontario',
  'PE': 'Prince Edward Island',
  'QC': 'Quebec',
  'SK': 'Saskatchewan',
};

/// Unambiguous country aliases used for both `country` and `region` fields
/// (excludes 2-letter ISO codes that collide with US/Canada division codes).
const Map<String, String> _unambiguousCountryAliases = {
  'UNITED STATES': 'UNITED STATES',
  'UNITED STATES OF AMERICA': 'UNITED STATES',
  'USA': 'UNITED STATES',
  'U.S.A.': 'UNITED STATES',
  'U.S.': 'UNITED STATES',
  'PUERTO RICO': 'UNITED STATES',
  'UNITED KINGDOM': 'UNITED KINGDOM',
  'UNITED KINGDOM OF GREAT BRITAIN AND NORTHERN IRELAND': 'UNITED KINGDOM',
  'GREAT BRITAIN': 'UNITED KINGDOM',
  'UK': 'UNITED KINGDOM',
  'U.K.': 'UNITED KINGDOM',
  'GBR': 'UNITED KINGDOM',
  'ENGLAND': 'UNITED KINGDOM',
  'SCOTLAND': 'UNITED KINGDOM',
  'WALES': 'UNITED KINGDOM',
  'NORTHERN IRELAND': 'UNITED KINGDOM',
  'TAIWAN': 'TAIWAN',
  'CHINESE TAIPEI': 'TAIWAN',
  'CHINESETAIPEI': 'TAIWAN',
  'TAIWAN, PROVINCE OF CHINA': 'TAIWAN',
  'TAIWAN, CHINA': 'TAIWAN',
  'TWN': 'TAIWAN',
  'TAIPEI': 'TAIWAN',
  'TAIPEI CITY': 'TAIWAN',
  'NEW TAIPEI': 'TAIWAN',
  'NEW TAIPEI CITY': 'TAIWAN',
  'AUSTRALIA': 'AUSTRALIA',
  'AUS': 'AUSTRALIA',
  'CANADA': 'CANADA',
  'CAN': 'CANADA',
  'NEW ZEALAND': 'NEW ZEALAND',
  'NZL': 'NEW ZEALAND',
  'UNITED ARAB EMIRATES': 'UNITED ARAB EMIRATES',
  'UAE': 'UNITED ARAB EMIRATES',
  'U.A.E.': 'UNITED ARAB EMIRATES',
  'SOUTH KOREA': 'SOUTH KOREA',
  'KOREA, REPUBLIC OF': 'SOUTH KOREA',
  'REPUBLIC OF KOREA': 'SOUTH KOREA',
  'KOREA, SOUTH': 'SOUTH KOREA',
  'KOREA': 'SOUTH KOREA',
  'KOR': 'SOUTH KOREA',
  'TURKEY': 'TURKEY',
  'TÜRKIYE': 'TURKEY',
  'TÜRKİYE': 'TURKEY',
  'TURKIYE': 'TURKEY',
  'REPUBLIC OF TÜRKIYE': 'TURKEY',
  'REPUBLIC OF TÜRKİYE': 'TURKEY',
  'TUR': 'TURKEY',
  'CHINA': 'CHINA',
  "PEOPLE'S REPUBLIC OF CHINA": 'CHINA',
  'PRC': 'CHINA',
  'CHN': 'CHINA',
  'HONG KONG': 'HONG KONG',
  'HONG KONG SAR': 'HONG KONG',
  'HONG KONG, CHINA': 'HONG KONG',
  'HKG': 'HONG KONG',
  'MACAO': 'MACAO',
  'MACAU': 'MACAO',
  'MACAO SAR': 'MACAO',
  'MACAU SAR': 'MACAO',
  'MACAO, CHINA': 'MACAO',
  'MAC': 'MACAO',
  'IRELAND': 'IRELAND',
  'REPUBLIC OF IRELAND': 'IRELAND',
  'IRL': 'IRELAND',
  'MEXICO': 'MEXICO',
  'MÉXICO': 'MEXICO',
  'MEX': 'MEXICO',
  'JAPAN': 'JAPAN',
  'JPN': 'JAPAN',
  'GERMANY': 'GERMANY',
  'DEUTSCHLAND': 'GERMANY',
  'GER': 'GERMANY',
  'DEU': 'GERMANY',
  'FRANCE': 'FRANCE',
  'FRA': 'FRANCE',
  'SPAIN': 'SPAIN',
  'ESPAÑA': 'SPAIN',
  'ESP': 'SPAIN',
  'SINGAPORE': 'SINGAPORE',
  'SGP': 'SINGAPORE',
  'PHILIPPINES': 'PHILIPPINES',
  'THE PHILIPPINES': 'PHILIPPINES',
  'PHL': 'PHILIPPINES',
  'VIETNAM': 'VIETNAM',
  'VIET NAM': 'VIETNAM',
  'VNM': 'VIETNAM',
  'NETHERLANDS': 'NETHERLANDS',
  'THE NETHERLANDS': 'NETHERLANDS',
  'NLD': 'NETHERLANDS',
  'SWITZERLAND': 'SWITZERLAND',
  'CHE': 'SWITZERLAND',
  'BRAZIL': 'BRAZIL',
  'BRASIL': 'BRAZIL',
  'BRA': 'BRAZIL',
  'CHILE': 'CHILE',
  'CHL': 'CHILE',
  'COLOMBIA': 'COLOMBIA',
  'COL': 'COLOMBIA',
  'BAHRAIN': 'BAHRAIN',
  'BHR': 'BAHRAIN',
  'EGYPT': 'EGYPT',
  'EGY': 'EGYPT',
  'ETHIOPIA': 'ETHIOPIA',
  'ETH': 'ETHIOPIA',
  'FINLAND': 'FINLAND',
  'FIN': 'FINLAND',
  'JORDAN': 'JORDAN',
  'JOR': 'JORDAN',
  'MALAYSIA': 'MALAYSIA',
  'MYS': 'MALAYSIA',
  'MOROCCO': 'MOROCCO',
  'MAR': 'MOROCCO',
  'OMAN': 'OMAN',
  'OMN': 'OMAN',
  'PARAGUAY': 'PARAGUAY',
  'PRY': 'PARAGUAY',
  'SAUDI ARABIA': 'SAUDI ARABIA',
  'SAU': 'SAUDI ARABIA',
  'THAILAND': 'THAILAND',
  'THA': 'THAILAND',
  'TUNISIA': 'TUNISIA',
  'TUN': 'TUNISIA',
};

/// 2-letter ISO codes only safe to interpret on the `country` field (not `region`,
/// where codes like CA, DE, CO, MO, TN represent US states).
const Map<String, String> _countryFieldIso2Aliases = {
  'US': 'UNITED STATES',
  'GB': 'UNITED KINGDOM',
  'TW': 'TAIWAN',
  'AU': 'AUSTRALIA',
  'CA': 'CANADA',
  'NZ': 'NEW ZEALAND',
  'AE': 'UNITED ARAB EMIRATES',
  'KR': 'SOUTH KOREA',
  'TR': 'TURKEY',
  'CN': 'CHINA',
  'HK': 'HONG KONG',
  'MO': 'MACAO',
  'IE': 'IRELAND',
  'MX': 'MEXICO',
  'JP': 'JAPAN',
  'DE': 'GERMANY',
  'FR': 'FRANCE',
  'ES': 'SPAIN',
  'SG': 'SINGAPORE',
  'PH': 'PHILIPPINES',
  'VN': 'VIETNAM',
  'NL': 'NETHERLANDS',
  'CH': 'SWITZERLAND',
  'BR': 'BRAZIL',
  'CL': 'CHILE',
  'CO': 'COLOMBIA',
  'BH': 'BAHRAIN',
  'EG': 'EGYPT',
  'ET': 'ETHIOPIA',
  'FI': 'FINLAND',
  'JO': 'JORDAN',
  'MY': 'MALAYSIA',
  'MA': 'MOROCCO',
  'OM': 'OMAN',
  'PY': 'PARAGUAY',
  'SA': 'SAUDI ARABIA',
  'TH': 'THAILAND',
  'TN': 'TUNISIA',
};

const Map<String, String> _extraDivisionAliases = {
  'D.C.': 'DISTRICT OF COLUMBIA',
  'WASHINGTON, D.C.': 'DISTRICT OF COLUMBIA',
  'WASHINGTON D.C.': 'DISTRICT OF COLUMBIA',
  'WASHINGTON DC': 'DISTRICT OF COLUMBIA',
  'QUÉBEC': 'QUEBEC',
};

String _normalize(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

/// Canonicalizes a country or region filter string (e.g. "UK" -> "UNITED KINGDOM").
String canonicalizeCountryName(String value) {
  final clean = _normalize(value);
  if (clean.isEmpty) return '';
  return _unambiguousCountryAliases[clean] ??
      _countryFieldIso2Aliases[clean] ??
      regionAliases[clean]?.toUpperCase() ??
      clean;
}

/// Canonicalizes a division/state/province name or abbreviation (e.g. "TX" -> "TEXAS").
String canonicalizeDivisionName(String value) {
  final clean = _normalize(value);
  if (clean.isEmpty) return '';
  return divisionAliases[clean]?.toUpperCase() ??
      _extraDivisionAliases[clean] ??
      clean;
}

/// Checks whether an event's location fields match a single selected [targetRegion].
bool isEventInRegion({
  required String? country,
  required String? region,
  required String? city,
  required String? venue,
  required String targetRegion,
}) {
  final cleanTarget = _normalize(targetRegion);
  if (cleanTarget.isEmpty || cleanTarget == 'ALL') return true;

  final targetCountry = canonicalizeCountryName(cleanTarget);
  final eventCountry = _normalize(country ?? '');

  // When country is present on the event, treat it as authoritative so sub-regions
  // like "New South Wales" (Australia), "New Mexico" (US), or "Northern Ireland" (UK)
  // never bleed into another country's filter.
  if (eventCountry.isNotEmpty) {
    return canonicalizeCountryName(eventCountry) == targetCountry;
  }

  // Fallback when country metadata is absent: match against event.region only
  // (never city or venue), using exact canonical country or known child divisions.
  final eventRegion = _normalize(region ?? '');
  if (eventRegion.isEmpty) return false;

  final regionAsCountry = _unambiguousCountryAliases[eventRegion] ?? eventRegion;
  if (regionAsCountry == targetCountry) return true;

  final knownDivisions = _regionDivisionLists[targetCountry];
  if (knownDivisions != null) {
    final canonicalDiv = canonicalizeDivisionName(eventRegion);
    if (knownDivisions.any((d) => d.toUpperCase() == canonicalDiv)) {
      return true;
    }
  }

  return false;
}

/// Checks whether an event's location fields match a single selected [targetDivision].
bool isEventInDivision({
  required String? region,
  required String? city,
  required String? venue,
  required String targetDivision,
}) {
  final cleanTarget = _normalize(targetDivision);
  if (cleanTarget.isEmpty || cleanTarget == 'ALL') return true;

  final eventRegion = _normalize(region ?? '');
  if (eventRegion.isEmpty) return false;

  return canonicalizeDivisionName(eventRegion) == canonicalizeDivisionName(cleanTarget);
}
