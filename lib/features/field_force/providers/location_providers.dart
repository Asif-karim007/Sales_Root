import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:salesroot/features/field_force/service/location_source.dart';

part 'location_providers.g.dart';

@Riverpod(keepAlive: true)
LocationSource locationSource(Ref ref) => DeviceLocationSource();
