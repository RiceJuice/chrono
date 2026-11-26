import 'dart:typed_data';

import 'package:chronoapp/core/widgets/app_modal_sheet.dart';
import 'package:chronoapp/features/settings/data/models/profile_avatar.dart';
import 'package:chronoapp/features/settings/data/models/profile_snapshot.dart';
import 'package:chronoapp/features/settings/data/profile_avatar_repository.dart';
import 'package:chronoapp/features/settings/presentation/providers/profile_avatar_provider.dart';
import 'package:chronoapp/features/settings/presentation/widgets/profile_avatar.dart';
import 'package:chronoapp/features/settings/presentation/widgets/profile_avatar_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

const profile = ProfileSnapshot(
  firstName: 'Anna',
  lastName: 'Muster',
  className: null,
  schoolTrack: null,
  voice: null,
  role: null,
  choir: null,
  diet: null,
);

class RecordingAvatarRepository implements ProfileAvatarRepository {
  @override
  SupabaseClient get client => throw UnimplementedError();

  @override
  Stream<ProfileAvatar> watch() => Stream.value(const ProfileAvatar());

  @override
  Future<Uint8List?> download(String? path) async => null;
  int calls = 0;
  int? savedColor;
  bool? savedUsePhoto;
  bool fail = false;

  @override
  Future<void> save({
    required int? color,
    Uint8List? photo,
    required bool usePhoto,
  }) async {
    calls++;
    if (fail) throw StateError('offline');
    savedColor = color;
    savedUsePhoto = usePhoto;
  }
}

Future<void> openEditor(
  WidgetTester tester,
  RecordingAvatarRepository repository, {
  ProfileAvatar initial = const ProfileAvatar(),
  Uint8List? photo,
  Brightness brightness = Brightness.light,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileAvatarRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppModalSheet.show<void>(
                context: context,
                builder: (_) => ProfileAvatarEditor(
                  profile: profile,
                  initial: initial,
                  initialPhoto: photo,
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('initials editor fits a small screen with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openEditor(tester, RecordingAvatarRepository());
    expect(find.text('Hintergrundfarbe'), findsOneWidget);
  });

  test('malformed metadata falls back to initials and theme color', () {
    final avatar = ProfileAvatar.fromMetadata({
      'chrono_avatar': {'path': 7, 'color': -1},
    });
    expect(avatar.path, isNull);
    expect(avatar.color, isNull);
    expect(
      ProfileAvatar.fromMetadata({'chrono_avatar': 'invalid'}).path,
      isNull,
    );
  });

  test('normalizes a photo and removes EXIF metadata', () {
    final source = img.Image(width: 120, height: 80);
    img.fill(source, color: img.ColorRgb8(220, 30, 40));
    source.exif.imageIfd.orientation = 6;
    source.exif.imageIfd.make = 'Private camera metadata';
    final result = prepareProfilePhoto(
      Uint8List.fromList(img.encodeJpg(source)),
    );
    final decoded = img.decodeJpg(result)!;
    expect(decoded.width, 512);
    expect(decoded.height, 512);
    expect(decoded.exif.imageIfd.make, isNull);
    expect(decoded.exif.imageIfd.orientation, isNull);
    expect(decoded.getPixel(256, 256).r, greaterThan(200));
    expect(result.length, lessThan(2 * 1024 * 1024));
  });

  test('rejects invalid and oversized photos', () {
    expect(
      () => prepareProfilePhoto(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
    expect(
      () => prepareProfilePhoto(Uint8List(20 * 1024 * 1024 + 1)),
      throwsFormatException,
    );
  });

  testWidgets('color preview stays local until Done', (tester) async {
    final repository = RecordingAvatarRepository();
    await openEditor(tester, repository);
    await tester.tap(find.byTooltip('Grün'));
    await tester.pumpAndSettle();
    final preview = tester.widget<ProfileAvatarView>(
      find.byType(ProfileAvatarView).first,
    );
    expect(preview.color, 0xff43846b);
    expect(repository.calls, 0);
    await tester.tap(find.byTooltip('Fertig'));
    await tester.pumpAndSettle();
    expect(repository.savedColor, 0xff43846b);
    expect(repository.savedUsePhoto, isFalse);
    expect(find.byType(ProfileAvatarEditor), findsNothing);
  });

  testWidgets('Cancel discards color changes', (tester) async {
    final repository = RecordingAvatarRepository();
    await openEditor(tester, repository);
    await tester.tap(find.byTooltip('Rosa'));
    await tester.tap(find.byTooltip('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repository.calls, 0);
    expect(find.byType(ProfileAvatarEditor), findsNothing);
  });

  testWidgets('switching from photo to initials removes photo on save', (
    tester,
  ) async {
    final repository = RecordingAvatarRepository();
    final photo = Uint8List.fromList(
      img.encodePng(img.Image(width: 8, height: 8)),
    );
    await openEditor(
      tester,
      repository,
      initial: const ProfileAvatar(path: 'user/photo.jpg', color: 0xff43846b),
      photo: photo,
    );
    await tester.tap(find.byTooltip('Initialen'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProfileAvatarView>(find.byType(ProfileAvatarView).first)
          .photo,
      isNull,
    );
    await tester.tap(find.byTooltip('Fertig'));
    await tester.pumpAndSettle();
    expect(repository.savedUsePhoto, isFalse);
    expect(repository.savedColor, 0xff43846b);
  });

  testWidgets('visual choices retain the photo when switching back', (
    tester,
  ) async {
    final repository = RecordingAvatarRepository();
    final photo = Uint8List.fromList(
      img.encodePng(img.Image(width: 8, height: 8)),
    );
    await openEditor(
      tester,
      repository,
      initial: const ProfileAvatar(path: 'user/photo.jpg'),
      photo: photo,
    );
    expect(find.text('Initialen'), findsNothing);
    expect(find.text('Foto'), findsNothing);
    await tester.tap(find.byTooltip('Initialen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Foto'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProfileAvatarView>(find.byType(ProfileAvatarView).first)
          .photo,
      same(photo),
    );
    expect(repository.calls, 0);
    await tester.tap(find.byTooltip('Fertig'));
    await tester.pumpAndSettle();
    expect(repository.savedUsePhoto, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed saves retain selection and allow retry in dark mode', (
    tester,
  ) async {
    final repository = RecordingAvatarRepository()..fail = true;
    await openEditor(tester, repository, brightness: Brightness.dark);
    await tester.tap(find.byTooltip('Indigo'));
    await tester.tap(find.byTooltip('Fertig'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verbindung prüfen'), findsOneWidget);
    expect(
      tester
          .widget<ProfileAvatarView>(find.byType(ProfileAvatarView).first)
          .color,
      0xff5856a8,
    );
    repository.fail = false;
    await tester.tap(find.byTooltip('Fertig'));
    await tester.pumpAndSettle();
    expect(repository.savedColor, 0xff5856a8);
    expect(repository.calls, 2);
    expect(tester.takeException(), isNull);
  });
}
