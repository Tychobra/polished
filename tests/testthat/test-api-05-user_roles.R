
### POST ----

# free_user role for testing
test_role <- get_roles(role_uid = "da782793-cfac-45c1-8a55-02af4ce6011e")

test_role <- test_role$content


test_user <- get_users(email = "test1@tychobra.com")

test_user <- test_user$content

if (identical(nrow(test_user), 0L)) {
  add_user(email = "test1@tychobra.com")

  test_user <- get_users(email = "test1@tychobra.com")

  test_user <- test_user$content
}






test_that("a user can be added to a role - by user_uid", {

  api_res <- add_user_role(role_uid = test_role$uid, user_uid = test_user$uid)

  expect_equal(length(api_res), 2L)
  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res$content), 1L)

  tryCatch({

    api_res <- add_user_role(role_uid = test_role$uid, user_uid = test_user$uid)

  }, error = function(err) {
    expect_equal(err$message, "user role already exists")
  })

})


### GET ----
test_that("can get all user roles for an account", {

  api_res <- get_user_roles()

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 5L)
})

test_that("can get all user roles for a role", {

  api_res <- get_user_roles(role_uid = test_role$uid)

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 5L)
})

test_that("can get all user roles for a user", {

  api_res <- get_user_roles(user_uid = test_user$uid)

  expect_equal(status_code(api_res$response), 200L)
  expect_equal(length(api_res), 2L)
  expect_equal(length(api_res$content), 5L)
  expect_equal(nrow(api_res$content), 1L)
})



