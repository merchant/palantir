-- Test
Declare @StartDel as CHAR(5) = '<int>'
Declare @EndDel  as CHAR(6) = '</int>'
Declare @String as Varchar(max) 
Set @String = (SELECT TemplateContent FROM DATAFLOW.RDS_DocumentTemplate WHERE TemplateId =43)
Declare @ReturnVariableID as varchar(max)
Declare @Index as INt
Declare @IndexEnd as Int
Declare @SubStringLeft as Varchar(Max)
Declare @ReturnStringLeft as Varchar(Max) = ''
 Declare @SubStringRight as Varchar(MAX) =''
 Declare @TotalLength as Int
Declare @VariableID as Int, @VariableName as Varchar(255)
set @Index = 1

Declare @DBPrefix int = 30000
declare @ReturnVariableIDLen int
declare @DEVVarID Varchar(255) =''
while @Index!=0
begin -- Begin While
--Captures Value that needs to get updated
SET @Index = CHARINDEX(@StartDel,@String)
 set @IndexEnd = CHARINDEX(@EndDel,@String)
 if @IndexEnd <1 
begin
 Set	@ReturnStringLeft  = @ReturnStringLeft + @String
 break
 end

set @SubStringLeft = LEFT(@string,@IndexEnd - 1)
SET @ReturnVariableID = SUBSTRING(@SubStringLeft, @Index + LEN(@StartDel),Len(@SubStringLeft) )
set @ReturnVariableIDLen = Len(@ReturnVariableID)
set @SubStringLeft = SUBSTRING(@SubStringLeft,-1,@Index + LEN(@StartDel)+1)
set @SubStringRight = RIGHT(@String,Len(@String) - LEN(@SubStringLeft) - LEN(@ReturnVariableID) - LEN(@EndDel))


if (ISNUMERIC(@ReturnVariableID) = 1)
begin


select @VariableID = VariableID, @VariableName = VariableName from DATAFLOW.RDS_VariableDefinition where VariableId = Cast (@ReturnVariableID  as int)

if  exists(select VariableId from DATAFLOW.VariableDefinition where  VariableName = @VariableName)
begin -- if Exists
select @DEVVarID = VariableID from DATAFLOW.VariableDefinition where VariableName = @VariableName
	if (@DevVarID <> @VariableID)
		begin
		set	@ReturnVariableID = @DevVarID
		end 
		--select VariableId from DATAFLOW.VariableDefinition where VariableId = @VariableID and VariableName = @VariableName
end --End If Exists
if not exists(select VariableId from DATAFLOW.VariableDefinition where  VariableName = @VariableName)
 begin
	Set @ReturnVariableID = Cast((@DBPrefix + Cast( @ReturnVariableID as Int)) as Varchar(max))
	Set Identity_insert [Dataflow].[VariableDefinition] on
	insert into Dataflow.VariableDefinition 
	(VariableID , VariableName, VariableCategoryId , Prompt, Comments, DataType, label, SubCategories, LookupList)
	select VariableID + @DbPrefix, VariableName,VariableCategoryID, Prompt, Comments, DataType, label, SubCategories, LookupList
	
	 from Dataflow.RDS_VariableDefinition where VariableName = @VariableName
	Set Identity_Insert [Dataflow].[VariableDefinition] OFF
 end


Set @ReturnStringLeft = @ReturnStringLeft + @SubStringLeft + @ReturnVariableID + @EndDel


Select @String = @SubStringRight
--Select @String
end --IsNumeric IF
end --end While

select @ReturnStringLeft as EndString


insert into Dataflow.DocumentTemplate (templateName, templateDescription, TemplateContent)
--  select TemplateName, templateDescription, @ReturnStringLeft from Dataflow.RDS_DocumentTemplate 
-- where TemplateID = 43
