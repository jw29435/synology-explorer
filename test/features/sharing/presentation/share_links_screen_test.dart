import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synology_explorer/features/sharing/data/sharing_api.dart';
import 'package:synology_explorer/features/sharing/domain/share_link.dart';
import 'package:synology_explorer/features/sharing/presentation/sharing_providers.dart';

import '../../../helpers/app_harness.dart';

class _ListSharingApi implements SharingApi {
  _ListSharingApi(this.links);

  final List<ShareLink> links;
  final deleted = <List<String>>[];

  @override
  Future<List<ShareLink>> list() async => links;

  @override
  Future<void> delete(List<String> ids) async {
    deleted.add(ids);
    links.removeWhere((l) => ids.contains(l.id));
  }

  @override
  Future<List<ShareLink>> create(
    List<String> paths, {
    String? password,
    DateTime? expiresAt,
  }) => throw UnimplementedError();
}

ShareLink _link(String id, String name, {DateTime? expiresAt}) => ShareLink(
  id: id,
  url: 'https://nas/sharing/$id',
  name: name,
  path: '/music/$name',
  isFolder: false,
  hasPassword: false,
  expiresAt: expiresAt,
);

void main() {
  testWidgets('23: Löschen und Aufräumen erst nach Bestätigung (E2E-035)', (
    tester,
  ) async {
    final api = _ListSharingApi([
      _link('a', 'booklet.pdf'),
      _link('b', 'alt.mp3', expiresAt: DateTime(2020)),
      _link('c', 'uralt.mp3', expiresAt: DateTime(2019)),
    ]);
    await pumpApp(
      tester,
      location: '/settings/shares',
      overrides: [sharingApiProvider.overrideWithValue(api)],
    );
    expect(find.text('booklet.pdf'), findsOne);
    // Links landen in keinem Papierkorb (E2E-062).
    expect(find.byTooltip('Löschen (in Papierkorb)'), findsNothing);

    // Abbrechen löscht nichts.
    await tester.tap(find.byTooltip('Löschen'));
    await tester.pumpAndSettle();
    expect(find.text('Freigabelink für „booklet.pdf“ löschen?'), findsOne);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(api.deleted, isEmpty);

    await tester.tap(find.byTooltip('Löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pumpAndSettle();
    expect(api.deleted, [
      ['a'],
    ]);
    expect(find.text('booklet.pdf'), findsNothing);

    await tester.tap(find.text('Aufräumen'));
    await tester.pumpAndSettle();
    expect(find.text('2 abgelaufene Links löschen?'), findsOne);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(api.deleted, hasLength(1));

    await tester.tap(find.text('Aufräumen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Löschen'));
    await tester.pumpAndSettle();
    expect(api.deleted.last, ['b', 'c']);
    expect(find.text('Keine Freigabelinks.'), findsOne);
  });
}
