

const polished_session = (token) => {
  $(document).on('shiny:sessioninitialized', () => {
    Shiny.setInputValue('polished__session', token)
  })
}
