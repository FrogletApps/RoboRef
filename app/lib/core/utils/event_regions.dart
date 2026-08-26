/// Configuration for a region's administrative divisions (e.g. States, Provinces)
class RegionDivisionConfig {
  final String singularLabel; // e.g. "State", "Province"
  final String pluralLabel;   // e.g. "States", "Provinces"
  final List<String> divisions;

  const RegionDivisionConfig({
    required this.singularLabel,
    required this.pluralLabel,
    required this.divisions,
  });
}

// Backwards compatibility alias
typedef CountryDivisionConfig = RegionDivisionConfig;

/// Official list of regions hosting VEX Robotics events
const List<String> vexRegions = [
  "Australia",
  "Bahrain",
  "Brazil",
  "Canada",
  "Chile",
  "China",
  "Colombia",
  "Egypt",
  "Ethiopia",
  "Finland",
  "France",
  "Germany",
  "Hong Kong",
  "Ireland",
  "Japan",
  "Jordan",
  "Macao",
  "Malaysia",
  "Mexico",
  "Morocco",
  "Netherlands",
  "New Zealand",
  "Oman",
  "Paraguay",
  "Philippines",
  "Saudi Arabia",
  "Singapore",
  "South Korea",
  "Spain",
  "Switzerland",
  "Taiwan",
  "Thailand",
  "Tunisia",
  "Turkey",
  "United Arab Emirates",
  "United Kingdom",
  "United States",
  "Vietnam",
];

// Backwards compatibility alias
const List<String> vexCountries = vexRegions;

/// Region-specific division lists with local terminology
const Map<String, RegionDivisionConfig> vexRegionDivisions = {
  'United States': RegionDivisionConfig(
    singularLabel: 'State',
    pluralLabel: 'States',
    divisions: [
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
    ],
  ),
  'Canada': RegionDivisionConfig(
    singularLabel: 'Province',
    pluralLabel: 'Provinces',
    divisions: [
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
    ],
  ),
};

// Backwards compatibility alias
const Map<String, RegionDivisionConfig> vexCountryDivisions = vexRegionDivisions;

/// Get division configuration for a region, or null if no division list is configured
RegionDivisionConfig? getRegionDivisionConfig(String? region) {
  if (region == null || region.isEmpty || region == 'All') return null;
  return vexRegionDivisions[region];
}

// Backwards compatibility alias
RegionDivisionConfig? getCountryDivisionConfig(String? country) => getRegionDivisionConfig(country);

/// Deduplicated and alphabetically sorted list of all VEX regions
List<String> getSortedVexRegions() {
  final set = vexRegions.toSet();
  final list = set.toList();
  list.sort((a, b) => a.compareTo(b));
  return list;
}

// Backwards compatibility alias
List<String> getSortedVexCountries() => getSortedVexRegions();

/// Shorthand region aliases to support quick lookup (e.g. "USA" -> "United States", "Chinese Taipei" -> "Taiwan")
const Map<String, String> regionAliases = {
  'USA': 'United States',
  'US': 'United States',
  'UK': 'United Kingdom',
  'GB': 'United Kingdom',
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

// Backwards compatibility alias
const Map<String, String> countryAliases = regionAliases;

/// Shorthand division aliases (e.g. "TX" -> "Texas", "ON" -> "Ontario", "NSW" -> "New South Wales")
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

