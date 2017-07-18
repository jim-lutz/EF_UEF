# script to collect all the field names from all the CEC_*.csv files

# go to the directory containing all the CEC_*.csv files
cd '/home/jiml/HotWaterResearch/projects/CECHWT24/2016 CBECC UEF_EF/directories 2017-07-17/'

# put all the lines with Manufacturer into a file
find . -iname "CEC*.csv" -print0 | xargs -0 head -n 7 | grep Manufacturer > fieldnames_CEC.csv

# convert all the commas to new lines
perl -pi -e "s/,/\n/g;" fieldnames_CEC.csv

# sort the file and remove duplicate lines
sort fieldnames_CEC.csv | uniq > fieldnames_CEC2.csv
rm fieldnames_CEC.csv
mv fieldnames_CEC2.csv fieldnames_CEC.csv

# now open this as a spreadsheet, 
# enter a clean replacement for each fieldname in 2nd column 
# with _CEC suffix, except for 'Model Number' -> 'model'
# save as .csv for reading into R for auto renaming, if I can figure out how
libreoffice5.2  fieldnames_CEC.csv



