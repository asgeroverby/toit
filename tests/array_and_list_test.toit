// Copyright (C) 2018 Toitware ApS.
// Use of this source code is governed by a Zero-Clause BSD license that can
// be found in the tests/LICENSE file.

import expect show *

main:
  test_byte_array
  test_array
  test_large_array_do
  test_matrix
  test_join

test_join:
  a := []
  expect_equals "" (a.join "")
  expect_equals "" (a.join "foo")
  a = ["foo"]
  expect_equals "foo" (a.join "")
  expect_equals "foo" (a.join "bar")
  a = ["foo", "bar"]
  expect_equals "foobar" (a.join "")
  expect_equals "foo,bar" (a.join ",")
  expect_equals "foo, bar" (a.join ", ")
  a = ["foo", "bar", "baz"]
  expect_equals "foobarbaz" (a.join "")
  expect_equals "foo,bar,baz" (a.join ",")
  expect_equals "foo, bar, baz" (a.join ", ")

  a = ["123", "1.25", "hello"]
  expect_equals "123, 1.25, hello" (a.join ", ")

  a = []
  star_block := : "*$it.stringify*"
  expect_equals "" (a.join "" star_block)
  expect_equals "" (a.join "foo" star_block)
  a = ["foo"]
  expect_equals "*foo*" (a.join "" star_block)
  expect_equals "*foo*" (a.join "bar" star_block)
  a = ["foo", "bar"]
  expect_equals "*foo**bar*" (a.join "" star_block)
  expect_equals "*foo*,*bar*" (a.join "," star_block)
  expect_equals "*foo*, *bar*" (a.join ", " star_block)
  a = ["foo", "bar", "baz"]
  expect_equals "*foo**bar**baz*" (a.join "" star_block)
  expect_equals "*foo*,*bar*,*baz*" (a.join "," star_block)
  expect_equals "*foo*, *bar*, *baz*" (a.join ", " star_block)

  a = ["123", "1.25", "hello"]
  expect_equals "*123*, *1.25*, *hello*" (a.join ", " star_block)

test_byte_array:
  a := ByteArray 10
  expect a.size == 10

  i := 0
  while i < a.size:
    a[i] = i * 2
    i++

  expect_equals (5 * 2) a[5]
  expect_equals (6 * 2) a[6]

  i = 0
  while i < a.size:
    a[i] = a[i] * 2
    i++

  expect_equals (6 * 2 * 2) a[6]
  expect_equals (7 * 2 * 2) a[7]

  bytes := ByteArray 3: it + 1
  expect_equals "#[0x01, 0x02, 0x03]" bytes.stringify
  bytes = ByteArray 51: it
  expected := "#["
      + "0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, "
      + "0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, "
      + "0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, "
      + "0x30, 0x31, ...]"
  expect_equals expected bytes.stringify

  bytes = #['a', 'b', 'c']
  expect bytes.is_valid_string_content
  expect (bytes.is_valid_string_content 1)
  expect (bytes.is_valid_string_content 2 3)
  bytes[1] = 0b1110_0000
  expect_not bytes.is_valid_string_content
  expect (bytes.is_valid_string_content 0 1)
  expect (bytes.is_valid_string_content 2 3)
  bytes[2] = 0b1110_0000
  expect_not bytes.is_valid_string_content
  expect (bytes.is_valid_string_content 0 1)
  expect_not (bytes.is_valid_string_content 2 3)

  // Must be long enough to be a CoW byte array.
  illegal := #[0xff, 'a', 0xff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
  expect_not illegal.is_valid_string_content
  expect (illegal.is_valid_string_content 1 2)
  expect_not (illegal.is_valid_string_content 2 3)

test_array:
  a := Array_ 10
  expect a.size == 10

  i := 0
  while i < a.size:
    a[i] = i * 2
    i++

  expect_equals (5 * 2) a[5]
  expect_equals (6 * 2) a[6]

  i = 0
  while i < a.size:
    a[i] = a[i] * 2
    i++

  expect_equals (6 * 2 * 2) a[6]
  expect_equals (7 * 2 * 2) a[7]

  a.size.repeat:
    a[it] = 100 - it

  sorted := a.sort
  expect (not a.is_sorted)
  expect sorted.is_sorted

ARRAYLET_SIZE ::= LargeArray_.ARRAYLET_SIZE
FILLER := 3.1415


test_large_array_do:
 10.repeat:
  sizes := [ 0, 1, 499, 500, 501, 999, 1000, 1001, 9999, 10000, 10001 ]
  sizes.do: | size |
    sizes.do: | new_size |
      sizes.do: | copy_size |
        array := Array_ size
        expect_equals
            size <= ARRAYLET_SIZE
            array is SmallArray_

        count := 0
        array.do: count++
        expect_equals size count

        // Fill with non-null values.
        array.size.repeat: array[it] = it

        sum := 0
        array.do:
          expect_equals it array[it]
          sum += it
        expect_equals
            (array.size * (array.size - 1)) / 2
            sum

        if copy_size <= size:
          copy := array.resize_for_list_ copy_size new_size FILLER

          expect_equals new_size copy.size

          expect_equals
              new_size <= ARRAYLET_SIZE
              copy is SmallArray_

          // Verify that the arraylets were reused.
          if array is LargeArray_ and copy is LargeArray_:
            (min (size / ARRAYLET_SIZE) (new_size / ARRAYLET_SIZE)).repeat:
              expect
                  identical
                      (array as LargeArray_).vector_[it]
                      (copy as LargeArray_).vector_[it]
          // Verify that values were copied.
          copy_edge := min size (min new_size copy_size)
          for i := 0; i < copy_edge; i++:
            expect_equals i copy[i]
          // Verify filler was used.
          for i := copy_edge; i < new_size; i++:
            expect_equals FILLER copy[i]

test_matrix:
  matrix := Matrix
  matrix[0, 0] = 00
  matrix[0, 1] = 01
  matrix[1, 0] = 10
  matrix[1, 1] = 11
  expect matrix[0, 0] == 00
  expect matrix[0, 1] == 01
  expect matrix[1, 0] == 10
  expect matrix[1, 1] == 11

  a := [ ]
  expect_equals 0 a.size

  a = [ 2, 3 ]
  expect_equals 2 a.size
  expect_equals 2 a[0]
  expect_equals 3 a[1]

  a = [ 3, 4, ]
  expect_equals 2 a.size
  expect_equals 3 a[0]
  expect_equals 4 a[1]

  expect [1,2] == [1,2]
  expect_equals
      6
      [1, 2, 3].reduce --initial=0: | sum e | sum + e

class Matrix:
  data := List 4
  operator [] x y:
    return data[x * 2 + y]
  operator []= x y v:
    return data[x * 2 + y] = v
