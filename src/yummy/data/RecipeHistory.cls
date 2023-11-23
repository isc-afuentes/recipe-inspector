/// Simple Recipe History (logs records)
/// You can have a look at the recipe history to check when it was loaded, analyzed, etc.
Class yummy.data.RecipeHistory Extends %Persistent
{

/// Event
Property Event As %String(VALUELIST = ",LOAD,ANALYSIS-RUN");

/// Info about the event
Property Info As %String(MAXLEN = "");

/// When the event was created
Property Created As %TimeStamp [ InitialExpression = {$zdt($h,3)} ];

/// parent Recipe
Relationship Recipe As Recipe [ Cardinality = one, Inverse = History ];

/// Index
Index RecipeIndex On Recipe;

Storage Default
{
<Data name="RecipeHistoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Event</Value>
</Value>
<Value name="3">
<Value>Info</Value>
</Value>
<Value name="4">
<Value>Created</Value>
</Value>
<Value name="5">
<Value>Recipe</Value>
</Value>
</Data>
<DataLocation>^yummy.data.RecipeHistoryD</DataLocation>
<DefaultData>RecipeHistoryDefaultData</DefaultData>
<IdLocation>^yummy.data.RecipeHistoryD</IdLocation>
<IndexLocation>^yummy.data.RecipeHistoryI</IndexLocation>
<StreamLocation>^yummy.data.RecipeHistoryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
