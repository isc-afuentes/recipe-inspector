Load CSV files in InterSystems IRIS through Foreign Tables and run some analysis on text data using Embedded Python (Langchain + OpenAI)

This example will guide you through loading a recipe dataset and building your own analyzer to score the recipes for you :)

## Clone repository
```console
git clone https://github.com/isc-afuentes/recipe-inspector
```

## Configure you OpenAI API Key
You need to configure your own OpenAI API key
Create a `.env` file in the same directory you have just cloned the repository with a content like this:
```
OPENAI_API_KEY="<your-api-key>"
```

## Run containers
Run InterSystems IRIS container:
```
docker compose up -d
```

* Check you can reach [Management Portal](http://localhost:52773/csp/sys/UtilHome.csp).
* Log-in using `superuser` / `SYS`

## Load dataset
You are going to work with a nice recipes [dataset](https://www.kaggle.com/datasets/michau96/recipes-from-reddit/) from Reddit.
It is mainly free text written by users and their own recipes.

* You can have a look at the file in [data/Recipes.csv](./data/Recipes.csv)
* Open [SQL Explorer](http://localhost:52773/csp/sys/exp/%25CSP.UI.Portal.SQL.Home.zen?$NAMESPACE=USER) in Management Portal or simply use your favourite SQL client to connect to IRIS.

* Create a Foreign Server
```sql
CREATE FOREIGN SERVER dataset FOREIGN DATA WRAPPER CSV HOST '/app/data/'
```

* Create a Foreign Table that connects to the CSV file
```sql
CREATE FOREIGN TABLE dataset.Recipes (
  CREATEDDATE DATE,
  NUMCOMMENTS INTEGER,
  TITLE VARCHAR,
  USERNAME VARCHAR,
  COMMENT VARCHAR,
  NUMCHAR INTEGER
) SERVER dataset FILE 'Recipes.csv' USING
{
  "from": {
    "file": {
       "skip": 1
    }
  }
}
```

* You can now have a look at the dataset in IRIS
```sql
select * from dataset.Recipes
```

## What data do we need?
The dataset is really interesting, but we would like to have some more information. 
We are going to work with two persistent classes (tables):
* [yummy.data.Recipe](src/yummy/data/Recipe.cls) - a class containing the title and description of the recipe and some other properties that we want to **extract** and **analyze** (e.g. Score, Difficulty, Ingredients)
* [yummy.data.RecipeHistory](src/yummy/data/RecipeHistory.cls) - a simple class for logging what are we doing with the recipe

We can now load our tables from the dataset:
```objectscript
do ##class(yummy.Utils).LoadDataset()
```

Have a look at the records with:
```sql
select * from yummy_data.Recipe
```

## Analyze the recipes
We want to process each recipe title and description and:
* Extract some information like **Difficulty**, **Ingredients**, **CuisineType**, etc.
* Build our own score based on our criteria so we can later decide what we want to cook

We are going to use the following:
* [yummy.analysis.Analysis](src/yummy/analysis/Analysis.cls) - a generic analysis structure we can re-use in case we want to build more analysis
* [yummy.analysis.SimpleOpenAI](src/yummy/analysis/SimpleOpenAI.cls) - an analysis that uses Embedded Python + Langchain Framework + OpenAI LLM model.

[LangChain](https://www.langchain.com/) is a framework designed to simplify the creation of applications using large language models such as OpenAI.

LLM (large language models) are really a great tool to process natural language.

LangChain is ready to work in Python, so we can use it directly in InterSystems IRIS using Embedded Python.

We can run the Python analysis with LangChain + OpenAI directly in a [webterminal](http://localhost:52773/terminal/) session:
```objectscript
do ##class(yummy.analysis.SimpleOpenAI).%New(##class(yummy.data.Recipe).%OpenId(12)).RunPythonAnalysis(1)
```

You will get something like this:
```
USER>do ##class(yummy.analysis.SimpleOpenAI).%New(##class(yummy.data.Recipe).%OpenId(12)).RunPythonAnalysis(1)
======ACTUAL PROMPT
                    Interprete and evaluate a recipe which title is: Folded Sushi - Alaska Roll
                    and the description is: Craving for some sushi but don't have a sushi roller? Try this easy version instead. It's super easy yet equally delicious!
[Video Recipe](https://www.youtube.com/watch?v=1LJPS1lOHSM)
# Ingredients
Serving Size:  \~5 sandwiches      
* 1 cup of sushi rice
* 3/4 cups + 2 1/2 tbsp of water
* A small piece of konbu (kelp)
* 2 tbsp of rice vinegar
* 1 tbsp of sugar
* 1 tsp of salt
* 2 avocado
* 6 imitation crab sticks
* 2 tbsp of Japanese mayo
* 1/2 lb of salmon  
# Recipe     
* Place 1 cup of sushi rice into a mixing bowl and wash the rice at least 2 times or until the water becomes clear. Then transfer the rice into the rice cooker and add a small piece of kelp along with 3/4 cups plus 2 1/2 tbsp of water. Cook according to your rice cookers instruction.
* Combine 2 tbsp rice vinegar, 1 tbsp sugar, and 1 tsp salt in a medium bowl. Mix until everything is well combined.
* After the rice is cooked, remove the kelp and immediately scoop all the rice into the medium bowl with the vinegar and mix it well using the rice spatula. Make sure to use the cut motion to mix the rice to avoid mashing them. After thats done, cover it with a kitchen towel and let it cool down to room temperature.
* Cut the top of 1 avocado, then slice into the center of the avocado and rotate it along your knife. Then take each half of the avocado and twist. Afterward, take the side with the pit and carefully chop into the pit and twist to remove it. Then, using your hand, remove the peel. Repeat these steps with the other avocado. Dont forget to clean up your work station to give yourself more space. Then, place each half of the avocado facing down and thinly slice them. Once theyre sliced, slowly spread them out. Once thats done, set it aside.
* Remove the wrapper from each crab stick. Then, using your hand, peel the crab sticks vertically to get strings of crab sticks. Once all the crab sticks are peeled, rotate them sideways and chop them into small pieces, then place them in a bowl along with 2 tbsp of Japanese mayo and mix until everything is well mixed.
* Place a sharp knife at an angle and thinly slice against the grain. The thickness of the cut depends on your preference. Just make sure that all the pieces are similar in thickness.
* Grab a piece of seaweed wrap. Using a kitchen scissor, start cutting at the halfway point of seaweed wrap and cut until youre a little bit past the center of the piece. Rotate the piece vertically and start building. Dip your hand in some water to help with the sushi rice. Take a handful of sushi rice and spread it around the upper left hand quadrant of the seaweed wrap. Then carefully place a couple slices of salmon on the top right quadrant. Then place a couple slices of avocado on the bottom right quadrant. And finish it off with a couple of tsp of crab salad on the bottom left quadrant. Then, fold the top right quadrant into the bottom right quadrant, then continue by folding it into the bottom left quadrant. Well finish off the folding by folding the top left quadrant onto the rest of the sandwich. Afterward, place a piece of plastic wrap on top, cut it half, add a couple pieces of ginger and wasabi, and there you have it.
                    
                    The output should be a markdown code snippet formatted in the following schema, including the leading and trailing "```json" and "```":
json
{
        "cuisine_type": string  // What is the cuisine type for the recipe?                                  Answer in 1 word max in lowercase
        "preparation_time": integer  // How much time in minutes do I need to prepare the recipe?                                    Anwer with an integer number, or null if unknown
        "difficulty": string  // How difficult is this recipe?                               Answer with one of these values: easy, normal, hard, very-hard
        "ingredients": string  // Give me a comma separated list of ingredients in lowercase or empty if unknown
}

                    
======RESPONSE
json
{
        "cuisine_type": "japanese",
        "preparation_time": 30,
        "difficulty": "easy",
        "ingredients": "sushi rice, water, konbu, rice vinegar, sugar, salt, avocado, imitation crab sticks, japanese mayo, salmon"
}
```

You can also run the whole analysis for a recipe:
```objectscript
set a = ##class(yummy.analysis.SimpleOpenAI).%New(##class(yummy.data.Recipe).%OpenId(12))
do a.Run()
zwrite a
```

```
USER>zwrite a
a=37@yummy.analysis.SimpleOpenAI  ; <OREF>
+----------------- general information ---------------
|      oref value: 37
|      class name: yummy.analysis.SimpleOpenAI
| reference count: 2
+----------------- attribute values ------------------
|        CuisineType = "japanese"
|         Difficulty = "easy"
|        Ingredients = "sushi rice, water, konbu, rice vinegar, sugar, salt, avocado, imitation crab sticks, japanese mayo, salmon"
|    PreparationTime = 30
|             Reason = "It seems to be a japanese recipe!. You don't need too much time to prepare it"
|              Score = 3
+----------------- swizzled references ---------------
|           i%Recipe = ""
|           r%Recipe = "30@yummy.data.Recipe"
+-----------------------------------------------------
```

## Analyzing multiple recipes
Of course you would like to run the analysis on the recipes we have loaded previously.

You can analyze a range of recipes IDs this way:
```objectscript
USER>do ##class(yummy.Utils).AnalyzeRange(1,10)

> Recipe 1 (.01477212s)
> Recipe 2 (.01831726s)
> Recipe 3 (.01257766s)
> Recipe 4 (.01083377s)
> Recipe 5 (.0157548s)
> Recipe 6 (.01357869s)
> Recipe 7 (.0153087s)
> Recipe 8 (.01437347s)
> Recipe 9 (.01668807s)
> Recipe 10 (.01537555s)
```

After that, have a look again at your recipe table and check the results
```sql
select * from yummy_data.Recipe
```

## Next Steps
With this simple example you've learned how to use LLM techniques to add features, or to analyze some parts of your data in InterSystems IRIS.

With this starting point, you could think about:
* Using InterSystems BI to explore and navigate your data using cubes and dashboards
* Create a webapp and provide some UI for this, you could leverage packages like RESTForms2 to automatically generate REST APIs to your persistent classes
* What about stroring whether you like or not a recipe, and then try to determine if a new recipe will like you? You could try an IntegratedML approach, or even an LLM approach providing some example data 
