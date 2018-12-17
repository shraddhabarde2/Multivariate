libname sasdata("\\vmware-host\Shared Folders\Desktop\SasData"); run;


/*Macro to convert csv file to sasdb*/
%macro importcsv(file);
   proc import 
      datafile="%superq(file)" 
      out=%scan(&file,-2,.\) replace; GUESSINGROWS=MAX;
   run;
%mend importcsv;
%importcsv(\\vmware-host\Shared Folders\Desktop\SasData\project\house.csv)
 

Libname out '\\vmware-host\Shared Folders\Desktop\SasData';  

data out.house;
    Set house;
 Run;


 /*Converted zipcode to continuous variable using zipcitydistance function*/
 /*Here we calculate the distance between each house and most expensive house in the dataset i.e. '98102'*/
data house2;
	set house;
    distance=zipcitydistance(zipcode, '98102');
run; 

/* Performed multiple linear regression initially to understand how the variables */
title"model before normalizing";
proc reg data= house2 plots(maxpoints=460000);
     model price = bedrooms bathrooms sqft_living sqft_lot floors waterfront view condition grade 
	sqft_above sqft_basement year_built year_renov sqft_living15 sqft_lot15 distance / vif dwProb selection=stepwise;
	output out=house_n rstudent=rstud h=lev cookd=cook dffits=dffit;
  quit;

/* Normalized the dataset house using z-score transformation*/
PROC STANDARD DATA=house2(keep= id price bedrooms bathrooms sqft_living sqft_lot floors waterfront view condition grade 
	sqft_above sqft_basement year_built year_renov sqft_living15 sqft_lot15 distance yr_built zipcode) MEAN=0 STD=1 
             OUT=house2_z(rename=(id=id price=price_z bedrooms=bedrooms_z bathrooms=bathrooms_z sqft_living=sqft_living_z
			sqft_lot=sqft_lot_z floors=floors_z waterfront=waterfront_z view=view_z condition=condition_z grade=grade_z
			sqft_above=sqft_above_z sqft_basement= sqft_basement_z yr_built=yr_built_z year_built=year_built_z year_renov=year_renov_z 
			sqft_living15=sqft_living15_z sqft_lot15=sqft_lot15_z distance=distance_z zipcode=zipcode));
  VAR  price bedrooms bathrooms sqft_living sqft_lot floors waterfront view condition grade yr_built
	sqft_above sqft_basement yr_built year_renov sqft_living15 sqft_lot15 distance ;
run;

/* Ran regression model after normalizing the dataset*/
title"Regression Model after normalizing";
proc reg data= house2_z plots(maxpoints=460000);
     model price_z = bedrooms_z bathrooms_z sqft_living_z sqft_lot_z floors_z waterfront_z view_z condition_z grade_z 
	sqft_above_z sqft_basement_z year_built_z sqft_living15_z sqft_lot15_z distance_z / vif dwProb selection=stepwise;
	output out=outhouse2_z rstudent=rstud h=lev cookd=cook dffits=dffit;
  quit;


/* Used Cook's distance to remove influential observations*/
/* Calculated threshold cookd using 4/(n-k-1) where n = number of observations and k = number of independent variables*/
/* Threshold cookD = 0.00018525379770*/
/* Kept only the non-influential observations where the cookD for each observation value was less than or equal to 0.00018525379770*/
data house3_z;
set outhouse2_z (where=(cook<=0.00018525379770));
run;

/* Performed regression model after removing influential observations*/
title"Regression after removing influential";
proc reg data= house3_z plots(maxpoints=460000);
     model price_z = bedrooms_z bathrooms_z sqft_living_z sqft_lot_z floors_z waterfront_z view_z condition_z grade_z 
	sqft_above_z sqft_basement_z year_built_z sqft_living15_z sqft_lot15_z distance_z / vif dwProb selection=stepwise;
	output out=outhouse3_z rstudent=rstud h=lev cookd=cook dffits=dffit;
  quit;

/*Derived the correlation matrix for 15 independent variables*/
title"Correlation Matrix";
proc corr data=outhouse3_z cov; 
var bedrooms_z bathrooms_z sqft_living_z sqft_lot_z floors_z waterfront_z view_z condition_z grade_z 
	sqft_above_z sqft_basement_z year_built_z sqft_living15_z sqft_lot15_z distance_z;
run;

/*Since the correlation amongst independent was high, performed component analysis*/
* Performed Principal Component Analysis *;
title "Principal Component Analysis"; 
proc princomp   data=outhouse3_z  out=pcahouse3_z;
   var  bedrooms_z bathrooms_z sqft_living_z sqft_lot_z floors_z waterfront_z view_z condition_z grade_z 
	sqft_above_z sqft_basement_z year_built_z sqft_living15_z sqft_lot15_z distance_z;
run;

/*Derived correlation matrix on the top chosen principal components*/
title"Check correlation on Principal components";
proc corr data=pcahouse3_z cov; 
var prin1 prin2 prin3 prin4 prin5 prin6 prin7 prin8 prin9 prin10;
run;

/* Performed multiple lineqar regression on the top chosen principal components*/
title "Regression using PCA";
proc reg data= pcahouse3_z plots(maxpoints=460000);
     model price_z = prin1 prin2 prin3 prin4 prin5 prin6 prin7 prin8 prin9 prin10/ vif dwProb;
	output out=pcahouse4_z rstudent=rstud h=lev cookd=cook dffits=dffit;
	plot residual.*predicted.;
  quit;

proc contents data=pcahouse4_z;
run;


/*Calculating the average price in order to split the data into 2 groups*/
title 'Calculating avg of price';
proc sql;
   select avg(price_z) format=BEST12. as AvgPrice
      from work.pcahouse4_z;
quit;

/*If the average price is greater than average price_z, house is categorized as expensive else it is categorized as not expensive*/
data house_log;  
	set pcahouse4_z;  
	if price_z >= -0.117922549 then price_new=1;  
	else price_new=0;             
run;

/* Performed Logistic Regression on the top principal components*/
title"Logistic Regression";
proc logistic data= house_log plots=all descending;
	 class price_new(ref='0')/ param=ref;
     model price_new = prin1 prin2 prin3 prin4 prin5 prin6 prin7 prin8 prin9 prin10; 
     run;
quit;

/* Performed discriminant analysis on top principal components*/
title"Discriminant Analysis";
proc discrim data=house_log method=normal distance anova manova;
	class price_new; 
	var prin1 prin2 prin3 prin4 prin5 prin6 prin7 prin8 prin9 prin10;
run;
