// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library ace_module;

import '../core/modules.dart';
import '../core/dependencies.dart';
import '../editing/editor_ace.dart';

class AceModule extends Module {
  Future init() {
    deps[EditorFactory] = aceFactory;

    if (!aceFactory.inited) {
      return aceFactory.init();
    } else {
      return new Future.value();
    }
  }
}
