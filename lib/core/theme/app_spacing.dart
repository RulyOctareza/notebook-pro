import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class AppRadii {
  static const double sm = 6;
  static const double md = 10;
  static const double pill = 14;
}

abstract final class AppLayout {
  static const double folderSidebarWidth = 200;
  static const double folderMin = 140;
  static const double folderMax = 480;
  static const double noteListWidth = 280;
  static const double noteListMin = 180;
  static const double noteListMax = 640;
  /// Keep at least this much room for the editor pane while resizing.
  static const double editorMin = 280;
  /// Comfortable centered reading measure (iA Writer / Notes-style).
  static const double editorMaxContent = 680;
  static const double toolbarHeight = 44;
  static const double listHeaderHeight = 48;
  static const Size windowMin = Size(800, 560);
}
