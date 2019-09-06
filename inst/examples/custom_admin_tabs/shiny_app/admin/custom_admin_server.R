

function(input, output, session) {

  output$custom_out <- renderPrint({
    "Hi there, this is so custom!"
  })

}

