library(rsconnect)

# Location of shiny application code
code_dir <- Sys.getenv("SHINY_CV_LOC")


rsconnect::setAccountInfo(name='hbcrews',
                          token=Sys.getenv("SHINYAPPS_TOKEN"),
                          secret=Sys.getenv("SHINYAPPS_SECRET"))

rsconnect::deployApp(code_dir, forceUpdate = T, appTitle = "Hugh Crews Interactive CV")
