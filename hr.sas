/*Exploratory Data Analysis*/
/*reading in data*/
DATA hr; 
INFILE '/home/ansonge0/my_data/HR_comma_sep.csv' delimiter=',' firstobs=2;  
INPUT satisfaction_level last_evaluation number_project average_montly_hours time_spend_company 
	Work_accident left promotion_last_5years sales$ salary$; 
RUN; 

/*summaries*/
PROC MEANS DATA=hr; 
CLASS left; 
VAR satisfaction_level 
	last_evaluation 
	number_project 
	average_montly_hours 
	time_spend_company 
	Work_accident 
	promotion_last_5years;
RUN; 

/*distributions by class */
/*promotion/work accident very similar, may not be useful*/
PROC UNIVARIATE DATA= hr; 
	HISTOGRAM satisfaction_level 
	last_evaluation 
	number_project 
	average_montly_hours 
	time_spend_company
	Work_accident 
	promotion_last_5years;
	CLASS left;  
RUN;

PROC SGPLOT DATA=hr; 
	VBOX satisfaction_level 
	last_evaluation 
	number_project 
	average_montly_hours 
	time_spend_company
	Work_accident 
	promotion_last_5years 
	/ CATEGORY=left; 
RUN; 

/*Boxplots*/  
PROC SORT DATA=hr OUT=hr_sort; 
	BY left; 
RUN; 
 
	 
PROC BOXPLOT DATA=hr_sort;
plot (satisfaction_level 
	last_evaluation 
	number_project 
	average_montly_hours 
	time_spend_company
	Work_accident 
	promotion_last_5years)*left;
RUN;	 

/*No significant/strong correlations between columns*/ 
PROC CORR DATA=hr COV; 
VAR satisfaction_level 
	last_evaluation 
	number_project 
	average_montly_hours 
	time_spend_company; 
RUN; 


PROC SGSCATTER DATA=hr; 
TITLE "Human Resources Scatterplot Matrix"; 
MATRIX satisfaction_level 
	last_evaluation 
	number_project 
	average_montly_hours 
	time_spend_company 
		/ GROUP=left; 
RUN; 

/*Changing salary attributes to numeric*/
PROC SQL;
	UPDATE 
		hr
	SET salary = (
		CASE 
			WHEN salary = 'low' THEN '1'
			WHEN salary = 'medium' THEN '2'
			ELSE '3'
		END 
		);
QUIT;  

DATA hr; 
SET hr; 
newsalary = INPUT(salary, 1.); 
DROP salary; 
RENAME newsalary = salary; 
RUN; 

/*Predictive Analysis - Logistic Regression*/
PROC SURVEYSELECT data=hr out=split samprate=.7 outall;
RUN;

DATA training validation;
SET split;
IF selected = 1 THEN OUTPUT training;
ELSE OUTPUT validation;
RUN; 

PROC LOGISTIC DATA=hr;
	CLASS sales Work_accident; 
	MODEL left (event = '1') = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company 
	Work_accident promotion_last_5years sales; 
	score data=training out = Logit_Training fitstat outroc=troc;
	score data=validation out = Logit_Validation fitstat outroc=vroc; 
RUN;


Proc npar1way data=Logit_Validation edf;
class left;
var p_1;
RUN;

/* Decision Tree - Very high performance */
ods graphics on; 
proc hpsplit data=hr seed=123;
	class sales left;
	model left = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company 
	Work_accident promotion_last_5years sales;
	grow entropy; 
	prune costcomplexity; 
RUN; 
 
/* promotion_last_5years removed - performance remains the same */
proc hpsplit data=hr seed=123;
	class sales left;
	model left = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company 
	Work_accident sales;
	grow entropy; 
	prune costcomplexity; 
RUN; 

/* promotion_last_5years, sales removed - performance nearly 
   identical. May generalize new data better than the first tree */
proc hpsplit data=hr seed=123;
	class sales left;
	model left = satisfaction_level last_evaluation number_project average_montly_hours time_spend_company 
	sales;
	grow entropy; 
	prune costcomplexity; 
RUN; 
