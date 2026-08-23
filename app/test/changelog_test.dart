import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Check changelog asset loading', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final list = manifest.listAssets();
    print('Available assets: $list');
  });
}
