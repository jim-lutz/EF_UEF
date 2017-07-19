# EF_UEF.R
# find UEF and EF data for same water heaters in CEC and DOE directories
# Jim Lutz "Mon Jul 17 13:41:03 2017"

# make sure all packages loaded and start logging
source("setup.R")

# set the working directory names 
source("setup_wd.R")

# get a list of all the CEC_*.csv files in the wd_data subdirectories
csv_files <- list.files(path = wd_data, pattern = ".+.csv", 
                        full.names = TRUE, recursive = TRUE,
                        ignore.case = TRUE)
str(csv_files)

# find and read the DOE file
DOE_fn <- grep("DOE_CCMS", csv_files, value=TRUE)

DT_DOE <- as.data.table(read_csv(DOE_fn,comment = "#"))

# look at DOE field names
names(DT_DOE)

# clean up DOE field names
setnames(DT_DOE,
         c("Brand_Name", "Basic_Model_Number", "Individual_Model_Number", "Type_of_Heater",
           "Rated_Storage_Volume","Draw_Pattern","Uniform_Energy_Factor",
           "Energy_Factor","First_Hour_Rating","Maximum_Gallons_Per_Minute","Recovery_Efficiency"), # old names
         c("brand_DOE", "basic_model_DOE", "model", "type_DOE", "Vol_DOE","bin_DOE",
           "UEF_DOE","EF_DOE","FHR_DOE","MaxGPM_DOE","RE_DOE")  # new names
         )

# check if any certification numbers mean anything
DT_DOE[Is_the_Certification_for_this_Basic_Model_Based_on_a_Waiver_of_DOE_s_Test_Procedure_Requirements!="No"]
# none!
DT_DOE[Is_the_Certification_based_upon_any_Exception_Relief_from_an_Applicable_Standard_by_DOE_s_Office_of_Hearing_and_Appeals!="No"]
# none!

# drop certification columns
names(DT_DOE)[c(12,13)]
c13<-eval(names(DT_DOE)[13])
DT_DOE[,eval(c13):=NULL]
c12<-eval(names(DT_DOE)[12])
DT_DOE[,eval(c12):=NULL]
names(DT_DOE)

# list basic model numbers by mfr
DT_DOE[,list(nbmodels=length(basic_model_DOE), nmodels=length(model)), by=brand_DOE][order(-nbmodels)]
DT_DOE[, list(nmodels=length(model)), by=c("brand_DOE","basic_model_DOE")][basic_model_DOE=="N" | basic_model_DOE=="Y"][order(-nmodels)]

# find the type_DOE s
DT_DOE[,list(nmodels=length(model)), by=type_DOE]
    #                                type_DOE nmodels
    # 1:        Electric Storage Water Heater      50
    # 2: Instantaneous Gas-fired Water Heater     327
    # 3:       Gas-fired Storage Water Heater     158
    # 4:            Grid-Enabled Water Heater      14
    # 5:                Tabletop Water Heater       1
    # 6:       Oil-fired Storage Water Heater       2
    # 7:  Instantaneous Electric Water Heater      15

# sort by model number
setkey(DT_DOE, model)

# save as .csv
write_csv(DT_DOE, path = paste0(wd_data,"/DOE_WHs.csv") )

# find all the CEC *.csv files
CEC_fns <- grep("/CEC_", csv_files, value=TRUE)

# find all the fieldnames in those files
# see fieldnames_CEC.sh
fldn_fn <- paste0(wd_data,"/fieldnames_CEC.csv")
DT_fldn <- as.data.table(read_csv(fldn_fn,comment = "#"))

# get the WH types from the file names
WH_types <- gsub(".+CEC_(.+) 2017-07.+$", "\\1", CEC_fns, perl=TRUE) 


# loop through all the CEC_*.csv files 
for (n in 1:8) {
  
  # see if we're getting them all
  cat(n, sep = "\n")
  
  # n=2 # for testing only

  # show the WH type
  cat(WH_types[n], sep = "\n")

  # read the file in as a data.table
  DT_CEC <- as.data.table(read_csv(CEC_fns[n],comment = "#"))
  
  # find field names in the CEC data.table
  DT_fldn[DT_fldn$fld_old %in% names(DT_CEC)]
  
  # make lists of corresponding old and new names
  names_old <- DT_fldn[DT_fldn$fld_old %in% names(DT_CEC)][[1]]
  names_new <- DT_fldn[DT_fldn$fld_old %in% names(DT_CEC)][[2]]
  
  # change the names in the CEC data.table
  setnames(DT_CEC, names_old, names_new)
 
  # drop any columns that are all NAs
  DT_CEC[,colSums(!is.na(DT_CEC)) > 0]
  DT_CEC <- DT_CEC[,which(unlist(lapply(DT_CEC, function(x)!all(is.na(x))))),with=F]
   
  # find any model numbers in CEC that match DOE
  DT_CEC_match <- DT_CEC[model %in% DT_DOE$model,]
  setkey(DT_CEC_match, model)
  
  DT_match <- merge(DT_CEC_match, DT_DOE)
  names(DT_match)
  
  # get rid of columns of all NAs
  DT_match[,colSums(!is.na(DT_match)) > 0]
  DT_match <- DT_match[,which(unlist(lapply(DT_match, function(x)!all(is.na(x))))),with=F]
  names(DT_match)
  
  # save as .csv
  write_csv(DT_match, path = paste0(wd_data,"/DOE_CEC_",WH_types[n],".csv") )
  
}



