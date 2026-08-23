// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _programMeta =
      const VerificationMeta('program');
  @override
  late final GeneratedColumn<String> program = GeneratedColumn<String>(
      'program', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<String> season = GeneratedColumn<String>(
      'season', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
      'start_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _endDateMeta =
      const VerificationMeta('endDate');
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
      'end_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [sku, name, program, season, startDate, endDate, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('program')) {
      context.handle(_programMeta,
          program.isAcceptableOrUnknown(data['program']!, _programMeta));
    } else if (isInserting) {
      context.missing(_programMeta);
    }
    if (data.containsKey('season')) {
      context.handle(_seasonMeta,
          season.isAcceptableOrUnknown(data['season']!, _seasonMeta));
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(_endDateMeta,
          endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta));
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sku};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      program: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}program'])!,
      season: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}season'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_date'])!,
      endDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}end_date'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final String sku;
  final String name;
  final String program;
  final String season;
  final String startDate;
  final String endDate;
  final int updatedAt;
  const Event(
      {required this.sku,
      required this.name,
      required this.program,
      required this.season,
      required this.startDate,
      required this.endDate,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sku'] = Variable<String>(sku);
    map['name'] = Variable<String>(name);
    map['program'] = Variable<String>(program);
    map['season'] = Variable<String>(season);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      sku: Value(sku),
      name: Value(name),
      program: Value(program),
      season: Value(season),
      startDate: Value(startDate),
      endDate: Value(endDate),
      updatedAt: Value(updatedAt),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      sku: serializer.fromJson<String>(json['sku']),
      name: serializer.fromJson<String>(json['name']),
      program: serializer.fromJson<String>(json['program']),
      season: serializer.fromJson<String>(json['season']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sku': serializer.toJson<String>(sku),
      'name': serializer.toJson<String>(name),
      'program': serializer.toJson<String>(program),
      'season': serializer.toJson<String>(season),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Event copyWith(
          {String? sku,
          String? name,
          String? program,
          String? season,
          String? startDate,
          String? endDate,
          int? updatedAt}) =>
      Event(
        sku: sku ?? this.sku,
        name: name ?? this.name,
        program: program ?? this.program,
        season: season ?? this.season,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      sku: data.sku.present ? data.sku.value : this.sku,
      name: data.name.present ? data.name.value : this.name,
      program: data.program.present ? data.program.value : this.program,
      season: data.season.present ? data.season.value : this.season,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('program: $program, ')
          ..write('season: $season, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(sku, name, program, season, startDate, endDate, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.sku == this.sku &&
          other.name == this.name &&
          other.program == this.program &&
          other.season == this.season &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.updatedAt == this.updatedAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<String> sku;
  final Value<String> name;
  final Value<String> program;
  final Value<String> season;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.sku = const Value.absent(),
    this.name = const Value.absent(),
    this.program = const Value.absent(),
    this.season = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String sku,
    required String name,
    required String program,
    required String season,
    required String startDate,
    required String endDate,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : sku = Value(sku),
        name = Value(name),
        program = Value(program),
        season = Value(season),
        startDate = Value(startDate),
        endDate = Value(endDate),
        updatedAt = Value(updatedAt);
  static Insertable<Event> custom({
    Expression<String>? sku,
    Expression<String>? name,
    Expression<String>? program,
    Expression<String>? season,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sku != null) 'sku': sku,
      if (name != null) 'name': name,
      if (program != null) 'program': program,
      if (season != null) 'season': season,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith(
      {Value<String>? sku,
      Value<String>? name,
      Value<String>? program,
      Value<String>? season,
      Value<String>? startDate,
      Value<String>? endDate,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return EventsCompanion(
      sku: sku ?? this.sku,
      name: name ?? this.name,
      program: program ?? this.program,
      season: season ?? this.season,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (program.present) {
      map['program'] = Variable<String>(program.value);
    }
    if (season.present) {
      map['season'] = Variable<String>(season.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('sku: $sku, ')
          ..write('name: $name, ')
          ..write('program: $program, ')
          ..write('season: $season, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TeamsTable extends Teams with TableInfo<$TeamsTable, Team> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TeamsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _teamNumberMeta =
      const VerificationMeta('teamNumber');
  @override
  late final GeneratedColumn<String> teamNumber = GeneratedColumn<String>(
      'team_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamNameMeta =
      const VerificationMeta('teamName');
  @override
  late final GeneratedColumn<String> teamName = GeneratedColumn<String>(
      'team_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _organizationMeta =
      const VerificationMeta('organization');
  @override
  late final GeneratedColumn<String> organization = GeneratedColumn<String>(
      'organization', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
      'city', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _regionMeta = const VerificationMeta('region');
  @override
  late final GeneratedColumn<String> region = GeneratedColumn<String>(
      'region', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _countryMeta =
      const VerificationMeta('country');
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
      'country', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [teamNumber, teamName, sku, organization, city, region, country];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'teams';
  @override
  VerificationContext validateIntegrity(Insertable<Team> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('team_number')) {
      context.handle(
          _teamNumberMeta,
          teamNumber.isAcceptableOrUnknown(
              data['team_number']!, _teamNumberMeta));
    } else if (isInserting) {
      context.missing(_teamNumberMeta);
    }
    if (data.containsKey('team_name')) {
      context.handle(_teamNameMeta,
          teamName.isAcceptableOrUnknown(data['team_name']!, _teamNameMeta));
    } else if (isInserting) {
      context.missing(_teamNameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('organization')) {
      context.handle(
          _organizationMeta,
          organization.isAcceptableOrUnknown(
              data['organization']!, _organizationMeta));
    }
    if (data.containsKey('city')) {
      context.handle(
          _cityMeta, city.isAcceptableOrUnknown(data['city']!, _cityMeta));
    }
    if (data.containsKey('region')) {
      context.handle(_regionMeta,
          region.isAcceptableOrUnknown(data['region']!, _regionMeta));
    }
    if (data.containsKey('country')) {
      context.handle(_countryMeta,
          country.isAcceptableOrUnknown(data['country']!, _countryMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {teamNumber, sku};
  @override
  Team map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Team(
      teamNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_number'])!,
      teamName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_name'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      organization: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}organization']),
      city: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city']),
      region: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}region']),
      country: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}country']),
    );
  }

  @override
  $TeamsTable createAlias(String alias) {
    return $TeamsTable(attachedDatabase, alias);
  }
}

class Team extends DataClass implements Insertable<Team> {
  final String teamNumber;
  final String teamName;
  final String sku;
  final String? organization;
  final String? city;
  final String? region;
  final String? country;
  const Team(
      {required this.teamNumber,
      required this.teamName,
      required this.sku,
      this.organization,
      this.city,
      this.region,
      this.country});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['team_number'] = Variable<String>(teamNumber);
    map['team_name'] = Variable<String>(teamName);
    map['sku'] = Variable<String>(sku);
    if (!nullToAbsent || organization != null) {
      map['organization'] = Variable<String>(organization);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || region != null) {
      map['region'] = Variable<String>(region);
    }
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    return map;
  }

  TeamsCompanion toCompanion(bool nullToAbsent) {
    return TeamsCompanion(
      teamNumber: Value(teamNumber),
      teamName: Value(teamName),
      sku: Value(sku),
      organization: organization == null && nullToAbsent
          ? const Value.absent()
          : Value(organization),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      region:
          region == null && nullToAbsent ? const Value.absent() : Value(region),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
    );
  }

  factory Team.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Team(
      teamNumber: serializer.fromJson<String>(json['teamNumber']),
      teamName: serializer.fromJson<String>(json['teamName']),
      sku: serializer.fromJson<String>(json['sku']),
      organization: serializer.fromJson<String?>(json['organization']),
      city: serializer.fromJson<String?>(json['city']),
      region: serializer.fromJson<String?>(json['region']),
      country: serializer.fromJson<String?>(json['country']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'teamNumber': serializer.toJson<String>(teamNumber),
      'teamName': serializer.toJson<String>(teamName),
      'sku': serializer.toJson<String>(sku),
      'organization': serializer.toJson<String?>(organization),
      'city': serializer.toJson<String?>(city),
      'region': serializer.toJson<String?>(region),
      'country': serializer.toJson<String?>(country),
    };
  }

  Team copyWith(
          {String? teamNumber,
          String? teamName,
          String? sku,
          Value<String?> organization = const Value.absent(),
          Value<String?> city = const Value.absent(),
          Value<String?> region = const Value.absent(),
          Value<String?> country = const Value.absent()}) =>
      Team(
        teamNumber: teamNumber ?? this.teamNumber,
        teamName: teamName ?? this.teamName,
        sku: sku ?? this.sku,
        organization:
            organization.present ? organization.value : this.organization,
        city: city.present ? city.value : this.city,
        region: region.present ? region.value : this.region,
        country: country.present ? country.value : this.country,
      );
  Team copyWithCompanion(TeamsCompanion data) {
    return Team(
      teamNumber:
          data.teamNumber.present ? data.teamNumber.value : this.teamNumber,
      teamName: data.teamName.present ? data.teamName.value : this.teamName,
      sku: data.sku.present ? data.sku.value : this.sku,
      organization: data.organization.present
          ? data.organization.value
          : this.organization,
      city: data.city.present ? data.city.value : this.city,
      region: data.region.present ? data.region.value : this.region,
      country: data.country.present ? data.country.value : this.country,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Team(')
          ..write('teamNumber: $teamNumber, ')
          ..write('teamName: $teamName, ')
          ..write('sku: $sku, ')
          ..write('organization: $organization, ')
          ..write('city: $city, ')
          ..write('region: $region, ')
          ..write('country: $country')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      teamNumber, teamName, sku, organization, city, region, country);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Team &&
          other.teamNumber == this.teamNumber &&
          other.teamName == this.teamName &&
          other.sku == this.sku &&
          other.organization == this.organization &&
          other.city == this.city &&
          other.region == this.region &&
          other.country == this.country);
}

class TeamsCompanion extends UpdateCompanion<Team> {
  final Value<String> teamNumber;
  final Value<String> teamName;
  final Value<String> sku;
  final Value<String?> organization;
  final Value<String?> city;
  final Value<String?> region;
  final Value<String?> country;
  final Value<int> rowid;
  const TeamsCompanion({
    this.teamNumber = const Value.absent(),
    this.teamName = const Value.absent(),
    this.sku = const Value.absent(),
    this.organization = const Value.absent(),
    this.city = const Value.absent(),
    this.region = const Value.absent(),
    this.country = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TeamsCompanion.insert({
    required String teamNumber,
    required String teamName,
    required String sku,
    this.organization = const Value.absent(),
    this.city = const Value.absent(),
    this.region = const Value.absent(),
    this.country = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : teamNumber = Value(teamNumber),
        teamName = Value(teamName),
        sku = Value(sku);
  static Insertable<Team> custom({
    Expression<String>? teamNumber,
    Expression<String>? teamName,
    Expression<String>? sku,
    Expression<String>? organization,
    Expression<String>? city,
    Expression<String>? region,
    Expression<String>? country,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (teamNumber != null) 'team_number': teamNumber,
      if (teamName != null) 'team_name': teamName,
      if (sku != null) 'sku': sku,
      if (organization != null) 'organization': organization,
      if (city != null) 'city': city,
      if (region != null) 'region': region,
      if (country != null) 'country': country,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TeamsCompanion copyWith(
      {Value<String>? teamNumber,
      Value<String>? teamName,
      Value<String>? sku,
      Value<String?>? organization,
      Value<String?>? city,
      Value<String?>? region,
      Value<String?>? country,
      Value<int>? rowid}) {
    return TeamsCompanion(
      teamNumber: teamNumber ?? this.teamNumber,
      teamName: teamName ?? this.teamName,
      sku: sku ?? this.sku,
      organization: organization ?? this.organization,
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (teamNumber.present) {
      map['team_number'] = Variable<String>(teamNumber.value);
    }
    if (teamName.present) {
      map['team_name'] = Variable<String>(teamName.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (organization.present) {
      map['organization'] = Variable<String>(organization.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (region.present) {
      map['region'] = Variable<String>(region.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TeamsCompanion(')
          ..write('teamNumber: $teamNumber, ')
          ..write('teamName: $teamName, ')
          ..write('sku: $sku, ')
          ..write('organization: $organization, ')
          ..write('city: $city, ')
          ..write('region: $region, ')
          ..write('country: $country, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MatchesTable extends Matches with TableInfo<$MatchesTable, Matche> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _matchIdMeta =
      const VerificationMeta('matchId');
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
      'match_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _divisionIdMeta =
      const VerificationMeta('divisionId');
  @override
  late final GeneratedColumn<int> divisionId = GeneratedColumn<int>(
      'division_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
      'field', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _scheduledTimeMeta =
      const VerificationMeta('scheduledTime');
  @override
  late final GeneratedColumn<String> scheduledTime = GeneratedColumn<String>(
      'scheduled_time', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _redTeamsJsonMeta =
      const VerificationMeta('redTeamsJson');
  @override
  late final GeneratedColumn<String> redTeamsJson = GeneratedColumn<String>(
      'red_teams_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _blueTeamsJsonMeta =
      const VerificationMeta('blueTeamsJson');
  @override
  late final GeneratedColumn<String> blueTeamsJson = GeneratedColumn<String>(
      'blue_teams_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _redScoreMeta =
      const VerificationMeta('redScore');
  @override
  late final GeneratedColumn<int> redScore = GeneratedColumn<int>(
      'red_score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _blueScoreMeta =
      const VerificationMeta('blueScore');
  @override
  late final GeneratedColumn<int> blueScore = GeneratedColumn<int>(
      'blue_score', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        matchId,
        sku,
        divisionId,
        name,
        field,
        scheduledTime,
        redTeamsJson,
        blueTeamsJson,
        redScore,
        blueScore
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'matches';
  @override
  VerificationContext validateIntegrity(Insertable<Matche> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('match_id')) {
      context.handle(_matchIdMeta,
          matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta));
    } else if (isInserting) {
      context.missing(_matchIdMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('division_id')) {
      context.handle(
          _divisionIdMeta,
          divisionId.isAcceptableOrUnknown(
              data['division_id']!, _divisionIdMeta));
    } else if (isInserting) {
      context.missing(_divisionIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
          _fieldMeta, field.isAcceptableOrUnknown(data['field']!, _fieldMeta));
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
          _scheduledTimeMeta,
          scheduledTime.isAcceptableOrUnknown(
              data['scheduled_time']!, _scheduledTimeMeta));
    }
    if (data.containsKey('red_teams_json')) {
      context.handle(
          _redTeamsJsonMeta,
          redTeamsJson.isAcceptableOrUnknown(
              data['red_teams_json']!, _redTeamsJsonMeta));
    } else if (isInserting) {
      context.missing(_redTeamsJsonMeta);
    }
    if (data.containsKey('blue_teams_json')) {
      context.handle(
          _blueTeamsJsonMeta,
          blueTeamsJson.isAcceptableOrUnknown(
              data['blue_teams_json']!, _blueTeamsJsonMeta));
    } else if (isInserting) {
      context.missing(_blueTeamsJsonMeta);
    }
    if (data.containsKey('red_score')) {
      context.handle(_redScoreMeta,
          redScore.isAcceptableOrUnknown(data['red_score']!, _redScoreMeta));
    }
    if (data.containsKey('blue_score')) {
      context.handle(_blueScoreMeta,
          blueScore.isAcceptableOrUnknown(data['blue_score']!, _blueScoreMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {matchId, sku};
  @override
  Matche map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Matche(
      matchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_id'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      divisionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}division_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      field: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field']),
      scheduledTime: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}scheduled_time']),
      redTeamsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}red_teams_json'])!,
      blueTeamsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}blue_teams_json'])!,
      redScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}red_score']),
      blueScore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}blue_score']),
    );
  }

  @override
  $MatchesTable createAlias(String alias) {
    return $MatchesTable(attachedDatabase, alias);
  }
}

class Matche extends DataClass implements Insertable<Matche> {
  final String matchId;
  final String sku;
  final int divisionId;
  final String name;
  final String? field;
  final String? scheduledTime;
  final String redTeamsJson;
  final String blueTeamsJson;
  final int? redScore;
  final int? blueScore;
  const Matche(
      {required this.matchId,
      required this.sku,
      required this.divisionId,
      required this.name,
      this.field,
      this.scheduledTime,
      required this.redTeamsJson,
      required this.blueTeamsJson,
      this.redScore,
      this.blueScore});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['match_id'] = Variable<String>(matchId);
    map['sku'] = Variable<String>(sku);
    map['division_id'] = Variable<int>(divisionId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || field != null) {
      map['field'] = Variable<String>(field);
    }
    if (!nullToAbsent || scheduledTime != null) {
      map['scheduled_time'] = Variable<String>(scheduledTime);
    }
    map['red_teams_json'] = Variable<String>(redTeamsJson);
    map['blue_teams_json'] = Variable<String>(blueTeamsJson);
    if (!nullToAbsent || redScore != null) {
      map['red_score'] = Variable<int>(redScore);
    }
    if (!nullToAbsent || blueScore != null) {
      map['blue_score'] = Variable<int>(blueScore);
    }
    return map;
  }

  MatchesCompanion toCompanion(bool nullToAbsent) {
    return MatchesCompanion(
      matchId: Value(matchId),
      sku: Value(sku),
      divisionId: Value(divisionId),
      name: Value(name),
      field:
          field == null && nullToAbsent ? const Value.absent() : Value(field),
      scheduledTime: scheduledTime == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduledTime),
      redTeamsJson: Value(redTeamsJson),
      blueTeamsJson: Value(blueTeamsJson),
      redScore: redScore == null && nullToAbsent
          ? const Value.absent()
          : Value(redScore),
      blueScore: blueScore == null && nullToAbsent
          ? const Value.absent()
          : Value(blueScore),
    );
  }

  factory Matche.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Matche(
      matchId: serializer.fromJson<String>(json['matchId']),
      sku: serializer.fromJson<String>(json['sku']),
      divisionId: serializer.fromJson<int>(json['divisionId']),
      name: serializer.fromJson<String>(json['name']),
      field: serializer.fromJson<String?>(json['field']),
      scheduledTime: serializer.fromJson<String?>(json['scheduledTime']),
      redTeamsJson: serializer.fromJson<String>(json['redTeamsJson']),
      blueTeamsJson: serializer.fromJson<String>(json['blueTeamsJson']),
      redScore: serializer.fromJson<int?>(json['redScore']),
      blueScore: serializer.fromJson<int?>(json['blueScore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'matchId': serializer.toJson<String>(matchId),
      'sku': serializer.toJson<String>(sku),
      'divisionId': serializer.toJson<int>(divisionId),
      'name': serializer.toJson<String>(name),
      'field': serializer.toJson<String?>(field),
      'scheduledTime': serializer.toJson<String?>(scheduledTime),
      'redTeamsJson': serializer.toJson<String>(redTeamsJson),
      'blueTeamsJson': serializer.toJson<String>(blueTeamsJson),
      'redScore': serializer.toJson<int?>(redScore),
      'blueScore': serializer.toJson<int?>(blueScore),
    };
  }

  Matche copyWith(
          {String? matchId,
          String? sku,
          int? divisionId,
          String? name,
          Value<String?> field = const Value.absent(),
          Value<String?> scheduledTime = const Value.absent(),
          String? redTeamsJson,
          String? blueTeamsJson,
          Value<int?> redScore = const Value.absent(),
          Value<int?> blueScore = const Value.absent()}) =>
      Matche(
        matchId: matchId ?? this.matchId,
        sku: sku ?? this.sku,
        divisionId: divisionId ?? this.divisionId,
        name: name ?? this.name,
        field: field.present ? field.value : this.field,
        scheduledTime:
            scheduledTime.present ? scheduledTime.value : this.scheduledTime,
        redTeamsJson: redTeamsJson ?? this.redTeamsJson,
        blueTeamsJson: blueTeamsJson ?? this.blueTeamsJson,
        redScore: redScore.present ? redScore.value : this.redScore,
        blueScore: blueScore.present ? blueScore.value : this.blueScore,
      );
  Matche copyWithCompanion(MatchesCompanion data) {
    return Matche(
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      sku: data.sku.present ? data.sku.value : this.sku,
      divisionId:
          data.divisionId.present ? data.divisionId.value : this.divisionId,
      name: data.name.present ? data.name.value : this.name,
      field: data.field.present ? data.field.value : this.field,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      redTeamsJson: data.redTeamsJson.present
          ? data.redTeamsJson.value
          : this.redTeamsJson,
      blueTeamsJson: data.blueTeamsJson.present
          ? data.blueTeamsJson.value
          : this.blueTeamsJson,
      redScore: data.redScore.present ? data.redScore.value : this.redScore,
      blueScore: data.blueScore.present ? data.blueScore.value : this.blueScore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Matche(')
          ..write('matchId: $matchId, ')
          ..write('sku: $sku, ')
          ..write('divisionId: $divisionId, ')
          ..write('name: $name, ')
          ..write('field: $field, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('redTeamsJson: $redTeamsJson, ')
          ..write('blueTeamsJson: $blueTeamsJson, ')
          ..write('redScore: $redScore, ')
          ..write('blueScore: $blueScore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(matchId, sku, divisionId, name, field,
      scheduledTime, redTeamsJson, blueTeamsJson, redScore, blueScore);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Matche &&
          other.matchId == this.matchId &&
          other.sku == this.sku &&
          other.divisionId == this.divisionId &&
          other.name == this.name &&
          other.field == this.field &&
          other.scheduledTime == this.scheduledTime &&
          other.redTeamsJson == this.redTeamsJson &&
          other.blueTeamsJson == this.blueTeamsJson &&
          other.redScore == this.redScore &&
          other.blueScore == this.blueScore);
}

class MatchesCompanion extends UpdateCompanion<Matche> {
  final Value<String> matchId;
  final Value<String> sku;
  final Value<int> divisionId;
  final Value<String> name;
  final Value<String?> field;
  final Value<String?> scheduledTime;
  final Value<String> redTeamsJson;
  final Value<String> blueTeamsJson;
  final Value<int?> redScore;
  final Value<int?> blueScore;
  final Value<int> rowid;
  const MatchesCompanion({
    this.matchId = const Value.absent(),
    this.sku = const Value.absent(),
    this.divisionId = const Value.absent(),
    this.name = const Value.absent(),
    this.field = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.redTeamsJson = const Value.absent(),
    this.blueTeamsJson = const Value.absent(),
    this.redScore = const Value.absent(),
    this.blueScore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MatchesCompanion.insert({
    required String matchId,
    required String sku,
    required int divisionId,
    required String name,
    this.field = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    required String redTeamsJson,
    required String blueTeamsJson,
    this.redScore = const Value.absent(),
    this.blueScore = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : matchId = Value(matchId),
        sku = Value(sku),
        divisionId = Value(divisionId),
        name = Value(name),
        redTeamsJson = Value(redTeamsJson),
        blueTeamsJson = Value(blueTeamsJson);
  static Insertable<Matche> custom({
    Expression<String>? matchId,
    Expression<String>? sku,
    Expression<int>? divisionId,
    Expression<String>? name,
    Expression<String>? field,
    Expression<String>? scheduledTime,
    Expression<String>? redTeamsJson,
    Expression<String>? blueTeamsJson,
    Expression<int>? redScore,
    Expression<int>? blueScore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (matchId != null) 'match_id': matchId,
      if (sku != null) 'sku': sku,
      if (divisionId != null) 'division_id': divisionId,
      if (name != null) 'name': name,
      if (field != null) 'field': field,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (redTeamsJson != null) 'red_teams_json': redTeamsJson,
      if (blueTeamsJson != null) 'blue_teams_json': blueTeamsJson,
      if (redScore != null) 'red_score': redScore,
      if (blueScore != null) 'blue_score': blueScore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MatchesCompanion copyWith(
      {Value<String>? matchId,
      Value<String>? sku,
      Value<int>? divisionId,
      Value<String>? name,
      Value<String?>? field,
      Value<String?>? scheduledTime,
      Value<String>? redTeamsJson,
      Value<String>? blueTeamsJson,
      Value<int?>? redScore,
      Value<int?>? blueScore,
      Value<int>? rowid}) {
    return MatchesCompanion(
      matchId: matchId ?? this.matchId,
      sku: sku ?? this.sku,
      divisionId: divisionId ?? this.divisionId,
      name: name ?? this.name,
      field: field ?? this.field,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      redTeamsJson: redTeamsJson ?? this.redTeamsJson,
      blueTeamsJson: blueTeamsJson ?? this.blueTeamsJson,
      redScore: redScore ?? this.redScore,
      blueScore: blueScore ?? this.blueScore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (divisionId.present) {
      map['division_id'] = Variable<int>(divisionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<String>(scheduledTime.value);
    }
    if (redTeamsJson.present) {
      map['red_teams_json'] = Variable<String>(redTeamsJson.value);
    }
    if (blueTeamsJson.present) {
      map['blue_teams_json'] = Variable<String>(blueTeamsJson.value);
    }
    if (redScore.present) {
      map['red_score'] = Variable<int>(redScore.value);
    }
    if (blueScore.present) {
      map['blue_score'] = Variable<int>(blueScore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MatchesCompanion(')
          ..write('matchId: $matchId, ')
          ..write('sku: $sku, ')
          ..write('divisionId: $divisionId, ')
          ..write('name: $name, ')
          ..write('field: $field, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('redTeamsJson: $redTeamsJson, ')
          ..write('blueTeamsJson: $blueTeamsJson, ')
          ..write('redScore: $redScore, ')
          ..write('blueScore: $blueScore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncidentNotesTable extends IncidentNotes
    with TableInfo<$IncidentNotesTable, IncidentNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncidentNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _teamNumberMeta =
      const VerificationMeta('teamNumber');
  @override
  late final GeneratedColumn<String> teamNumber = GeneratedColumn<String>(
      'team_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matchIdMeta =
      const VerificationMeta('matchId');
  @override
  late final GeneratedColumn<String> matchId = GeneratedColumn<String>(
      'match_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ruleCodesJsonMeta =
      const VerificationMeta('ruleCodesJson');
  @override
  late final GeneratedColumn<String> ruleCodesJson = GeneratedColumn<String>(
      'rule_codes_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _refereeNameMeta =
      const VerificationMeta('refereeName');
  @override
  late final GeneratedColumn<String> refereeName = GeneratedColumn<String>(
      'referee_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isDeletedMeta =
      const VerificationMeta('isDeleted');
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
      'is_deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        sku,
        teamNumber,
        matchId,
        ruleCodesJson,
        severity,
        notes,
        refereeName,
        deviceId,
        createdAt,
        updatedAt,
        isDeleted,
        version,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incident_notes';
  @override
  VerificationContext validateIntegrity(Insertable<IncidentNote> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('team_number')) {
      context.handle(
          _teamNumberMeta,
          teamNumber.isAcceptableOrUnknown(
              data['team_number']!, _teamNumberMeta));
    } else if (isInserting) {
      context.missing(_teamNumberMeta);
    }
    if (data.containsKey('match_id')) {
      context.handle(_matchIdMeta,
          matchId.isAcceptableOrUnknown(data['match_id']!, _matchIdMeta));
    }
    if (data.containsKey('rule_codes_json')) {
      context.handle(
          _ruleCodesJsonMeta,
          ruleCodesJson.isAcceptableOrUnknown(
              data['rule_codes_json']!, _ruleCodesJsonMeta));
    } else if (isInserting) {
      context.missing(_ruleCodesJsonMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('referee_name')) {
      context.handle(
          _refereeNameMeta,
          refereeName.isAcceptableOrUnknown(
              data['referee_name']!, _refereeNameMeta));
    } else if (isInserting) {
      context.missing(_refereeNameMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(_isDeletedMeta,
          isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta));
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncidentNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncidentNote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku'])!,
      teamNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}team_number'])!,
      matchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}match_id']),
      ruleCodesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}rule_codes_json'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      refereeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}referee_name'])!,
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      isDeleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_deleted'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $IncidentNotesTable createAlias(String alias) {
    return $IncidentNotesTable(attachedDatabase, alias);
  }
}

class IncidentNote extends DataClass implements Insertable<IncidentNote> {
  final String id;
  final String sku;
  final String teamNumber;
  final String? matchId;
  final String ruleCodesJson;
  final String severity;
  final String notes;
  final String refereeName;
  final String deviceId;
  final int createdAt;
  final int updatedAt;
  final bool isDeleted;
  final int version;
  final bool isSynced;
  const IncidentNote(
      {required this.id,
      required this.sku,
      required this.teamNumber,
      this.matchId,
      required this.ruleCodesJson,
      required this.severity,
      required this.notes,
      required this.refereeName,
      required this.deviceId,
      required this.createdAt,
      required this.updatedAt,
      required this.isDeleted,
      required this.version,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sku'] = Variable<String>(sku);
    map['team_number'] = Variable<String>(teamNumber);
    if (!nullToAbsent || matchId != null) {
      map['match_id'] = Variable<String>(matchId);
    }
    map['rule_codes_json'] = Variable<String>(ruleCodesJson);
    map['severity'] = Variable<String>(severity);
    map['notes'] = Variable<String>(notes);
    map['referee_name'] = Variable<String>(refereeName);
    map['device_id'] = Variable<String>(deviceId);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['version'] = Variable<int>(version);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  IncidentNotesCompanion toCompanion(bool nullToAbsent) {
    return IncidentNotesCompanion(
      id: Value(id),
      sku: Value(sku),
      teamNumber: Value(teamNumber),
      matchId: matchId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchId),
      ruleCodesJson: Value(ruleCodesJson),
      severity: Value(severity),
      notes: Value(notes),
      refereeName: Value(refereeName),
      deviceId: Value(deviceId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      version: Value(version),
      isSynced: Value(isSynced),
    );
  }

  factory IncidentNote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncidentNote(
      id: serializer.fromJson<String>(json['id']),
      sku: serializer.fromJson<String>(json['sku']),
      teamNumber: serializer.fromJson<String>(json['teamNumber']),
      matchId: serializer.fromJson<String?>(json['matchId']),
      ruleCodesJson: serializer.fromJson<String>(json['ruleCodesJson']),
      severity: serializer.fromJson<String>(json['severity']),
      notes: serializer.fromJson<String>(json['notes']),
      refereeName: serializer.fromJson<String>(json['refereeName']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      version: serializer.fromJson<int>(json['version']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sku': serializer.toJson<String>(sku),
      'teamNumber': serializer.toJson<String>(teamNumber),
      'matchId': serializer.toJson<String?>(matchId),
      'ruleCodesJson': serializer.toJson<String>(ruleCodesJson),
      'severity': serializer.toJson<String>(severity),
      'notes': serializer.toJson<String>(notes),
      'refereeName': serializer.toJson<String>(refereeName),
      'deviceId': serializer.toJson<String>(deviceId),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'version': serializer.toJson<int>(version),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  IncidentNote copyWith(
          {String? id,
          String? sku,
          String? teamNumber,
          Value<String?> matchId = const Value.absent(),
          String? ruleCodesJson,
          String? severity,
          String? notes,
          String? refereeName,
          String? deviceId,
          int? createdAt,
          int? updatedAt,
          bool? isDeleted,
          int? version,
          bool? isSynced}) =>
      IncidentNote(
        id: id ?? this.id,
        sku: sku ?? this.sku,
        teamNumber: teamNumber ?? this.teamNumber,
        matchId: matchId.present ? matchId.value : this.matchId,
        ruleCodesJson: ruleCodesJson ?? this.ruleCodesJson,
        severity: severity ?? this.severity,
        notes: notes ?? this.notes,
        refereeName: refereeName ?? this.refereeName,
        deviceId: deviceId ?? this.deviceId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        version: version ?? this.version,
        isSynced: isSynced ?? this.isSynced,
      );
  IncidentNote copyWithCompanion(IncidentNotesCompanion data) {
    return IncidentNote(
      id: data.id.present ? data.id.value : this.id,
      sku: data.sku.present ? data.sku.value : this.sku,
      teamNumber:
          data.teamNumber.present ? data.teamNumber.value : this.teamNumber,
      matchId: data.matchId.present ? data.matchId.value : this.matchId,
      ruleCodesJson: data.ruleCodesJson.present
          ? data.ruleCodesJson.value
          : this.ruleCodesJson,
      severity: data.severity.present ? data.severity.value : this.severity,
      notes: data.notes.present ? data.notes.value : this.notes,
      refereeName:
          data.refereeName.present ? data.refereeName.value : this.refereeName,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      version: data.version.present ? data.version.value : this.version,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncidentNote(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('teamNumber: $teamNumber, ')
          ..write('matchId: $matchId, ')
          ..write('ruleCodesJson: $ruleCodesJson, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes, ')
          ..write('refereeName: $refereeName, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('version: $version, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      sku,
      teamNumber,
      matchId,
      ruleCodesJson,
      severity,
      notes,
      refereeName,
      deviceId,
      createdAt,
      updatedAt,
      isDeleted,
      version,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncidentNote &&
          other.id == this.id &&
          other.sku == this.sku &&
          other.teamNumber == this.teamNumber &&
          other.matchId == this.matchId &&
          other.ruleCodesJson == this.ruleCodesJson &&
          other.severity == this.severity &&
          other.notes == this.notes &&
          other.refereeName == this.refereeName &&
          other.deviceId == this.deviceId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.version == this.version &&
          other.isSynced == this.isSynced);
}

class IncidentNotesCompanion extends UpdateCompanion<IncidentNote> {
  final Value<String> id;
  final Value<String> sku;
  final Value<String> teamNumber;
  final Value<String?> matchId;
  final Value<String> ruleCodesJson;
  final Value<String> severity;
  final Value<String> notes;
  final Value<String> refereeName;
  final Value<String> deviceId;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<bool> isDeleted;
  final Value<int> version;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const IncidentNotesCompanion({
    this.id = const Value.absent(),
    this.sku = const Value.absent(),
    this.teamNumber = const Value.absent(),
    this.matchId = const Value.absent(),
    this.ruleCodesJson = const Value.absent(),
    this.severity = const Value.absent(),
    this.notes = const Value.absent(),
    this.refereeName = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.version = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncidentNotesCompanion.insert({
    required String id,
    required String sku,
    required String teamNumber,
    this.matchId = const Value.absent(),
    required String ruleCodesJson,
    required String severity,
    required String notes,
    required String refereeName,
    required String deviceId,
    required int createdAt,
    required int updatedAt,
    this.isDeleted = const Value.absent(),
    this.version = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sku = Value(sku),
        teamNumber = Value(teamNumber),
        ruleCodesJson = Value(ruleCodesJson),
        severity = Value(severity),
        notes = Value(notes),
        refereeName = Value(refereeName),
        deviceId = Value(deviceId),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<IncidentNote> custom({
    Expression<String>? id,
    Expression<String>? sku,
    Expression<String>? teamNumber,
    Expression<String>? matchId,
    Expression<String>? ruleCodesJson,
    Expression<String>? severity,
    Expression<String>? notes,
    Expression<String>? refereeName,
    Expression<String>? deviceId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<int>? version,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sku != null) 'sku': sku,
      if (teamNumber != null) 'team_number': teamNumber,
      if (matchId != null) 'match_id': matchId,
      if (ruleCodesJson != null) 'rule_codes_json': ruleCodesJson,
      if (severity != null) 'severity': severity,
      if (notes != null) 'notes': notes,
      if (refereeName != null) 'referee_name': refereeName,
      if (deviceId != null) 'device_id': deviceId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (version != null) 'version': version,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncidentNotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? sku,
      Value<String>? teamNumber,
      Value<String?>? matchId,
      Value<String>? ruleCodesJson,
      Value<String>? severity,
      Value<String>? notes,
      Value<String>? refereeName,
      Value<String>? deviceId,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<bool>? isDeleted,
      Value<int>? version,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return IncidentNotesCompanion(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      teamNumber: teamNumber ?? this.teamNumber,
      matchId: matchId ?? this.matchId,
      ruleCodesJson: ruleCodesJson ?? this.ruleCodesJson,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      refereeName: refereeName ?? this.refereeName,
      deviceId: deviceId ?? this.deviceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      version: version ?? this.version,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (teamNumber.present) {
      map['team_number'] = Variable<String>(teamNumber.value);
    }
    if (matchId.present) {
      map['match_id'] = Variable<String>(matchId.value);
    }
    if (ruleCodesJson.present) {
      map['rule_codes_json'] = Variable<String>(ruleCodesJson.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (refereeName.present) {
      map['referee_name'] = Variable<String>(refereeName.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncidentNotesCompanion(')
          ..write('id: $id, ')
          ..write('sku: $sku, ')
          ..write('teamNumber: $teamNumber, ')
          ..write('matchId: $matchId, ')
          ..write('ruleCodesJson: $ruleCodesJson, ')
          ..write('severity: $severity, ')
          ..write('notes: $notes, ')
          ..write('refereeName: $refereeName, ')
          ..write('deviceId: $deviceId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('version: $version, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventsTable events = $EventsTable(this);
  late final $TeamsTable teams = $TeamsTable(this);
  late final $MatchesTable matches = $MatchesTable(this);
  late final $IncidentNotesTable incidentNotes = $IncidentNotesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [events, teams, matches, incidentNotes];
}

typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  required String sku,
  required String name,
  required String program,
  required String season,
  required String startDate,
  required String endDate,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> sku,
  Value<String> name,
  Value<String> program,
  Value<String> season,
  Value<String> startDate,
  Value<String> endDate,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get program => $composableBuilder(
      column: $table.program, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get program => $composableBuilder(
      column: $table.program, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get season => $composableBuilder(
      column: $table.season, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endDate => $composableBuilder(
      column: $table.endDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get program =>
      $composableBuilder(column: $table.program, builder: (column) => column);

  GeneratedColumn<String> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
    Event,
    PrefetchHooks Function()> {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sku = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> program = const Value.absent(),
            Value<String> season = const Value.absent(),
            Value<String> startDate = const Value.absent(),
            Value<String> endDate = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventsCompanion(
            sku: sku,
            name: name,
            program: program,
            season: season,
            startDate: startDate,
            endDate: endDate,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sku,
            required String name,
            required String program,
            required String season,
            required String startDate,
            required String endDate,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EventsCompanion.insert(
            sku: sku,
            name: name,
            program: program,
            season: season,
            startDate: startDate,
            endDate: endDate,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
    Event,
    PrefetchHooks Function()>;
typedef $$TeamsTableCreateCompanionBuilder = TeamsCompanion Function({
  required String teamNumber,
  required String teamName,
  required String sku,
  Value<String?> organization,
  Value<String?> city,
  Value<String?> region,
  Value<String?> country,
  Value<int> rowid,
});
typedef $$TeamsTableUpdateCompanionBuilder = TeamsCompanion Function({
  Value<String> teamNumber,
  Value<String> teamName,
  Value<String> sku,
  Value<String?> organization,
  Value<String?> city,
  Value<String?> region,
  Value<String?> country,
  Value<int> rowid,
});

class $$TeamsTableFilterComposer extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get teamNumber => $composableBuilder(
      column: $table.teamNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamName => $composableBuilder(
      column: $table.teamName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get organization => $composableBuilder(
      column: $table.organization, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnFilters(column));
}

class $$TeamsTableOrderingComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get teamNumber => $composableBuilder(
      column: $table.teamNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamName => $composableBuilder(
      column: $table.teamName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get organization => $composableBuilder(
      column: $table.organization,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get region => $composableBuilder(
      column: $table.region, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get country => $composableBuilder(
      column: $table.country, builder: (column) => ColumnOrderings(column));
}

class $$TeamsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TeamsTable> {
  $$TeamsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get teamNumber => $composableBuilder(
      column: $table.teamNumber, builder: (column) => column);

  GeneratedColumn<String> get teamName =>
      $composableBuilder(column: $table.teamName, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get organization => $composableBuilder(
      column: $table.organization, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get region =>
      $composableBuilder(column: $table.region, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);
}

class $$TeamsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TeamsTable,
    Team,
    $$TeamsTableFilterComposer,
    $$TeamsTableOrderingComposer,
    $$TeamsTableAnnotationComposer,
    $$TeamsTableCreateCompanionBuilder,
    $$TeamsTableUpdateCompanionBuilder,
    (Team, BaseReferences<_$AppDatabase, $TeamsTable, Team>),
    Team,
    PrefetchHooks Function()> {
  $$TeamsTableTableManager(_$AppDatabase db, $TeamsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TeamsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TeamsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TeamsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> teamNumber = const Value.absent(),
            Value<String> teamName = const Value.absent(),
            Value<String> sku = const Value.absent(),
            Value<String?> organization = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<String?> region = const Value.absent(),
            Value<String?> country = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeamsCompanion(
            teamNumber: teamNumber,
            teamName: teamName,
            sku: sku,
            organization: organization,
            city: city,
            region: region,
            country: country,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String teamNumber,
            required String teamName,
            required String sku,
            Value<String?> organization = const Value.absent(),
            Value<String?> city = const Value.absent(),
            Value<String?> region = const Value.absent(),
            Value<String?> country = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TeamsCompanion.insert(
            teamNumber: teamNumber,
            teamName: teamName,
            sku: sku,
            organization: organization,
            city: city,
            region: region,
            country: country,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TeamsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TeamsTable,
    Team,
    $$TeamsTableFilterComposer,
    $$TeamsTableOrderingComposer,
    $$TeamsTableAnnotationComposer,
    $$TeamsTableCreateCompanionBuilder,
    $$TeamsTableUpdateCompanionBuilder,
    (Team, BaseReferences<_$AppDatabase, $TeamsTable, Team>),
    Team,
    PrefetchHooks Function()>;
typedef $$MatchesTableCreateCompanionBuilder = MatchesCompanion Function({
  required String matchId,
  required String sku,
  required int divisionId,
  required String name,
  Value<String?> field,
  Value<String?> scheduledTime,
  required String redTeamsJson,
  required String blueTeamsJson,
  Value<int?> redScore,
  Value<int?> blueScore,
  Value<int> rowid,
});
typedef $$MatchesTableUpdateCompanionBuilder = MatchesCompanion Function({
  Value<String> matchId,
  Value<String> sku,
  Value<int> divisionId,
  Value<String> name,
  Value<String?> field,
  Value<String?> scheduledTime,
  Value<String> redTeamsJson,
  Value<String> blueTeamsJson,
  Value<int?> redScore,
  Value<int?> blueScore,
  Value<int> rowid,
});

class $$MatchesTableFilterComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get matchId => $composableBuilder(
      column: $table.matchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get divisionId => $composableBuilder(
      column: $table.divisionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get field => $composableBuilder(
      column: $table.field, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get scheduledTime => $composableBuilder(
      column: $table.scheduledTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get redTeamsJson => $composableBuilder(
      column: $table.redTeamsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get blueTeamsJson => $composableBuilder(
      column: $table.blueTeamsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get redScore => $composableBuilder(
      column: $table.redScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get blueScore => $composableBuilder(
      column: $table.blueScore, builder: (column) => ColumnFilters(column));
}

class $$MatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get matchId => $composableBuilder(
      column: $table.matchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get divisionId => $composableBuilder(
      column: $table.divisionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get field => $composableBuilder(
      column: $table.field, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scheduledTime => $composableBuilder(
      column: $table.scheduledTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get redTeamsJson => $composableBuilder(
      column: $table.redTeamsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get blueTeamsJson => $composableBuilder(
      column: $table.blueTeamsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get redScore => $composableBuilder(
      column: $table.redScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get blueScore => $composableBuilder(
      column: $table.blueScore, builder: (column) => ColumnOrderings(column));
}

class $$MatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MatchesTable> {
  $$MatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<int> get divisionId => $composableBuilder(
      column: $table.divisionId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<String> get scheduledTime => $composableBuilder(
      column: $table.scheduledTime, builder: (column) => column);

  GeneratedColumn<String> get redTeamsJson => $composableBuilder(
      column: $table.redTeamsJson, builder: (column) => column);

  GeneratedColumn<String> get blueTeamsJson => $composableBuilder(
      column: $table.blueTeamsJson, builder: (column) => column);

  GeneratedColumn<int> get redScore =>
      $composableBuilder(column: $table.redScore, builder: (column) => column);

  GeneratedColumn<int> get blueScore =>
      $composableBuilder(column: $table.blueScore, builder: (column) => column);
}

class $$MatchesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MatchesTable,
    Matche,
    $$MatchesTableFilterComposer,
    $$MatchesTableOrderingComposer,
    $$MatchesTableAnnotationComposer,
    $$MatchesTableCreateCompanionBuilder,
    $$MatchesTableUpdateCompanionBuilder,
    (Matche, BaseReferences<_$AppDatabase, $MatchesTable, Matche>),
    Matche,
    PrefetchHooks Function()> {
  $$MatchesTableTableManager(_$AppDatabase db, $MatchesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> matchId = const Value.absent(),
            Value<String> sku = const Value.absent(),
            Value<int> divisionId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> field = const Value.absent(),
            Value<String?> scheduledTime = const Value.absent(),
            Value<String> redTeamsJson = const Value.absent(),
            Value<String> blueTeamsJson = const Value.absent(),
            Value<int?> redScore = const Value.absent(),
            Value<int?> blueScore = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MatchesCompanion(
            matchId: matchId,
            sku: sku,
            divisionId: divisionId,
            name: name,
            field: field,
            scheduledTime: scheduledTime,
            redTeamsJson: redTeamsJson,
            blueTeamsJson: blueTeamsJson,
            redScore: redScore,
            blueScore: blueScore,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String matchId,
            required String sku,
            required int divisionId,
            required String name,
            Value<String?> field = const Value.absent(),
            Value<String?> scheduledTime = const Value.absent(),
            required String redTeamsJson,
            required String blueTeamsJson,
            Value<int?> redScore = const Value.absent(),
            Value<int?> blueScore = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MatchesCompanion.insert(
            matchId: matchId,
            sku: sku,
            divisionId: divisionId,
            name: name,
            field: field,
            scheduledTime: scheduledTime,
            redTeamsJson: redTeamsJson,
            blueTeamsJson: blueTeamsJson,
            redScore: redScore,
            blueScore: blueScore,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MatchesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MatchesTable,
    Matche,
    $$MatchesTableFilterComposer,
    $$MatchesTableOrderingComposer,
    $$MatchesTableAnnotationComposer,
    $$MatchesTableCreateCompanionBuilder,
    $$MatchesTableUpdateCompanionBuilder,
    (Matche, BaseReferences<_$AppDatabase, $MatchesTable, Matche>),
    Matche,
    PrefetchHooks Function()>;
typedef $$IncidentNotesTableCreateCompanionBuilder = IncidentNotesCompanion
    Function({
  required String id,
  required String sku,
  required String teamNumber,
  Value<String?> matchId,
  required String ruleCodesJson,
  required String severity,
  required String notes,
  required String refereeName,
  required String deviceId,
  required int createdAt,
  required int updatedAt,
  Value<bool> isDeleted,
  Value<int> version,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$IncidentNotesTableUpdateCompanionBuilder = IncidentNotesCompanion
    Function({
  Value<String> id,
  Value<String> sku,
  Value<String> teamNumber,
  Value<String?> matchId,
  Value<String> ruleCodesJson,
  Value<String> severity,
  Value<String> notes,
  Value<String> refereeName,
  Value<String> deviceId,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<bool> isDeleted,
  Value<int> version,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$IncidentNotesTableFilterComposer
    extends Composer<_$AppDatabase, $IncidentNotesTable> {
  $$IncidentNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get teamNumber => $composableBuilder(
      column: $table.teamNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchId => $composableBuilder(
      column: $table.matchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ruleCodesJson => $composableBuilder(
      column: $table.ruleCodesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get refereeName => $composableBuilder(
      column: $table.refereeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$IncidentNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $IncidentNotesTable> {
  $$IncidentNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get teamNumber => $composableBuilder(
      column: $table.teamNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchId => $composableBuilder(
      column: $table.matchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ruleCodesJson => $composableBuilder(
      column: $table.ruleCodesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get refereeName => $composableBuilder(
      column: $table.refereeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
      column: $table.isDeleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$IncidentNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncidentNotesTable> {
  $$IncidentNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get teamNumber => $composableBuilder(
      column: $table.teamNumber, builder: (column) => column);

  GeneratedColumn<String> get matchId =>
      $composableBuilder(column: $table.matchId, builder: (column) => column);

  GeneratedColumn<String> get ruleCodesJson => $composableBuilder(
      column: $table.ruleCodesJson, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get refereeName => $composableBuilder(
      column: $table.refereeName, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$IncidentNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $IncidentNotesTable,
    IncidentNote,
    $$IncidentNotesTableFilterComposer,
    $$IncidentNotesTableOrderingComposer,
    $$IncidentNotesTableAnnotationComposer,
    $$IncidentNotesTableCreateCompanionBuilder,
    $$IncidentNotesTableUpdateCompanionBuilder,
    (
      IncidentNote,
      BaseReferences<_$AppDatabase, $IncidentNotesTable, IncidentNote>
    ),
    IncidentNote,
    PrefetchHooks Function()> {
  $$IncidentNotesTableTableManager(_$AppDatabase db, $IncidentNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncidentNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncidentNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncidentNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sku = const Value.absent(),
            Value<String> teamNumber = const Value.absent(),
            Value<String?> matchId = const Value.absent(),
            Value<String> ruleCodesJson = const Value.absent(),
            Value<String> severity = const Value.absent(),
            Value<String> notes = const Value.absent(),
            Value<String> refereeName = const Value.absent(),
            Value<String> deviceId = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<bool> isDeleted = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IncidentNotesCompanion(
            id: id,
            sku: sku,
            teamNumber: teamNumber,
            matchId: matchId,
            ruleCodesJson: ruleCodesJson,
            severity: severity,
            notes: notes,
            refereeName: refereeName,
            deviceId: deviceId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            version: version,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sku,
            required String teamNumber,
            Value<String?> matchId = const Value.absent(),
            required String ruleCodesJson,
            required String severity,
            required String notes,
            required String refereeName,
            required String deviceId,
            required int createdAt,
            required int updatedAt,
            Value<bool> isDeleted = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IncidentNotesCompanion.insert(
            id: id,
            sku: sku,
            teamNumber: teamNumber,
            matchId: matchId,
            ruleCodesJson: ruleCodesJson,
            severity: severity,
            notes: notes,
            refereeName: refereeName,
            deviceId: deviceId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isDeleted: isDeleted,
            version: version,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IncidentNotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $IncidentNotesTable,
    IncidentNote,
    $$IncidentNotesTableFilterComposer,
    $$IncidentNotesTableOrderingComposer,
    $$IncidentNotesTableAnnotationComposer,
    $$IncidentNotesTableCreateCompanionBuilder,
    $$IncidentNotesTableUpdateCompanionBuilder,
    (
      IncidentNote,
      BaseReferences<_$AppDatabase, $IncidentNotesTable, IncidentNote>
    ),
    IncidentNote,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db, _db.teams);
  $$MatchesTableTableManager get matches =>
      $$MatchesTableTableManager(_db, _db.matches);
  $$IncidentNotesTableTableManager get incidentNotes =>
      $$IncidentNotesTableTableManager(_db, _db.incidentNotes);
}
