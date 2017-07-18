# EF_UEF.R
# find UEF and EF data for same water heaters in CEC and DOE directories
# Jim Lutz "Mon Jul 17 13:41:03 2017"

# make sure all packages loaded and start logging
source("setup.R")

# set the working directory names 
source("setup_wd.R")

# get a list of all the xls files in the wd_data subdirectories
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

# save as .csv
write_csv(DT_DOE, path = paste0(wd_data,"/DOE_WHs.csv") )

# find the CEC Small Gas & Oil file
CEC_sgo_fn <- grep("Small Gas", csv_files, value=TRUE)

DT_CEC_sgo <- as.data.table(read_csv(CEC_sgo_fn,comment = "#"))

# clean up CEC field names
names(DT_CEC_sgo)

setnames(DT_CEC_sgo,
         c( "Manufacturer", "Brand", "Model Number", "Energy Source", "Rated Volume",
            "First Hour Rating", "Maximum GPM", "Input BTUH", "Recovery Efficiency",
            "Annual Energy Consumption KBTU", "Energy Factor"), # old names
         c("mfr_CEC", "brand_CEC", "model", "fuel_CEC", "volume_CEC", 
           "FHR_CEC", "MaxGPM_CEC", "input_CEC", "RE_CEC", 
           "Eannual_CEC", "EF_CEC")  # new names
)

# keep only the desired fields in CEC_sgo
DT_CEC_sgo <- DT_CEC_sgo[,c("mfr_CEC", "brand_CEC", "model", "fuel_CEC", "volume_CEC", 
                            "FHR_CEC", "input_CEC", "RE_CEC", "EF_CEC")]

# see what we've got so far
tables()

# compare brand & mfr
DT_CEC_sgo[,list(unique(mfr_CEC))] # 38
DT_CEC_sgo[,list(unique(brand_CEC))] # 147
DT_DOE[,list(unique(brand_DOE))] # 26

DT_DOE[,list(num=length(model)), by=type_DOE]
    #                                type_DOE num
    # 1:        Electric Storage Water Heater  50
    # 2: Instantaneous Gas-fired Water Heater 327
    # 3:       Gas-fired Storage Water Heater 158
    # 4:            Grid-Enabled Water Heater  14
    # 5:                Tabletop Water Heater   1
    # 6:       Oil-fired Storage Water Heater   2
    # 7:  Instantaneous Electric Water Heater  15

DT_CEC_sgo[,list(num=length(model)), by=fuel_CEC]
    #                     fuel_CEC  num
    # 1:               Natural Gas 7105
    # 2:                       LPG 5784
    # 3:                       Oil   22
    # 4: Combo (Natural Gas & Oil)   41

# try finding any model numbers in CEC that match DOE
DT_CEC_match <- DT_CEC_sgo[model %in% DT_DOE$model,] # 139 models
names(DT_CEC_match)
setkey(DT_CEC_match, model)

# and any models in DOE that match CEC models
DT_DOE_match <- DT_DOE[model %in% (DT_CEC_sgo$model) ] # 210 models
names(DT_DOE_match)
setkey(DT_DOE_match, model)

DT_match <- merge(DT_DOE_match,DT_CEC_match, all=TRUE)
names(DT_match)
setcolorder(DT_match, 
            c("model", "basic_model_DOE", "brand_DOE", "mfr_CEC", "brand_CEC", 
              "type_DOE", "fuel_CEC", "bin_DOE", 
              "Vol_DOE", "volume_CEC", "UEF_DOE", "EF_DOE", "EF_CEC", 
              "MaxGPM_DOE", "FHR_DOE", "FHR_CEC", "RE_DOE", "RE_CEC", "input_CEC"))

# save as .csv
write_csv(DT_match, path = paste0(wd_data,"/DOE_CEC_sgo.csv") )

