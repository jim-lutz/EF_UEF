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
DOE_fn <- grep("DOE", csv_files, value=TRUE)

DT_DOE <- as.data.table(read_csv(DOE_fn,comment = "#"))

# look at DOE field names
names(DT_DOE)

# clean up DOE field names
setnames(DT_DOE,
         c("Brand_Name", "Basic_Model_Number", "Individual_Model_Number", "Type_of_Heater",
           "Rated_Storage_Volume","Draw_Pattern","Uniform_Energy_Factor",
           "Energy_Factor","First_Hour_Rating","Maximum_Gallons_Per_Minute","Recovery_Efficiency"), # old names
         c("brand", "basic_model", "model", "type", "Vol","bin","UEF","EF","FHR","MaxGPM","RE")  # new names
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


# find the Type_of_Heater s
DT_DOE[,list(unique(type))]
  # 1:        Electric Storage Water Heater
  # 2: Instantaneous Gas-fired Water Heater
  # 3:       Gas-fired Storage Water Heater
  # 4:            Grid-Enabled Water Heater
  # 5:                Tabletop Water Heater
  # 6:       Oil-fired Storage Water Heater
  # 7:  Instantaneous Electric Water Heater

# find the CEC Small Gas & Oil file
CEC_sgo_fn <- grep("Small Gas", csv_files, value=TRUE)

DT_CEC_sgo <- as.data.table(read_csv(CEC_sgo_fn,comment = "#"))

# clean up CEC field names
names(DT_CEC_sgo)

setnames(DT_CEC_sgo,
         c( "Manufacturer", "Brand", "Model Number", "Energy Source", "Rated Volume",
            "First Hour Rating", "Maximum GPM", "Input BTUH", "Recovery Efficiency",
            "Annual Energy Consumption KBTU", "Energy Factor"), # old names
         c("mfr", "brand", "model", "fuel", "volume", "FHR", "MaxGPM", "input", "RE", 
           "Eannual", "EF")  # new names
)

# keep only the desired fields in CEC_sgo
DT_CEC_sgo <- DT_CEC_sgo[,c("mfr", "brand", "model", "fuel", "volume", "FHR", "MaxGPM", "input", "RE", "Eannual", "EF")]

# see what we've got so far
tables()

# compare brand & mfr
DT_CEC_sgo[,list(unique(mfr))] # 38
DT_CEC_sgo[,list(unique(brand))] # 147
DT_DOE[,list(unique(brand))] # 26

DT_DOE[,list(unique(type))]
  # 1:        Electric Storage Water Heater
  # 2: Instantaneous Gas-fired Water Heater
  # 3:       Gas-fired Storage Water Heater
  # 4:            Grid-Enabled Water Heater
  # 5:                Tabletop Water Heater
  # 6:       Oil-fired Storage Water Heater
  # 7:  Instantaneous Electric Water Heater

DT_CEC_sgo[,list(unique(fuel))]
  # 1:               Natural Gas
  # 2:                       LPG
  # 3:                       Oil
  # 4: Combo (Natural Gas & Oil)


# find some AO Smith 40 gallon couple gas-fired storage models in common?
# DOE
DT_DOE[,list(length(model)), by=brand]
DT_DOE[brand=="A.O. SMITH" & Vol<=45 & Vol>=35 & type=="Gas-fired Storage Water Heater",]
    # brand basic_model       model                           type Vol    bin  UEF EF FHR MaxGPM RE
    # 1: A.O. SMITH           Y  GUF 40 100 Gas-fired Storage Water Heater  38 Medium 0.65 NA  68     NA 73
    # 2: A.O. SMITH           Y FMDV 40 250 Gas-fired Storage Water Heater  38 Medium 0.59 NA  57     NA 76
    # 3: A.O. SMITH  GUF 40 100  GUF 40 100 Gas-fired Storage Water Heater  38 Medium 0.65 NA  67     NA 73
    # 4: A.O. SMITH FMDV 40 250 FMDV 40 250 Gas-fired Storage Water Heater  39 Medium 0.62 NA  57     NA 77
# Huh? 2 models twices with different values?
DT_DOE[model=="FMDV 40 250"]
DOE_AOSMITH40 <- DT_DOE[brand=="A.O. SMITH" & Vol<=45 & Vol>=35 & type=="Gas-fired Storage Water Heater",]


# CEC
names(DT_CEC_sgo)
DT_CEC_sgo[,list(length(mfr)), by=brand]
DT_CEC_sgo[brand=="A O Smith Water Products" & volume<=40 & volume>=35 & fuel=="Natural Gas",]
# there's 89 of them
CEC_AOSMITH40 <- DT_CEC_sgo[brand=="A O Smith Water Products" & volume<=40 & volume>=35 & fuel=="Natural Gas",]

# see if any have FMDV in the model
CEC_AOSMITH40[grepl("FMDV",model)]
