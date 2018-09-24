context("test-type-date-time")

test_that("date-times have informative types", {
  expect_equal(vec_ptype_abbr(Sys.Date()), "date")
  expect_equal(vec_ptype_full(Sys.Date()), "date")

  expect_equal(vec_ptype_abbr(Sys.time()), "dttm")
  expect_equal(vec_ptype_full(Sys.time()), "datetime<local>")

  expect_equal(vec_ptype_abbr(new_duration(10)), "drtn")
  expect_equal(vec_ptype_full(new_duration(10)), "duration<secs>")
})


# coerce ------------------------------------------------------------------

test_that("tz comes from first non-empty", {
  # On the assumption that if you've set the time zone explicitly it
  # should win

  x <- as.POSIXct("2020-01-01")
  y <- as.POSIXct("2020-01-01", tz = "America/New_York")

  expect_equal(vec_type2(x, y), y[0])
  expect_equal(vec_type2(y, x), y[0])

  z <- as.POSIXct("2020-01-01", tz = "Pacific/Auckland")
  expect_equal(vec_type2(y, z), y[0])
  expect_equal(vec_type2(z, y), z[0])
})


# cast: dates ---------------------------------------------------------------

test_that("safe casts work as expected", {
  date <- as.Date("2018-01-01")

  expect_equal(vec_cast(NULL, date), NULL)
  expect_equal(vec_cast(17532, date), date)
  expect_equal(vec_cast("2018-01-01", date), date)
  expect_equal(vec_cast(date, date), date)
  expect_equal(vec_cast(as.POSIXct(date), date), date)
  expect_equal(vec_cast(list(date), date), date)
})

test_that("lossy casts generate warning", {
  date <- as.Date("2018-01-01")
  datetime <- as.POSIXct(date) + 3600

  expect_condition(vec_cast(datetime, date), class = "warning_lossy_cast")
})

test_that("invalid casts generate error", {
  date <- as.Date("2018-01-01")
  expect_error(vec_cast(integer(), date), class = "error_incompatible_cast")
})


# cast: datetimes -----------------------------------------------------------

test_that("safe casts work as expected", {
  datetime <- as.POSIXct("1970-02-01", tz = "UTC")

  expect_equal(vec_cast(NULL, datetime), NULL)
  expect_equal(vec_cast(2678400, datetime), datetime)
  expect_equal(vec_cast("1970-02-01", datetime), datetime)
  expect_equal(vec_cast(datetime, datetime), datetime)
  expect_equal(vec_cast(as.Date(datetime), datetime), datetime)
  expect_equal(vec_cast(list(datetime), datetime), datetime)
})

test_that("invalid casts generate error", {
  datetime <- as.POSIXct("1970-02-01", tz = "UTC")
  expect_error(vec_cast(integer(), datetime), class = "error_incompatible_cast")
})

test_that("dates become midnight in date-time tzone", {
  date1 <- as.Date("2010-01-01")
  datetime <- as.POSIXct(character(), tz = "Pacific/Auckland")

  date2 <- vec_cast(date1, datetime)
  expect_equal(attr(date2, "tzone"), "Pacific/Auckland")
  expect_equal(format(date2, "%H:%M"), "00:00")
})

# cast: durations ------------------------------------------------------------

test_that("safe casts work as expected", {
  dt1 <- as.difftime(600, units = "secs")
  dt2 <- as.difftime(10, units = "mins")

  expect_equal(vec_cast(NULL, dt1), NULL)
  expect_equal(vec_cast(600, dt1), dt1)
  expect_equal(vec_cast(dt1, dt1), dt1)
  expect_equal(vec_cast(dt1, dt2), dt2)
  expect_equal(vec_cast(list(dt1), dt1), dt1)
})

test_that("invalid casts generate error", {
  dt <- as.difftime(600, units = "secs")
  expect_error(vec_cast(integer(), dt), class = "error_incompatible_cast")
})


