function(input, output, server) {
  cir_sims <- reactive({
    set.seed(1234)
    obs <- input$num_obs
    yrs <- input$num_years
    # theta parameters for `rcCIR()`
    # theta[1] = mean * (reversion speed) = a * b
    # theta[2] = mean = b
    # theta[3] = sigma
    out <- vector("list", length = obs)
    for (i in seq_along(out)) {
      out[[i]] <- rcCIR(n=input$num_years, Dt = 1, x0 = 0, theta = c(input$ir_mean * input$reversion, input$reversion, input$ir_sd))
    }
    
    out
  })
  
  bs_sims <- reactive({
    set.seed(1235)
    yields <- t_bills %>%
      mutate(
        year = year(date)
      ) %>%
      filter(
        year >= input$sample_years[1],
        year <= input$sample_years[2]
      )
    yields <- yields[[input$duration]]
    yields <- yields[!is.na(yields)]
    validate(
      need(
        length(yields) >= 2, 
        label = "Sample Years", 
        message = "Not Enough Historical Yields in Sample"
      ), 
      errorClass = character(0)
    )
    
    obs <- input$num_obs
    
    yield_changes <- diff(yields) / yields[-length(yields)]
    
    out <- vector("list", length = obs)
    for (i in seq_along(out)) {
      # find initial yield
      initial_yield <- input$bs_yield
      sim_changes <- 1 + sample(yield_changes, size = input$num_years, replace = TRUE)
      sim_changes <- cumprod(sim_changes)
      out[[i]] <- c(initial_yield * sim_changes)
    }
    
    out
    
  })
  
  sel_sim <- reactive({
    dat <- if (input$type == "cir") {
      cir_sims()
    } else {
      bs_sims()
    }
  })
  
  sims_chart_prep <- reactive({
    dat <- sel_sim()
    
    out <- vector("list", length = length(dat))
    for (i in seq_along(out)) {
      out[[i]]$data <- dat[[i]]
      out[[i]]$name <- paste0("V", i)
    }
    isolate({
      title <- if (input$type == "cir") {
        list(
          main = "Cox-Ingersoll-Ross Random Walk",
          sub = paste0("Parameters: a = ", input$reversion, ", b = ", input$ir_mean, 
                       ", sigma = ", input$ir_sd) 
        ) 
      } else {
          sel_duration <- gsub("[^*]_", "", input$duration)
          
        list(
          main = paste0("Bootstrap Resampling - Changes in ", 
                       sel_duration, 
                       " Year Treasuries"), 
          sub = paste0("Parameters: Initial Yield = ", input$bs_yield, 
                       ", Sampled Annual Changes from ", 
                       input$sample_years[1], 
                       " to ",
                       input$sample_years[2])
        )
      }
    })
    list(
      dat = out,
      titles = title
    )
  })
  
  output$sims_chart <- renderHighchart({
    dat <- sims_chart_prep()$dat
    titles <- sims_chart_prep()$titles  
    
    highchart() %>%
      hc_chart(
        zoomType = "y"
      ) %>%
      hc_title(text = titles$main) %>%
      hc_subtitle(text = titles$sub) %>%
      hc_exporting(
        enabled = TRUE,
        buttons = tychobratools::hc_btn_options()
      ) %>%
      hc_legend(
        enabled = FALSE,
        reversed = TRUE
      ) %>%
      hc_plotOptions(
        series = list(
          tooltip = list(
            crosshairs = TRUE,
            pointFormat = 'Yield: <b>{point.y:,.2f}</b>'
          ),
          marker = list(enabled = FALSE)
        )
      ) %>%
      hc_xAxis(
        categories = 1:isolate({input$num_years}),
        title = list(text = "Simulated Year")
      ) %>%
      hc_yAxis(
        title = list(text = "Yield")
      ) %>%
      hc_add_series_list(
        dat
      )
  })
  
  output$sim_tbl <- DT::renderDataTable({
    out <- sel_sim()
    names(out) <- paste0("Observation ", 1:length(out))
    out <- as_data_frame(out)
    out <- cbind("Year" = 1:nrow(out), out)
    
    DT::datatable(
      out,
      rownames = FALSE,
      extensions = "Buttons",
      options = list(
        dom= "Btp",
        buttons = list("excel", "csv"),
        ordering = FALSE,
        scrollX = TRUE
      )
    ) %>%
      formatRound(
        columns = 2:length(out),
        digits = 2
      )
  }, server = FALSE)
  
  
  output$ir_tbl <- DT::renderDataTable({
    out <- t_bills
    
    out$date <- substr(as.character(out$date), 1, 4)
    
    datatable(
      out,
      rownames = FALSE,
      colnames = c("Year", "1 Year", "5 Year", "10 Year", "20 Year", "30 Year"),
      extensions = "Buttons",
      options = list(
        dom = "Btp",
        buttons = list(c("excel", "csv")),
        columnDefs = list(
          list(targets = 0, className = "dt-center")
        )
      )
    ) %>%
      formatRound(
        columns = 2:6,
        digits = 2
      )
  }, server = FALSE)
  
  output$ir_chart <- renderHighchart({
    highchart(type = "stock") %>%
      hc_chart(
        zoomType = "y",
        type = "line"
      ) %>%
      hc_exporting(
        enabled = TRUE,
        buttons = tychobratools::hc_btn_options()
      ) %>%
      hc_legend(
        enabled = TRUE,
        reversed = TRUE
        ) %>%
      hc_rangeSelector(
        selected = 4,
        buttons = list(
          list(type = 'all', text = "ALL"),
          list(type = 'year', count = 1, text = "1yr"),
          list(type = 'year', count = 5, text = "5yr"),
          list(type = 'year', count = 10, text = "10yr"),
          list(type = 'year', count = 20, text = "20yr"),
          list(type = 'year', count = 30, text = "30yr")
        )
      ) %>%
      hc_xAxis(
        type = 'datetime'
      ) %>%
      hc_yAxis(
        title = list(text = "Yield")
      ) %>%
      hc_add_series(
        data = t_bill_30,
        name = "30 Year T-Bill",
        showInNavigator = FALSE
      ) %>%
      hc_add_series(
        data = t_bill_20,
        name = "20 Year T-Bill",
        visible = FALSE
      ) %>%
      hc_add_series(
        data = t_bill_10,
        name = "10 Year T-Bill",
        showInNavigator = TRUE
      ) %>%
      hc_add_series(
        data = t_bill_5,
        name = "5 Year T-Bill",
        visible = FALSE
      ) %>%
      hc_add_series(
        data = t_bill_1,
        name = "1 Year T-Bill"
      )
  })
}
