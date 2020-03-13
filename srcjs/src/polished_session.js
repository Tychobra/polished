
const polished_session = (hashed_cookie) => {
  $(document).on('shiny:sessioninitialized', function () {
    Shiny.setInputValue('hashed_cookie', hashed_cookie)
  })
}
