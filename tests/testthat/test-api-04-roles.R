
### POST ----
test_role <- "test_role"
test_that("can add a role to an account", {


  api_res <- add_role(role_name = test_role)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)


  # test that we get the correct error message if the app already exists
  tryCatch({
    api_res <- add_role(role_name = test_role)
  }, error = function(err) {

    expect_equal(err$message, paste0('role "', test_role, '" already exists'))
  })

})


### GET ----
role_info <- NULL
test_that("can get all roles for an account", {

  api_res <- get_roles()


  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 3L)
  role_info <<- api_res$content[api_res$content$role_name == test_role, ]
})


test_that("can get a role by uid", {
  api_res <- get_roles(role_uid = role_info$uid)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res$content), 3L)
  expect_equal(nrow(api_res$content), 1L)
})



### DELETE ------
test_that("can delete a role", {

  api_res <- delete_role(role_uid = role_info$uid)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
})
