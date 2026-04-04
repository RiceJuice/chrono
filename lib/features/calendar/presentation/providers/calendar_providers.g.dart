// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SelectedDay)
final selectedDayProvider = SelectedDayProvider._();

final class SelectedDayProvider
    extends $NotifierProvider<SelectedDay, DateTime> {
  SelectedDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDayHash();

  @$internal
  @override
  SelectedDay create() => SelectedDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedDayHash() => r'7646bc9f7552998a989e316eb00d2b96baaf8238';

abstract class _$SelectedDay extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FocusedDay)
final focusedDayProvider = FocusedDayProvider._();

final class FocusedDayProvider extends $NotifierProvider<FocusedDay, DateTime> {
  FocusedDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusedDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusedDayHash();

  @$internal
  @override
  FocusedDay create() => FocusedDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$focusedDayHash() => r'690e060784d52ac2eda5c0579f4fde7079b0d54e';

abstract class _$FocusedDay extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(calendarRepository)
final calendarRepositoryProvider = CalendarRepositoryProvider._();

final class CalendarRepositoryProvider
    extends
        $FunctionalProvider<
          CalendarRepository,
          CalendarRepository,
          CalendarRepository
        >
    with $Provider<CalendarRepository> {
  CalendarRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarRepositoryHash();

  @$internal
  @override
  $ProviderElement<CalendarRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalendarRepository create(Ref ref) {
    return calendarRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarRepository>(value),
    );
  }
}

String _$calendarRepositoryHash() =>
    r'b4ae9598806ae6fdab651962806f5c1dabc9f233';

@ProviderFor(CalendarEntries)
final calendarEntriesProvider = CalendarEntriesProvider._();

final class CalendarEntriesProvider
    extends $StreamNotifierProvider<CalendarEntries, List<CalendarEntry>> {
  CalendarEntriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarEntriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarEntriesHash();

  @$internal
  @override
  CalendarEntries create() => CalendarEntries();
}

String _$calendarEntriesHash() => r'7b703cf6637ab766cd6cfff317413a8a2f44e05c';

abstract class _$CalendarEntries extends $StreamNotifier<List<CalendarEntry>> {
  Stream<List<CalendarEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CalendarEntry>>, List<CalendarEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CalendarEntry>>, List<CalendarEntry>>,
              AsyncValue<List<CalendarEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CalendarEntriesForDay)
final calendarEntriesForDayProvider = CalendarEntriesForDayFamily._();

final class CalendarEntriesForDayProvider
    extends
        $StreamNotifierProvider<CalendarEntriesForDay, List<CalendarEntry>> {
  CalendarEntriesForDayProvider._({
    required CalendarEntriesForDayFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calendarEntriesForDayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarEntriesForDayHash();

  @override
  String toString() {
    return r'calendarEntriesForDayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CalendarEntriesForDay create() => CalendarEntriesForDay();

  @override
  bool operator ==(Object other) {
    return other is CalendarEntriesForDayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarEntriesForDayHash() =>
    r'ebb8dc0babe1c1083cacbd2bb672753ad0fed80e';

final class CalendarEntriesForDayFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarEntriesForDay,
          AsyncValue<List<CalendarEntry>>,
          List<CalendarEntry>,
          Stream<List<CalendarEntry>>,
          DateTime
        > {
  CalendarEntriesForDayFamily._()
    : super(
        retry: null,
        name: r'calendarEntriesForDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CalendarEntriesForDayProvider call(DateTime day) =>
      CalendarEntriesForDayProvider._(argument: day, from: this);

  @override
  String toString() => r'calendarEntriesForDayProvider';
}

abstract class _$CalendarEntriesForDay
    extends $StreamNotifier<List<CalendarEntry>> {
  late final _$args = ref.$arg as DateTime;
  DateTime get day => _$args;

  Stream<List<CalendarEntry>> build(DateTime day);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CalendarEntry>>, List<CalendarEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CalendarEntry>>, List<CalendarEntry>>,
              AsyncValue<List<CalendarEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
