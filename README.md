# Interactive CV
This is a RShiny application that serves as a hub for presenting CV and using LLM to allow users to query it.

# Getting Started

## Creating an assistant
In order for this application to work properly, you need to create an assistant bot on a project on your OpenAI account. You can do this programmatically using API commands but the easier way is to navigate to your project of interest and on the dashboard select Assistants. In the top right corner of the page should be a button to create a new assistant. You should give the bot a relevant name. You'll need to write give it instructions to provide some direction on how to respond and what files to query to try to generate those responses.  Select a model you want the bot to run on. You also need to select File Search and attach your CV as a file for the assistant to utilize. You can also provide additional files in supported formats (pdf, txt, csv) for the assistant to use but you need to update the instructions so it knows how to best use those additional files. Once you create an assistant, you will be able to get the assistant id.

## Setting up environment files
To properly deploy the app onto shinyapps.io and connect it to your OpenAI account you need to set up your .Renviron file with the following:

OPENAI_API_KEY = OpenAI api key for project that assistant is connected <br>
ASST_ID = The assistant id of the OpenAI assistant you created for managing requests <br>
SHINYAPPS_TOKEN = shinyapps.io token <br>
SHINYAPPS_SECRET = shinyapps.io secret corresponding to token <br>
SHINY_CV_LOC = path to code_dir folder <br>

## Deploying app
After setting up environment file and making sure all package dependencies are installed, you can simply run deploy_app.R to deploy the app onto your shinyapps.io account.
