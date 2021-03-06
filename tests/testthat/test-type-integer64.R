context("test-type-integer64")

test_that("casting of integer64 works", {
  x <- bit64::as.integer64(1:10)
  expect_equal(vec_cast(x, bit64::integer64()), x)

  expect_equal(vec_cast(x, integer()), 1:10)
  expect_equal(vec_cast(1:10, bit64::integer64()), x)

  expect_equal(vec_cast(x, double()), as.double(x))
  expect_equal(vec_cast(as.numeric(1:10), bit64::integer64()), x)

  expect_equal(vec_cast(x, character()), as.character(x))
  expect_equal(vec_cast(as.character(1:10), bit64::integer64()), x)

  expect_equal(vec_cast(x, logical()), rep(TRUE, 10L))
  expect_equal(vec_cast(c(TRUE, FALSE), bit64::integer64()), bit64::as.integer64(c(1, 0)))

  expect_equal(vec_cast(NA, bit64::integer64()), bit64::as.integer64(NA))

  expect_error(vec_cast(x, factor()))
  expect_error(vec_cast(factor(), x))
  expect_error(vec_cast(unspecified(), x))
  expect_error(vec_cast(x, unspecified()))
})

test_that("vec_type2 for integer64 works", {
  x <- bit64::as.integer64(1:10)
  expect_equal(vec_type2(x, x), bit64::integer64())

  expect_equal(vec_type2(x, 1L), bit64::integer64())
  expect_equal(vec_type2(1L, x), bit64::integer64())

  expect_equal(vec_type2(x, TRUE), bit64::integer64())
  expect_equal(vec_type2(TRUE, x), bit64::integer64())

  expect_equal(vec_type2(x, NA), bit64::integer64())
  expect_equal(vec_type2(NA, x), bit64::integer64())

  expect_equal(vec_type2(unspecified(), x), bit64::integer64())
  expect_equal(vec_type2(x, unspecified()), bit64::integer64())

  expect_error(vec_type2(x, 1))
  expect_error(vec_type2(1, x))

  expect_error(vec_type2(x, ""))
  expect_error(vec_type2("", x))

  expect_error(vec_type2(data.frame(), x))
  expect_error(vec_type2(x, data.frame()))
})

test_that("vec_ptype_abbr.integer64", {
  expect_equal(vec_ptype_abbr(bit64::as.integer64(1:10)), "int64")
  expect_equal(vec_ptype_full(bit64::as.integer64(1:10)), "integer64")
})
