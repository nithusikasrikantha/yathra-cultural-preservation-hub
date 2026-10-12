import 'package:flutter/foundation.dart';

abstract final class PublishedContentSignal {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static void notify() => revision.value++;
}
