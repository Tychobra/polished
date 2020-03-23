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
  
  output$sims_chart <- renderApexchart({
    dat <- sims_chart_prep()$dat
    titles <- sims_chart_prep()$titles  
    
    apexchart() %>% 
      ax_chart(
        type = 'line',
        zoom = list(
          type = 'y',
          enabled = TRUE,
          autoScaleYaxis = TRUE
        ),
        toolbar = list(
          autoSelected = 'zoom'
        )
      ) %>%
      ax_series2(
        dat
      ) %>%
      ax_stroke(
        width = 2
      ) %>%
      ax_xaxis(
        categories = 1:isolate({input$num_years}),
        title = list(text = "Simulated Year")
      ) %>%
      ax_yaxis(
        title = list(text = "Yield"),
        forceNiceScale = TRUE,
        decimalsInFloat = 0
        # labels = list(
        #   formatter = JS(
        #     "function (val) {
        #       debugger;
        #       return Math.round(val);
        #     }"
        #   )
        # )
      ) %>%
      ax_title(
        text = titles$main,
        align = 'center',
        style = list(
          fontSize = '18px'
        )
      ) %>%
      ax_subtitle(
        text = titles$sub,
        align = 'center'
      ) %>%
      ax_legend(
        show = FALSE
      ) %>%
      ax_tooltip(
        shared = FALSE,
        custom = JS(paste0(
          "function({series, seriesIndex, dataPointIndex, w}) {
            var x_val = dataPointIndex + 1;
            return '<div class=", '"text-center">', "'+ '<b>' + x_val + '</b>' + '</div>' + 
              'Yield: '+ '<b>' + Math.round(series[seriesIndex][dataPointIndex] * 100) / 100 + '</b>';
          }"
        )),
        theme = "light"
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
  
  output$ir_chart_2 <- renderApexchart({
    
    apexchart() %>%
      ax_chart(
        type = 'line',
        brush = list(
          enabled = TRUE,
          target = 'ir_chart'
        ),
        offsetY = -20,
        selection = list(
          enabled = TRUE,
          xaxis = list(
            # Convert from string (of date) to JS timestamp value
            min = format_date(as.POSIXct(t_bill_10_new$Date[20])), #as.numeric(as.POSIXct(t_bill_10_new$Date[20]))* 1000,
            max = format_date(as.POSIXct(t_bill_10_new$Date[35])) #as.numeric(as.POSIXct(t_bill_10_new$Date[35]))* 1000
          )
        ),
        toolbar = list(
          autoSelected = 'selection'
        ),
        group = 'timeseries'
      ) %>%
      ax_xaxis(
        type = 'datetime'
      ) %>%
      ax_yaxis(
        opposite = TRUE,
        tickAmount = 2,
        labels = list(
          formatter = JS(
            "function(val) {
              return '';
            }"
          )
        )
      ) %>%
      ax_series(
        list(
          name = "10 Year T-Bill",
          data = parse_df(t_bill_10_new)
        )
      )
  })
  
  output$ir_chart <- renderApexchart({
    
    apexchart() %>%
      ax_chart(
        id = 'ir_chart',
        type = 'line',
        zoom = list(
          type = 'xy',
          enabled = TRUE,
          autoScaleYaxis = TRUE
        ),
        toolbar = list(
          show = TRUE,
          autoSelected = 'zoom',
          offsetX = 15
        ),
        group = 'timeseries'
      ) %>%
      ax_xaxis(
        type = 'datetime'
      ) %>%
      ax_yaxis(
        title = list(text = "Yield"),
        forceNiceScale = TRUE,
        decimalsInFloat = 0,
        opposite = TRUE
      ) %>%
      ax_legend(
        position = 'top'
      ) %>%
      ax_stroke(
        width = 2
      ) %>%
      ax_tooltip(
        x = list(
          format = 'yyyy'
        )
      ) %>%
      ax_series(
        list(
          name = "1 Year T-Bill",
          data = parse_df(t_bill_1_new)
        ),
        list(
          name = "5 Year T-Bill",
          data = parse_df(t_bill_5_new)
        ),
        list(
          name = "10 Year T-Bill",
          data = parse_df(t_bill_10_new)
        ),
        list(
          name = "20 Year T-Bill",
          data = parse_df(t_bill_20_new)
        ),
        list(
          name = "30 Year T-Bill",
          data = parse_df(t_bill_30_new)
        )
      )
  })
}
