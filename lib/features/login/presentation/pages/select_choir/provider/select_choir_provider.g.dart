// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'select_choir_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedChoir)
final selectedChoirProvider = SelectedChoirProvider._();

final class SelectedChoirProvider
    extends $NotifierProvider<SelectedChoir, String?> {
  SelectedChoirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedChoirProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedChoirHash();

  @$internal
  @override
  SelectedChoir create() => SelectedChoir();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedChoirHash() => r'e652886843f6fd4f398bd94d6dc5a85933edd459';

abstract class _$SelectedChoir extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
