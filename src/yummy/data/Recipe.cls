/// Recipes 
Class yummy.data.Recipe Extends %Persistent
{

/// Title
Property Title As %String(MAXLEN = "");

/// Description (it can be a multi-line text)
Property Description As %String(MAXLEN = "");

/// When it was published
Property Created As %Date;

/*
 * Additional fields 
 */
/// List of ingredients
Property Ingredients As %String(MAXLEN = "");

/// Difficulty: easy, normal, hard, ...
Property Difficulty As %String;

/// Cuisine Type: french, americain, etc.
Property CuisineType As %String;

/// How much time do you need to prepare it?
Property PreparationTime As %Integer;

/// Score the recipe based
Property YummyScore As %Integer;

/// Reasons used to score the recipe
Property Reason As %String(MAXLEN = "");

/// Some history (logs) of the recipe
Relationship History As RecipeHistory [ Cardinality = many, Inverse = Recipe ];

/// Method to add a history record to the recipe
Method AddHistory(event As %String, info As %String)
{
    try {
        set history = ##class(RecipeHistory).%New()
        set history.Event = event
        set history.Info = info
        do ..History.Insert(history)

    } catch ex {
        set ret = ex.AsStatus()
    }
}

Storage Default
{
<Data name="RecipeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Title</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Created</Value>
</Value>
<Value name="5">
<Value>YummyScore</Value>
</Value>
<Value name="6">
<Value>Ingredients</Value>
</Value>
<Value name="7">
<Value>Difficulty</Value>
</Value>
<Value name="8">
<Value>CuisineType</Value>
</Value>
<Value name="9">
<Value>PreparationTime</Value>
</Value>
<Value name="10">
<Value>Reason</Value>
</Value>
</Data>
<DataLocation>^yummy.data.RecipeD</DataLocation>
<DefaultData>RecipeDefaultData</DefaultData>
<IdLocation>^yummy.data.RecipeD</IdLocation>
<IndexLocation>^yummy.data.RecipeI</IndexLocation>
<StreamLocation>^yummy.data.RecipeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
