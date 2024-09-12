# Load necessary libraries
library(shiny)
library(markdown)
library(shinyjs)
library(httr)
library(jsonlite)

# Define the assistant name (ID) and the API key
assistant_id <- Sys.getenv("ASST_ID")  # Replace with your assistant ID
api_key <- Sys.getenv("OPENAI_API_KEY")

# Start an assistant and create a thread when app is loaded
# Make the GET request to retrieve the assistant
asst <- GET(
  url = paste0("https://api.openai.com/v1/assistants/", assistant_id),
  add_headers(
    `Content-Type` = "application/json",
    Authorization = paste("Bearer", api_key),
    `OpenAI-Beta` = "assistants=v2"
  )
)

# Check the status and parse the response
if (status_code(asst) == 200) {
  asst_content <- content(asst, as = "parsed")
  print(asst_content)  # Print or further process the retrieved assistant object
} else {
  print(paste("Failed to retrieve assistant:", status_code(asst)))
}


# Now create a new thread
create_thread <- POST(
  url = "https://api.openai.com/v1/threads",
  add_headers(
    `Content-Type` = "application/json",
    Authorization = paste("Bearer", api_key),
    `OpenAI-Beta` = "assistants=v2"
  ),
  body = "{}",  # Empty JSON body, adjust as needed for additional parameters
  encode = "json"
)

# Check the status and parse the response
if (status_code(create_thread) == 200) {
  thread_content <- content(create_thread, as = "parsed")
  thread_id <- thread_content$id
} else {
  print(paste("Failed to create a new thread:", status_code(create_thread)))
  print(content(create_thread, as = "text"))  # Print error details
}


