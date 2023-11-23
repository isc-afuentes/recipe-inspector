/// Generic Yummy Analysis for recipes
/// We can build different analysis with this structure
Class yummy.analysis.Analysis Extends %RegisteredObject [ Abstract ]
{

/// Recipe to analyze
Property Recipe As yummy.data.Recipe;

/// Score calculated during analysis
Property Score As %Integer [ InitialExpression = 0 ];

/// Reason explaining the score
Property Reason As %String(MAXLEN = "");

/// Analysis constructor
Method %OnNew(recipe As yummy.data.Recipe) As %Status [ Private, ServerOnly = 1 ]
{
    set ret = $$$OK
    try {
        set ..Recipe = recipe

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

/// Run analysis
Method Run()
{
    quit $$$ERROR($$$NotImplemented)
}

/// Update recipe with analysis results
Method UpdateRecipe()
{
    try {
        // add history
        do ..Recipe.AddHistory("ANALYSIS-RUN", $classname()_". Score="_..Score_". Reason="_..Reason)
        
        // update score
        set ..Recipe.YummyScore = ..Recipe.YummyScore + ..Score
        set ..Recipe.Reason = ..Recipe.Reason _ ..Reason

    } catch ex {
        throw ex
    }
}

}
