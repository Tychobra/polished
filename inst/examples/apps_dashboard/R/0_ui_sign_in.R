fluidPage(
  tags$head(
    tags$link(rel = "icon", href = "images/tychobra_logo.png"),
    tags$title("Tychobra"),
    tags$style("
        .above_panel {
          width: 300px;
          max-width: 100%;
          position: absolute;
          left: 50%;
          top: 100px;
          transform: translate(-50%, 0);
          border: none;/*4px solid #080021;*/
          /*padding: 10px 25px;*/
          color: #FFF;
          z-index: 2;
          font-size: 54px;
          text-align: center;
        }
        .auth_panel {
          width: 300px;
          max-width: 100%;
          position: absolute;
          left: 50%;
          top: 200px;
          transform: translate(-50%, 0);
          border: none;/*4px solid #080021;*/
          padding: 10px 25px 25px 25px;
          background: #fff;
          color: #0277BD;
          z-index: 2;
          text-align: center;
        }



        .btn-primary {
          background-color:  #0277BD !important;
          border: none;
          /*border-color: #436f88 !important!*/
        }
        .footer {
          width: 300px;
          max-width: 100%;
          position: absolute;
          left: 50%;
          bottom: 5px;
          transform: translate(-50%, 0);
          border: none;/*4px solid #080021;*/
          color: #FFF;
          z-index: 3;
        }

        html {
          margin: 0;
        }

        body {
          margin: 0;
          padding: 0;
          background-color:  #000;
          /*background-repeat: no-repeat;
          background-position: 0 0;
          background-size: cover;*/
        }

      ")
  ),
  fluidRow(
    id = "pt",
    style = "height: 99vh;",

    div(
      class = "above_panel",
      "Tychobra"
    ),

    polished::sign_in_module_ui(
      "sign_in",
      app_config$firebase
    ),

    # div(
    #   style = "width: 300px; max-width: 100%; background-color: #FFF",
    #   hr(style="padding: 0; margin: 0;"),
    #   tags$img(
    #     src = "images/tychobra_logo_name.png",
    #     alt = "Tychobra Logo",
    #     style = "width: 125px; margin-bottom: 15px; padding-top: 15px;"
    #   )
    # )

    div(
      class = "footer",
      p(
        style = "color: #FFF; text-align: center;",
        HTML("&copy;"),
        "2020 - Tychobra LLC"
      )
    )

  ),
  tags$script(src="https://unpkg.com/pts/dist/pts.min.js"),
  tags$script(src="js/pt_bezier.js")
)
