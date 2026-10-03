import 'package:salesroot/core/access/app_module.dart';
import 'package:salesroot/core/access/module_access.dart';
import 'package:salesroot/core/fake/fake_backend.dart';
import 'package:salesroot/core/fake/fake_store.dart';
import 'package:salesroot/core/network/api_failure.dart';
import 'package:salesroot/core/utils/json_fields.dart';
import 'package:salesroot/features/growth/data/lead_sources_fixtures.dart';
import 'package:salesroot/features/growth/data/lead_sources_repository.dart';
import 'package:salesroot/features/growth/models/lead_channel.dart';

class FakeLeadSourcesRepository implements LeadSourcesRepository {
  FakeLeadSourcesRepository(this._backend);

  final FakeBackend _backend;

  /// The channel catalogue exists in every workspace; a new one has
  /// nothing connected yet.
  FakeTable get _channels => _catalogue(
    _backend.table(growthChannelsTable, channelFixtures),
    () => [
      for (final row in channelFixtures(_backend.graph))
        {
          'Id': row['Id'],
          'Kind': row['Kind'],
          'Status': row['Status'] == ChannelStatus.soon.wire
              ? ChannelStatus.soon.wire
              : ChannelStatus.available.wire,
          'Account': row['Account'],
          'EmbedCode': row['EmbedCode'],
          'ShareUrl': row['ShareUrl'],
        },
    ],
  );

  FakeTable get _setup =>
      _backend.table(growthFacebookTable, facebookSetupFixtures);

  /// Pages and forms live on Meta's side, so they exist even in a new
  /// workspace.
  FakeTable get _pages => _catalogue(
    _backend.table(growthFacebookPagesTable, facebookPageFixtures),
    () => facebookPageFixtures(_backend.graph),
  );

  FakeTable get _forms => _catalogue(
    _backend.table(growthFacebookFormsTable, facebookFormFixtures),
    () => [
      for (final row in facebookFormFixtures(_backend.graph))
        {...row, 'Enabled': false},
    ],
  );

  FakeTable _catalogue(
    FakeTable table,
    List<Map<String, dynamic>> Function() seed,
  ) {
    if (table.rows.isEmpty) table.replaceAll(seed());
    return table;
  }

  @override
  Future<List<LeadChannel>> channels() => _backend.run(
    'Lead channels',
    () => [for (final row in _channels.rows) LeadChannel.fromJson(row)],
    module: AppModule.leadSources,
  );

  @override
  Future<LeadChannel> connect(int channelId) => _backend.run(
    'Lead channel connect',
    () {
      final row = _channels.byId(channelId);
      if (row['Status'] == ChannelStatus.soon.wire) {
        throw const ApiFailure(400, 'This channel is not available yet');
      }
      return LeadChannel.fromJson(
        _channels.update(channelId, {'Status': ChannelStatus.connected.wire}),
      );
    },
    module: AppModule.leadSources,
    right: ModuleRight.edit,
  );

  @override
  Future<LeadChannel> disconnect(int channelId) => _backend.run(
    'Lead channel disconnect',
    () {
      final row = _channels.byId(channelId);
      if (row['Kind'] == ChannelKind.facebook.wire) {
        _updateSetup({'PageId': null});
        for (final form in _forms.rows) {
          _forms.update(jsonInt(form['Id']) ?? 0, {'Enabled': false});
        }
      }
      return LeadChannel.fromJson(
        _channels.update(channelId, {
          'Status': ChannelStatus.available.wire,
          'FormCount': 0,
        }),
      );
    },
    module: AppModule.leadSources,
    right: ModuleRight.edit,
  );

  @override
  Future<FacebookSetup> facebook() =>
      _backend.run('Facebook setup', _setupJson, module: AppModule.leadSources);

  @override
  Future<List<FacebookPage>> facebookPages() => _backend.run(
    'Facebook pages',
    () => [for (final row in _pages.rows) FacebookPage.fromJson(row)],
    module: AppModule.leadSources,
    right: ModuleRight.edit,
  );

  @override
  Future<List<LeadForm>> facebookForms(int pageId) => _backend.run(
    'Facebook forms',
    () {
      _pages.byId(pageId);
      return [
        for (final row in _forms.rows)
          if (row['PageId'] == pageId) LeadForm.fromJson(row),
      ];
    },
    module: AppModule.leadSources,
    right: ModuleRight.edit,
  );

  @override
  Future<FacebookSetup> saveFacebook(FacebookSetupInput input) => _backend.run(
    'Facebook save',
    () {
      final page = _pages.byId(input.pageId);
      if (input.formIds.isEmpty) {
        throw const ApiFailure(
          400,
          'Turn on at least one lead form',
          fieldErrors: {'FormIds': 'Turn on at least one lead form'},
        );
      }
      if (!input.mappings.any((m) => m.target == LeadField.mobile)) {
        throw const ApiFailure(
          400,
          'Map one question to Mobile',
          fieldErrors: {'Mappings': 'Map one question to Mobile'},
        );
      }
      var leads = 0;
      for (final form in _forms.rows) {
        if (form['PageId'] != input.pageId) continue;
        final id = jsonInt(form['Id']) ?? 0;
        final on = input.formIds.contains(id);
        if (on) leads += jsonInt(form['LeadCount']) ?? 0;
        _forms.update(id, {'Enabled': on});
      }
      _updateSetup(input.toJson());
      for (final channel in _channels.rows) {
        final kind = channel['Kind'];
        if (kind != ChannelKind.facebook.wire &&
            kind != ChannelKind.messenger.wire) {
          continue;
        }
        final isPage = kind == ChannelKind.facebook.wire;
        _channels.update(jsonInt(channel['Id']) ?? 0, {
          'Status': ChannelStatus.connected.wire,
          'Account': page['Name'],
          if (isPage) 'FormCount': input.formIds.length,
          if (isPage) 'LeadCount': leads,
        });
      }
      return _setupJson();
    },
    module: AppModule.leadSources,
    right: ModuleRight.edit,
  );

  void _updateSetup(Map<String, dynamic> patch) {
    if (_setup.rows.isEmpty) {
      _setup.insert({'Id': 1, ...patch});
    } else {
      _setup.update(1, patch);
    }
  }

  FacebookSetup _setupJson() {
    final setup = _setup.rows.isEmpty
        ? const <String, dynamic>{}
        : _setup.rows.first;
    final pageId = jsonInt(setup['PageId']);
    final page = pageId == null ? null : _pages.byIdOrNull(pageId);
    return FacebookSetup.fromJson({
      ...setup,
      'Page': page,
      'Forms': [
        if (page != null)
          for (final row in _forms.rows)
            if (row['PageId'] == pageId) row,
      ],
    });
  }
}
