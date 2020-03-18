
prior_val_tbl <- reactive({
  req(input$val_date_prior)
  
  loss_run(input$val_date_prior) %>%
    select(claim_num, paid, reported)
})


changes_prep <- reactive({
  
  out <- val_tbl() %>%
           select(claim_num, accident_date, paid, reported)
  
  out <- left_join(out, prior_val_tbl(), by = "claim_num") %>%
    mutate(paid_change = paid.x - paid.y,
           reported_change = reported.x - reported.y) %>%
    filter(paid_change != 0 | is.na(paid_change) | reported_change != 0) %>%
    arrange(desc(paid_change)) %>%
    mutate(new_claim = ifelse(is.na(paid.y), "New", "Existing"),
           ay = year(accident_date)) %>%
    filter(new_claim %in% input$changes_new,
           ay %in% input$changes_ay) %>%
    select(-new_claim, -ay)
  
  out
})


output$changes_title <- renderText({
  paste0(
    "From ",
    input$val_date_prior,
    " to ",
    input$val_date
  )
})


changes_tbl_headers <- reactive({
  # for some reason I can't include these in the tags
  t1 <- paste0("As of ", input$val_date)
  t2 <- paste0("As of ", input$val_date_prior)
  t3 <- paste0("Change from ", input$val_date_prior, 
               " to ", input$val_date)
  
  htmltools::withTags(
    table(
      thead(
        tr(
          th(rowspan = 2, "Claim Number", class = "dt-border-left dt-border-right dt-border-top"),
          th(rowspan = 2, "Accident Date", class = "dt-border-right dt-border-top"),
          th(colspan = 2, t1, class = "dt-border-right dt-border-top"),
          th(colspan = 2, t2, class = "dt-border-right dt-border-top"),
          th(colspan = 2, t3, class = "dt-border-right dt-border-top")
        ),
        tr(
          th("Paid"),
          th("Reported", class = "dt-border-right"),
          th("Paid"),
          th("Reported", class = "dt-border-right"),
          th("Paid"),
          th("Reported", class = "dt-border-right")
        )
      )
    )
  )
})


output$changes_tbl <- DT::renderDT({
  out <- changes_prep() 
  col_headers <- changes_tbl_headers()
  
  
  datatable(
    out,
    rownames = FALSE,
    container = col_headers,
    class = "stripe cell-border",
    extensions = "Buttons",
    options = list(
      dom = 'Brtip',
      scrollX = TRUE,
      buttons = list( 
        list(
          extend = 'collection',
          buttons = c('csv', 'excel', 'pdf'),
          text = 'Download'
        )
      )
    )
  ) %>%
    formatCurrency(
      columns = 3:8,
      currency = "",
      digits = 0
    )
}, server = FALSE)

outputOptions(output, "changes_tbl", suspendWhenHidden = FALSE)
