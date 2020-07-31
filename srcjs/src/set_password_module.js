

const set_password_module = (ns_prefix) => {

  $(() => {

    // send a new cookie to the Shiny module server when the submit button is clicked
    $(document).on("click", `#${ns_prefix}submit`, () => {

      const polished_cookie = "p" + Math.random()

      Cookies.set(
        'polished',
        polished_cookie,
        { expires: 365 } // set cookie to expire in 1 year
      )

      Shiny.setInputValue(`${ns_prefix}submit_from_js`, {
        cookie: polished_cookie
      }, { priority: "event"})

    })

  })

}
