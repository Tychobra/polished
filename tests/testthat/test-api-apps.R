
### POST -----
test_app_name <- "test_app"
test_that("can add an app to an account", {

  api_res <- add_app(app_name = test_app_name)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)


  # test that we get the correct error message if the app already exists
  tryCatch({
    api_res <- add_app(app_name = test_app_name)
  }, error = function(err) {

    expect_equal(err$message, paste0('app "', test_app_name, '" already exists'))
  })

})

### GET ------
test_that("can get all apps for an account", {

  api_res <- get_apps()


  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 5L)
})

test_app_info <- NULL
test_that("can get an app by app_name", {
  api_res <- get_apps(app_name = "test_app")

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res$content), 5L)
  expect_equal(nrow(api_res$content), 1L)
  test_app_info <<- api_res$content
})


test_that("can get an app by app_uid", {
  api_res <- get_apps(app_uid = test_app_info$uid)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res$content), 5L)
  expect_equal(nrow(api_res$content), 1L)
})

# PUT -------
test_that("can update an app", {

  api_res <- update_app(
    app_uid = test_app_info$uid,
    app_name = "test_app2",
    app_url = "http:/127.0.0.01:5000"
  )

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
})

### DELETE -----
test_that("can delete an app", {

  api_res <- delete_app(app_uid = test_app_info$uid)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
})
