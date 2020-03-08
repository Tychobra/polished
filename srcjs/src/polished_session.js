
const polished_session = (token) => {
  $(document).on('shiny:sessioninitialized', function () {
    Shiny.setInputValue('polished__session', token)
  })
}
