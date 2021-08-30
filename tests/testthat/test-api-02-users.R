

### POST ----
test_email <- "test1@tychobra.com"
test_that("can add a user to an account", {

  # delete the user if they already exist so that we can be sure to start fresh
  try({
    hold <- get_users(email = test_email)

    if (identical(nrow(hold$content), 1L)) {
      delete_user(user_uid = hold$content$uid)
    }
  })


  api_res <- add_user(email = test_email)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)


  # test that we get the correct error message if the app already exists
  tryCatch({
    api_res <- add_user(email = test_email)
  }, error = function(err) {

    expect_equal(err$message, paste0('user "', test_email, '" already exists'))
  })

})


### GET ----
test_that("can get all users for an account", {

  api_res <- get_users()


  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 8L)
})

test_user_info <- NULL
test_that("can get a app by email", {
  api_res <- get_users(email = test_email)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res$content), 8L)
  expect_equal(nrow(api_res$content), 1L)
  test_user_info <<- api_res$content
})

test_that("can get a user by user_uid", {
  api_res <- get_users(user_uid = test_user_info$uid)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res$content), 8L)
  expect_equal(nrow(api_res$content), 1L)
})

### DELETE ------
test_that("can delete a user", {

  api_res <- delete_user(user_uid = test_user_info$uid)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
})
