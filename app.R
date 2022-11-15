# screen - classify pathway figures quickly

library(shiny)
library(shinyjs)
library(filesstrings)  
library(magrittr)
library(dplyr)

## Read in PFOCR fetch results
df.all <- readRDS("pfocr.rds") 
df.all <- df.all %>%
  dplyr::select(figid, pmcid, filename, figtitle, figlink) 
fig.list.all <- as.character(df.all$figid)

# set headers for output rds
choices <- c("none","ns_phospho","phosphosite")
headers <- c(names(df.all), "phospho.type")
df.done.fn <- "pfocr_screened.rds"
if(!file.exists(df.done.fn)){
  df <- data.frame(matrix(ncol=6,nrow=0))
  names(df)<-headers
  saveRDS(df, df.done.fn)
}

getFigListTodo <- function(){
  df.done <- readRDS(df.done.fn)
  fig.list.done <<- as.character(df.done$figid)
  fig.list.todo <<- BiocGenerics::setdiff(fig.list.all, fig.list.done)
}

saveChoice <- function(df){
  ## read/save rds
  df.old <- readRDS(df.done.fn)
  names(df) <- names(df.old)
  df.new <- rbind(df.old,df)
  saveRDS(df.new, df.done.fn)
}

undoChoice <- function(choice){
  ## read/save rds
  df.old <- readRDS(df.done.fn)
  figid <- tail(df.old$figid,1)
  df.new <- df.old[-nrow(df.old),]
  saveRDS(df.new, df.done.fn)
}

# SHINY UI
ui <- fluidPage(
  titlePanel("PFOCR Screen"),
  
  sidebarLayout(
    sidebarPanel(
      fluidPage(
        useShinyjs(),
        # Figure information
        textOutput("fig.count"),
        h5("Current figure"),
        textOutput("fig.name"),
        p(textOutput("fig.title")),
        uiOutput("url"),
        
        hr(),
        # Buttons
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
            if (e.which == 39) {
              $('#one').click()
            }
          });
        })")),
        actionButton("one", label = "None", icon = icon("arrow-right")), #right arrow
        br(),
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
            if (e.which == 40) {
              $('#two').click()
            }
          });
        })")),
        actionButton("two", label = "NS phospho", icon = icon("arrow-down")), #down arrow
        br(),
        tags$script(HTML("$(function(){ 
          $(document).keyup(function(e) {
            if (e.which == 38) {
              $('#three').click()
            }
          });
        })")),
        actionButton("three", label = "Phosphosites", icon = icon("arrow-up")), #up arrow
        
        hr(),
        tags$script(HTML("$(function(){ 
                         $(document).keyup(function(e) {
                         if (e.which == 37) {
                         $('#undo').click()
                         }
                         });
                         })")),
        actionButton("undo", label = "Undo", icon = icon("arrow-left")), #left arrow
        textOutput("last.choice")
      ),
      width = 4
    ),
    
    mainPanel(
      htmlOutput("figure"),
      width = 8
    )
  )
)

# SHINY SERVER
server <- function(input, output, session) {
  
  ## FUNCTION: retrieve next figure
  nextFigure <- function(){
    # Display remaining count and select next figure to process
    getFigListTodo() #updates fig.list.todo and fig.list.done globally
    fig.cnt <- length(fig.list.todo)
    fig.cnt.done <- length(fig.list.done)
    output$fig.count <- renderText({paste0(fig.cnt.done,"/",fig.cnt.done+fig.cnt," (",fig.cnt," remaining)")})
    if (fig.cnt == 0){
      shinyjs::disable("one")
      shinyjs::disable("two")
      shinyjs::disable("three")
      df<-data.frame(figtitle="No more files!")
      output$fig.title <- renderText({as.character(df$figtitle)})
      output$fig.name <- renderText({as.character("")})
      display.url <- a("", href="")
      output$url <- renderUI({display.url})
      return(df)
    }
    # Get next fig info
    df <- df.all %>% 
      filter(figid==head(fig.list.todo,1))  %>% ## MOD: head or tail
      droplevels()
    figname <- df$filename
    pmcid <- df$pmcid
    output$fig.name <- renderText({as.character(figname)})
    ## retrieve image from local
    # output$figure <- renderImage({
    #   list(src = paste(image.path,df$figid, sep = '/'),
    #        alt = "No image available",
    #        width="600px")
    # }, deleteFile = FALSE)
    # output$fig.title <- renderText({as.character(df$figtitle)})
    # url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid)
    # display.url <- a(pmcid, href=url)
    # output$url <- renderUI({display.url})
    ## retrieve image from online
    linkout <- paste0("https://www.ncbi.nlm.nih.gov/",df$figlink)
    figid.split <- strsplit(df$figid, "__")[[1]]
    src <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",figid.split[1],"/bin/",figid.split[2])
    # output$figure <- renderText({
    #   c('<a href="',linkout,'" target="_blank"><img src="',src,'", width="600px"></a>')})
    output$figure <- renderText({
      c('<img src="',src,'", width="600px">')})
    pmc.url <- paste0("https://www.ncbi.nlm.nih.gov/pmc/articles/",pmcid)
    display.url <- a(pmcid, href=pmc.url)
    output$url <- renderUI({display.url})
    
    return(df)
  }
  fig <- nextFigure()
  
  ## DEFINE SHARED VARS
  rv <- reactiveValues(fig.df=fig)  
  
  ## BUTTON FUNCTIONALITY
  observeEvent(input$one, {
    rv$fig.df$choice <- choices[1]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
    rv$fig.df$choice <- choices[1] # temp track last choice for undo
    output$last.choice <- renderText({as.character(rv$fig.df$choice)})
    shinyjs::enable("undo")
  })
  
  observeEvent(input$two, {
    rv$fig.df$choice <- choices[2]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
    rv$fig.df$choice <- choices[2] # temp track last choice for undo
    output$last.choice <- renderText({as.character(rv$fig.df$choice)})
    shinyjs::enable("undo")
  })
  
  observeEvent(input$three, {
    rv$fig.df$choice <- choices[3]
    saveChoice(rv$fig.df)
    rv$fig.df <- nextFigure()
    rv$fig.df$choice <- choices[3] # temp track last choice for undo
    output$last.choice <- renderText({as.character(rv$fig.df$choice)})
    shinyjs::enable("undo")
  })
  
  observeEvent(input$undo, {
    if(!is.null(rv$fig.df$choice)){ #only respond if last.choice is known
      undoChoice(rv$fig.df$choice)
      rv$fig.df <- nextFigure()
    }
    shinyjs::disable("undo")
  })
}

shinyApp(ui = ui, server = server)