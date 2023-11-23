/// Simple OpenAI analysis for recipes
Class yummy.analysis.SimpleOpenAI Extends Analysis
{

Property CuisineType As %String;

Property PreparationTime As %Integer;

Property Difficulty As %String;

Property Ingredients As %String;

/// Run
/// You can try this from a terminal:
/// set a = ##class(yummy.analysis.SimpleOpenAI).%New(##class(yummy.data.Recipe).%OpenId(8))
/// do a.Run()
/// zwrite a
Method Run()
{
    try {
        do ..RunPythonAnalysis()

        set reasons = ""

        // my favourite cuisine types
        if "spanish,french,portuguese,italian,korean,japanese"[..CuisineType {
            set ..Score = ..Score + 2
            set reasons = reasons_$lb("It seems to be a "_..CuisineType_" recipe!")
        }

        // don't want to spend whole day cooking :)
        if ((+..PreparationTime'="") && (+..PreparationTime < 120)) {
            set ..Score = ..Score + 1
            set reasons = reasons_$lb("You don't need too much time to prepare it") 
        }
        
        // bonus for fav ingredients!
        set favIngredients = $listbuild("kimchi", "truffle", "squid")
        for i=1:1:$listlength(favIngredients) {
            set favIngred = $listget(favIngredients, i)
            if ..Ingredients[favIngred {
                set ..Score = ..Score + 1
                set reasons = reasons_$lb("Favourite ingredient found: "_favIngred)
            }
        }

        set ..Reason = $listtostring(reasons, ". ")

    } catch ex {
        throw ex
    }
}

/// Update recipe with analysis results
Method UpdateRecipe()
{
    try {
        // call parent class implementation first
        do ##super()

        // add specific OpenAI analysis results
        set ..Recipe.Ingredients = ..Ingredients
        set ..Recipe.PreparationTime = ..PreparationTime
        set ..Recipe.Difficulty = ..Difficulty
        set ..Recipe.CuisineType = ..CuisineType

    } catch ex {
        throw ex
    }
}

/// Run analysis using embedded Python + Langchain
/// do ##class(yummy.analysis.SimpleOpenAI).%New(##class(yummy.data.Recipe).%OpenId(8)).RunPythonAnalysis(1)
Method RunPythonAnalysis(debug As %Boolean = 0) [ Language = python ]
{
    # load OpenAI APIKEY from env
    import os
    from dotenv import load_dotenv, find_dotenv
    _ = load_dotenv('/app/.env')

    # account for deprecation of LLM model
    import datetime
    current_date = datetime.datetime.now().date()
    # date after which the model should be set to "gpt-3.5-turbo"
    target_date = datetime.date(2024, 6, 12)
    # set the model depending on the current date
    if current_date > target_date:
        llm_model = "gpt-3.5-turbo"
    else:
        llm_model = "gpt-3.5-turbo-0301"

    from langchain.chat_models import ChatOpenAI
    from langchain.prompts import ChatPromptTemplate
    from langchain.chains import LLMChain

    from langchain.output_parsers import ResponseSchema
    from langchain.output_parsers import StructuredOutputParser

    # init llm model
    llm = ChatOpenAI(temperature=0.0, model=llm_model)

    # prepare the responses we need
    cuisine_type_schema = ResponseSchema(
        name="cuisine_type",
        description="What is the cuisine type for the recipe? \
                     Answer in 1 word max in lowercase"
    )
    preparation_time_schema = ResponseSchema(
        name="preparation_time",
        description="How much time in minutes do I need to prepare the recipe?\
                     Anwer with an integer number, or null if unknown",
        type="integer",
    )
    difficulty_schema = ResponseSchema(
        name="difficulty",
        description="How difficult is this recipe?\
                     Answer with one of these values: easy, normal, hard, very-hard"
    )
    ingredients_schema = ResponseSchema(
        name="ingredients",
        description="Give me a comma separated list of ingredients in lowercase or empty if unknown"
    )
    response_schemas = [cuisine_type_schema, preparation_time_schema, difficulty_schema, ingredients_schema]

    # get format instructions from responses
    output_parser = StructuredOutputParser.from_response_schemas(response_schemas)
    format_instructions = output_parser.get_format_instructions()
    
    analysis_template = """\
    Interprete and evaluate a recipe which title is: {title}
    and the description is: {description}
    
    {format_instructions}
    """
    prompt = ChatPromptTemplate.from_template(template=analysis_template)

    messages = prompt.format_messages(title=self.Recipe.Title, description=self.Recipe.Description, format_instructions=format_instructions)
    response = llm(messages)

    if debug:
        print("======ACTUAL PROMPT")
        print(messages[0].content)
        print("======RESPONSE")
        print(response.content)

    # populate analysis with results
    output_dict = output_parser.parse(response.content)
    self.CuisineType = output_dict['cuisine_type']
    self.Difficulty = output_dict['difficulty']
    self.Ingredients = output_dict['ingredients']
    if type(output_dict['preparation_time']) == int:
        self.PreparationTime = output_dict['preparation_time']

    return 1
}

}
