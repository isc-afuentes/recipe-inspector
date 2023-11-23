/// Yummy utils
Class yummy.Utils Extends %RegisteredObject
{

/// Delete all data!
/// do ##class(yummy.Utils).KillData()
ClassMethod KillData()
{
    try {
        $$$ThrowOnError(##class(yummy.data.RecipeHistory).%KillExtent())
        $$$ThrowOnError(##class(yummy.data.Recipe).%KillExtent())
        
    } catch ex {
        throw ex
    }
}

/// Load data from foreign table dataset
/// do ##class(yummy.Utils).LoadDataset()
ClassMethod LoadDataset()
{
    try {
        set sql="select CreatedDate, Title, Comment FROM dataset.Recipes"
		
		set statement = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(statement.%Prepare(sql))	
		#dim result As %SQL.StatementResult = statement.%Execute()
		while result.%Next() {
            set recipe = ##class(yummy.data.Recipe).%New()
            set recipe.Title = result.%Get("Title")
            set recipe.Description = result.%Get("Comment")
            set recipe.Created = result.%Get("CreatedDate")
            do recipe.AddHistory("LOAD", "Loaded from dataset")
            $$$ThrowOnError(recipe.%Save())
		}
        
    } catch ex {
        throw ex
    }
}

/// Analyze a given recipe
/// do ##class(yummy.Utils).Analyze(123)
ClassMethod Analyze(recipeId As %Integer)
{
    try {
        set begin = $zhorolog
        
        set recipe = ##class(yummy.data.Recipe).%OpenId(recipeId)
        if '$isobject(recipe) {
            throw ##class(%Exception.General).%New("Recipe does not exist", "", "", recipeId)
        }

        write !,"> Recipe ",recipeId
        
        // new analysis run: reset score, score
        set recipe.YummyScore = 0
        set recipe.Reason = ""
        
        // run all required analysis
        set analysis = ##class(yummy.analysis.SimpleOpenAI).%New(recipe)
        do analysis.Run()
        do analysis.UpdateRecipe()
        
        // save recipe
        $$$ThrowOnError(recipe.%Save())

        set end = $zhorolog
        write " ("_(end-begin)_"s)",!

    } catch ex {
        throw ex
    }
}

/// Analyze a range of recipes
/// do ##class(yummy.Utils).AnalyzeRange(1,10)
ClassMethod AnalyzeRange(startId As %Integer, endId As %Integer)
{
    try {
        set sql="select ID FROM yummy_data.Recipe where ID between ? and ?"
		
		set statement = ##class(%SQL.Statement).%New()
		$$$ThrowOnError(statement.%Prepare(sql))	
		#dim result As %SQL.StatementResult = statement.%Execute(startId, endId)
		while result.%Next() {
            do ..Analyze(result.%Get("ID"))
		}
        
    } catch ex {
        throw ex
    }
}

}