# arithmetic --------------------------------------------------------------

test_that("default is error", {
  d <- as.Date("2018-01-01")
  dt <- as.POSIXct("2018-01-02 12:00")
  t <- as.difftime(12, units = "hours")
  f <- factor("x")

  expect_error(vec_arith("+", d, f), class = "error_incompatible_op")
  expect_error(vec_arith("+", dt, f), class = "error_incompatible_op")
  expect_error(vec_arith("+", t, f), class = "error_incompatible_op")
})

test_that("date-time vs date-time", {
  d <- as.Date("2018-01-01")
  dt <- as.POSIXct(d)

  expect_error(vec_arith("+", d, d), class = "error_incompatible_op")
  expect_equal(vec_arith("-", d, d), d - d)

  expect_error(vec_arith("+", d, dt), class = "error_incompatible_op")
  expect_equal(vec_arith("-", d, dt), difftime(d, dt))

  expect_error(vec_arith("+", dt, d), class = "error_incompatible_op")
  expect_equal(vec_arith("-", dt, d), difftime(dt, d))

  expect_error(vec_arith("+", dt, dt), class = "error_incompatible_op")
  expect_equal(vec_arith("-", dt, dt), dt - dt)
})

test_that("date-time vs numeric", {
   d <- as.Date("2018-01-01")
   dt <- as.POSIXct(d)

   expect_equal(vec_arith("+", d, 1), d + 1)
   expect_equal(vec_arith("+", 1, d), d + 1)
   expect_equal(vec_arith("-", d, 1), d - 1)
   expect_error(vec_arith("-", 1, d), class = "error_incompatible_op")

   expect_error(vec_arith("*", 1, d), class = "error_incompatible_op")
   expect_error(vec_arith("*", d, 1), class = "error_incompatible_op")
})

test_that("date-time vs difftime", {
  d <- as.Date("2018-01-01")
  dt <- as.POSIXct(d)
  t <- as.difftime(1, units = "days")

  expect_equal(vec_arith("+", dt, t), dt + t)
  expect_equal(vec_arith("+", d, t), d + t)
  expect_equal(vec_arith("-", dt, t), dt - t)
  expect_equal(vec_arith("-", d, t), d - t)

  expect_equal(vec_arith("+", t, dt), dt + t)
  expect_equal(vec_arith("+", t, d), d + t)
  expect_error(vec_arith("-", t, dt), class = "error_incompatible_op")
  expect_error(vec_arith("-", t, d), class = "error_incompatible_op")
})

test_that("difftime vs difftime/numeric", {
  t <- as.difftime(12, units = "hours")

  expect_equal(vec_arith("-", t, MISSING()), -t)
  expect_equal(vec_arith("+", t, MISSING()), t)

  expect_equal(vec_arith("-", t, t), t - t)
  expect_equal(vec_arith("-", t, 1), t - 1)
  expect_equal(vec_arith("-", 1, t), 1 - t)

  expect_equal(vec_arith("+", t, t), 2 * t)
  expect_equal(vec_arith("+", t, 1), t + 1)
  expect_equal(vec_arith("+", 1, t), t + 1)

  expect_equal(vec_arith("*", 2, t), 2 * t)
  expect_equal(vec_arith("*", t, 2), 2 * t)
  expect_error(vec_arith("*", t, t), class = "error_incompatible_op")

  expect_equal(vec_arith("/", t, 2), t / 2)
  expect_error(vec_arith("/", 2, t), class = "error_incompatible_op")

  expect_equal(vec_arith("/", t, t), 1)
  expect_equal(vec_arith("%/%", t, t), 1)
  expect_equal(vec_arith("%%", t, t), 0)
})


# Math --------------------------------------------------------------------

test_that("date and date times don't support math", {
  expect_error(vec_math("sum", new_date()), class = "error_unsupported")
  expect_error(vec_math("sum", new_datetime()), class = "error_unsupported")
})