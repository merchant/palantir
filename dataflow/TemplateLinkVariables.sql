-- Test
-- Testing the linking of variables and their templates in DATAFLOW

   -- List of all VariableDefinitions that are linked to the a DocumentTemplate
   SELECT df.VariableName, dt.TemplateName FROM dbo.TemplateVariables() tv, DATAFLOW.DocumentTemplate dt, DATAFLOW.VariableDefinition df
   WHERE tv.VariableId = df.VariableId
   AND tv.TemplateId = dt.TemplateId
      
   -- List of variables that exists in the VariableDefinition but are not linked to a DocumentTemplate
   (SELECT VariableName FROM DATAFLOW.VariableDefinition)
   EXCEPT
   (SELECT df.VariableName FROM dbo.TemplateVariables() tv, DATAFLOW.VariableDefinition df
   WHERE tv.VariableId = df.VariableId)
   
   -- Check to see which templates are using a particular variable
   SELECT *
   FROM DATAFLOW.DocumentTemplate 
   WHERE TemplateContent LIKE (SELECT '%<int>'+CAST(VariableId as varchar(10))+'</int>%'
							FROM DATAFLOW.VariableDefinition df
							WHERE df.VariableName = 'Shell.StandingData.Project.Name')

	-- Function for testing the link between variables and templates
    IF OBJECT_ID('[dbo].[TemplateVariables]') IS NOT NULL
	DROP FUNCTION [dbo].TemplateVariables
	GO     
    CREATE FUNCTION dbo.TemplateVariables()     
	RETURNS @temptable TABLE (TemplateId INTEGER, VariableId VARCHAR(MAX))     
	AS     
	BEGIN
		DECLARE @Id INT, @Index INT     
		DECLARE @Slice VARCHAR(max), @String VARCHAR(max) 
		DECLARE @StartDelimiter CHAR(5) = '<int>'
		DECLARE @EndDelimiter CHAR(6) = '</int>'  
		DECLARE cur CURSOR FOR SELECT TemplateId FROM DATAFLOW.DocumentTemplate
		OPEN cur
		FETCH NEXT FROM cur INTO @Id
		
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			SELECT @Index = 1     
			SET @String = (SELECT TemplateContent FROM DATAFLOW.DocumentTemplate WHERE TemplateId = @Id)
			IF LEN(@String)<1 or @String is null  RETURN      
			WHILE @Index!= 0     
			BEGIN     
				SET @Index = CHARINDEX(@StartDelimiter,@String)
				IF @Index = 0 BREAK
				SET @Slice = SUBSTRING(@String, LEN(@StartDelimiter),(charindex(@EndDelimiter, @String) - LEN(@EndDelimiter) + 1)) 
				
				IF(LEN(@Slice)>0 AND ISNUMERIC(@Slice)=1)
					INSERT INTO @temptable(TemplateId, VariableId) VALUES (@Id, @Slice)     

				SET @String = right(@String, LEN(@String) - @Index)     
				IF LEN(@String) = 0 break     
			END
			FETCH NEXT FROM cur INTO @Id
		END
		
		CLOSE cur
		DEALLOCATE cur
	RETURN     
	END