library(rsconnect)

code_dir <- "C:/Users/hughb/Documents/business discovery ideas/coding projects/r projects/interactive cv/code_dir"


rsconnect::setAccountInfo(name='hbcrews',
                          token=Sys.getenv("SHINYAPPS_TOKEN"),
                          secret=Sys.getenv("SHINYAPPS_SECRET"))

rsconnect::deployApp(code_dir, forceUpdate = T, appTitle = "Hugh Crews Interactive CV")
