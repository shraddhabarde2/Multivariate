libname sasdata("\\vmware-host\Shared Folders\Desktop\SasData"); run;

%importcsv(\\vmware-host\Shared Folders\Desktop\SASData\project\train_combined.csv)

%macro importcsv(file);
   proc import 
      datafile="%superq(file)" 
      out=%scan(&file,-2,.\) replace; 
   run;
%mend importcsv;
 

Libname out '\\vmware-host\Shared Folders\Desktop\SasData';

data out.train;
    Set sample1;
 Run;
