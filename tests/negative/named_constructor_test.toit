// Copyright (C) 2018 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/LICENSE file.

import .named_constructor_test as self

class A:
  constructor.foo:


main:
  a := A  // There should not be an implicit constructor.
  b := A.some_non_existing_static
  c := self.A.some_non_existing_static
