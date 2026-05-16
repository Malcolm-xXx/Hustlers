import 'package:flutter_riverpod/flutter_riverpod.dart';

final productQuantityProvider =
    StateProvider.family<int, String>((ref, productId) => 1);
