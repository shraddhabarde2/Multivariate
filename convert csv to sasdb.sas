libname sasdata("\\vmware-host\Shared Folders\Desktop\SasData"); run;

%macro importcsv(file);
   proc import 
      datafile="%superq(file)" 
      out=%scan(&file,-2,.\) replace;
   run;
%mend importcsv;
 
%importcsv(\\vmware-host\Shared Folders\Desktop\SASData\project\train_flat_cleaned.csv)


Libname out '\\vmware-host\Shared Folders\Desktop\SasData';

data out.train;
    Set train_flat_cleaned;
 Run;
