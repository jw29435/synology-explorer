import 'package:flutter/widgets.dart';

/// Ankerrechteck des auslösenden Widgets für `ShareParams.sharePositionOrigin`
/// – auf dem iPad braucht das Share-Popover einen Ursprung.
Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}
