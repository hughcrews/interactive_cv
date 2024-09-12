# Interactive CV
This is a RShiny application that serves as a hub for presenting CV and using LLM to allow users to query it.

# Setting up environment
To properly deploy the app onto shinyapps.io and connect it to your OpenAI account you need to set up your .Renviron file with the following:

OPENAI_API_KEY = OpenAI api key for project that assistant is connected <br>
ASST_ID = The assistant id of the OpenAI assistant you created for managing requests <br>
SHINYAPPS_TOKEN = shinyapps.io token <br>
SHINYAPPS_SECRET = shinyapps.io secret corresponding to token <br>