# UI part of the Shiny app
ui <- fluidPage(
  # Use shinyjs to enable JavaScript functionality
  useShinyjs(),
  
  # Add custom CSS and JavaScript for styling and auto-scrolling
  tags$head(
    tags$script(src = "scroll.js"),  # Link to the JavaScript file
    tags$style(HTML("
      .chat-box {
        border: 1px solid #ddd;
        padding: 10px;
        height: 400px;
        overflow-y: scroll;
        margin-bottom: 10px;
        position: relative; /* Ensure proper positioning */
      }
      .chat-log {
        white-space: pre-wrap;
      }
      .btn-submit {
        width: 20%;
        margin-top: 10px;
        background-color: #f0f0f0; /* Default grey color */
        border: 1px solid #ccc;
      }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      div(
        style = "margin-bottom: 10px;",
        actionButton("view_cv", "View CV")
      ),
      div(
        style = "margin-bottom: 10px;",
        actionButton("interact_cv", "Ask Questions of CV")
      ),
      downloadButton("download_cv", "Download CV")
    ),
    mainPanel(
      uiOutput("main_content")
    )
  )
)

# Server part of the Shiny app
server <- function(input, output, session) {
  
  # Placeholder for selected section
  selected_section <- reactiveVal("view")
  
  # Reactive value to store chat history as HTML
  chat_history <- reactiveVal("Welcome! You can ask questions about the CV here. For example, you might ask about my experience or education.")
  
  # Function to run the thread and fetch the latest message with retry logic
  run_thread_and_fetch_message <- function(thread_id, api_key, assistant_id) {
    max_retries <- 3
    attempt <- 1
    ready <- FALSE
    last_message <- NULL
    thread_ran_successfully <- FALSE
    
    while (attempt <= max_retries && !ready) {
      if (!thread_ran_successfully) {
        # Make a POST request to run the thread with the specified assistant
        run_thread <- httr::POST(
          url = paste0("https://api.openai.com/v1/threads/", thread_id, "/runs"),
          httr::add_headers(
            `Content-Type` = "application/json",
            Authorization = paste("Bearer", api_key),
            `OpenAI-Beta` = "assistants=v2"
          ),
          body = jsonlite::toJSON(list(
            assistant_id = assistant_id
          ), auto_unbox = TRUE)
        )
        
        # Check the status of the thread run
        if (httr::status_code(run_thread) == 200) {
          thread_ran_successfully <- TRUE
        } else {
          print(paste("Failed to run the thread:", httr::status_code(run_thread)))
          print(httr::content(run_thread, as = "text"))
        }
      }
      
      # If the thread has successfully run, proceed to fetch messages
      if (thread_ran_successfully) {
        all_messages <- httr::GET(
          url = paste0("https://api.openai.com/v1/threads/", thread_id, "/messages"),
          httr::add_headers(
            `Content-Type` = "application/json",
            Authorization = paste("Bearer", api_key),
            `OpenAI-Beta` = "assistants=v2"
          )
        )
        
        # Check if the request to fetch messages was successful
        if (httr::status_code(all_messages) == 200) {
          # Parse the response content as JSON
          messages <- httr::content(all_messages, as = "parsed", type = "application/json")
          
          # Check if messages are present and if the last message is from the assistant
          if (length(messages$data) > 0) {
            last_message <- head(messages$data, n = 1)[[1]]  # Extract the last message
            
            # Check if the last message is from the assistant
            if (last_message$role == "assistant" && !is.null(last_message$content[[1]]$text$value)) {
              ready <- TRUE
            }
          }
        } else {
          print(paste("Failed to retrieve messages:", httr::status_code(all_messages)))
        }
      }
      
      # If not ready, wait a bit before the next attempt
      if (!ready) {
        Sys.sleep(2)  # Wait 2 seconds before retrying
        attempt <- attempt + 1
      }
    }
    
    # Return the latest message if ready, otherwise NULL
    if (ready) {
      return(last_message$content[[1]]$text$value)
    } else {
      return(NULL)
    }
  }
  
  # Observe buttons to switch content
  observeEvent(input$view_cv, {
    selected_section("view")
  })
  
  observeEvent(input$interact_cv, {
    selected_section("interact")
  })
  
  # Dynamic UI output based on the selected section
  output$main_content <- renderUI({
    switch(selected_section(),
           "view" = includeMarkdown("cv.md"),  # Load your CV Markdown file
           "interact" = fluidPage(
             tags$div(id = "chat_box", class = "chat-box",
                      htmlOutput("chat_log")  # Output box for chat history
             ),
             tags$textarea(id = "question", rows = 4, style = "width: 100%;", placeholder = "Type your questions here"),  # Input box for user questions
             actionButton("submit_question", "Submit", class = "btn-submit")
           )
    )
  })
  
  # Handle question submission
  observeEvent(input$submit_question, {
    new_question <- input$question
    
    if (new_question != "") {
      # Disable the submit button immediately
      shinyjs::disable("submit_question")
      
      current_chat <- chat_history()
      
      # Check if this is the first question and remove the initial placeholder text
      if (grepl("Welcome! You can ask questions", current_chat)) {
        updated_chat <- paste("<strong>You:</strong> ", new_question, sep = "")
      } else {
        # Append new question to chat history with extra vertical space using HTML
        updated_chat <- paste(current_chat, "<br><br><br><strong>You:</strong> ", new_question, sep = "")
      }
      
      chat_history(updated_chat)
      
      # Create a new message in the thread
      add_message <- httr::POST(
        url = paste0("https://api.openai.com/v1/threads/", thread_id, "/messages"),
        httr::add_headers(
          `Content-Type` = "application/json",
          Authorization = paste("Bearer", api_key),
          `OpenAI-Beta` = "assistants=v2"
        ),
        body = jsonlite::toJSON(list(
          role = "user",
          content = new_question
        ), auto_unbox = TRUE)
      )
      
      # Check if the request was successful and display the result
      if (httr::status_code(add_message) == 200) {
        message_content <- httr::content(add_message, as = "parsed", type = "application/json")
        print(message_content)
      } else {
        print(paste("Failed to send the message:", httr::status_code(add_message)))
        print(httr::content(add_message, as = "text"))
      }
      
      # Run the thread and fetch the latest message with retry logic
      response_text <- run_thread_and_fetch_message(thread_id, api_key, assistant_id)
      
      if (!is.null(response_text)) {
        # Clean and format the response if successful
        cleaned_text <- gsub("【[0-9]+:[0-9]+†[^】]+】", "", response_text)
        formatted_text <- markdown::markdownToHTML(cleaned_text, fragment.only = TRUE)
        response <- paste("<br><br><strong>CV Bot:</strong> ", formatted_text, sep = "")
        updated_chat <- paste(updated_chat, response, sep = "")
        chat_history(updated_chat)
      } else {
        # Handle the failure case gracefully
        response <- "<br><br><strong>CV Bot:</strong> Something went wrong. Please try asking again."
        updated_chat <- paste(updated_chat, response, sep = "")
        chat_history(updated_chat)
      }
      
      # Clear the input field
      updateTextInput(session, "question", value = "")
      
      # Ensure the chat box scrolls to the bottom
      shinyjs::runjs("scrollToBottom('chat_box')")
      
      # Run scrollToBottom again to ensure the final scroll is applied
      shinyjs::runjs("setTimeout(function() { scrollToBottom('chat_box'); }, 100);")
      
      # Re-enable the submit button once the process is complete
      shinyjs::enable("submit_question")
    } else {
      # If no text is entered, just re-enable the button
      shinyjs::enable("submit_question")
    }
  })
  
  # Placeholder for chat log with HTML content
  output$chat_log <- renderUI({
    HTML(chat_history())
  })
  
  # Download handler for downloading the CV
  output$download_cv <- downloadHandler(
    filename = function() {
      "Hugh_Crews_CV.pdf"
    },
    content = function(file) {
      file.copy("cv_template.pdf", file)  # Point to your pre-rendered PDF file
    }
  )
}


# Run the app
shinyApp(ui = ui, server = server)

