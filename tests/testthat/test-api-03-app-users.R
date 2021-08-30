### POST ----

test_app <- get_apps(app_name = "polished_test")

test_app <- test_app$content


test_user <- get_users(email = "test1@tychobra.com")

test_user <- test_user$content

if (identical(nrow(test_user), 0L)) {
  add_user(email = "test1@tychobra.com")

  test_user <- get_users(email = "test1@tychobra.com")

  test_user <- test_user$content
}






test_that("a user can be added/invited to an app - by email", {

  api_res <- add_app_user(app_uid = test_app$uid, email = test_user$email)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)

  tryCatch({

    api_res <- add_app_user(app_uid = test_app$uid, email = test_user$email)

  }, error = function(err) {
    expect_equal(err$message, "user is already authorized to access app")
  })

})


### GET ----
test_that("can get all app users for an account", {

  api_res <- get_app_users()

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 6L)
})

test_that("can get all app users for an app", {

  api_res <- get_app_users(app_uid = test_app$uid)

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 6L)
})

test_that("can get an app user - by email", {

  api_res <- get_app_users(app_uid = test_app$uid, email = test_user$email)

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 6L)
  expect_equal(nrow(api_res$content), 1L)
})

test_that("can get an app user - by user_uid", {

  api_res <- get_app_users(app_uid = test_app$uid, user_uid = test_user$uid)

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 6L)
  expect_equal(nrow(api_res$content), 1L)
})

test_that("can get all apps for a user - by email", {

  api_res <- get_app_users(email = test_user$email)

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 6L)
})

test_that("can get all apps for a user - by user_uid", {

  api_res <- get_app_users(user_uid = test_user$uid)

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 6L)
})


### PUT -----
test_that("can update a user", {

  api_res <- update_app_user(user_uid = test_user$uid, app_uid = test_app$uid, is_admin = TRUE)

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 1L)
})

### DELETE ------
test_that("can delete a user", {

  api_res <- delete_app_user(user_uid = test_user$uid, app_uid = test_app$uid)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res$content), 1L)
})