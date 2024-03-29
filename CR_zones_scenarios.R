#Utilization of PrioritizR for identification of Essential Life support
#areas (ELSAs) in Costa Rica
#ecosystem services (Biodiversity intactness, below and above-growth carbon,
#agriculture value, water quality)

###################################################################
#sTEP ONE: Importating all the packeges necessary for the analyses
## Packages for data entry and processing
#install.packages("tidyverse")
library(tidyverse)

# load prioritizr package
#install.packages("prioritizr")
library("prioritizr")
#install.packages("rgdal")
library("rgdal")

#Load sover
#install.packages("slam")
library("slam")
library("gurobi")
#install.packages("here")
library("here")

library(doParallel)

###################################################################
#sTEP TWO: Set work directory, which should be where the data is saved
## Set work directory and import data
setwd("input data prepared/")

datfolder <- here("rasters_species_top100")
raster_files <- list.files(datfolder, pattern=".tif$", 
                           all.files=TRUE, full.names=TRUE)
raster_files

#import all raster files in folder using lapply

allrasters <- stack(raster_files)

#to check the index numbers of all imported raster list elements
allrasters

#call single raster element
allrasters[[80]]

#to run a function on an individual raster e.g., plot 
plot(allrasters[[23]])
plot(allrasters[[24]])

#or

species <- stack(allrasters)
names(species)
###################################################################
#sTEP THREE: Importing the data. If the directory is correct, only the full name
#of the layer will suffice to call the raster layer.
#Import data with "raster" function, from the raster package.
#Ecosystem Services:
Biodiversity <- raster("Biodiversity Intactness Index.tif") #Reads raster layers
import_hidrica<- raster("Water Importance.tif")
carbon <- raster("Geo Carbon.tif") / 1000000
organic_s <- raster("Organic Soil.tif") / 1000000
water_q<- raster("Quality of the Residual Surface Water.tif") / 10000
agricutlrure <- raster("Agriculture Suitability.tif")
#mangrove<- raster("C:/Users/Jenny/Dropbox/ELSA pilot - Costa Rica/input data original/hamilton_mangroves2014_cri.tif")
Mangroves<- raster("Mangroves.tif")
wetlands<-raster("Ramsar Site (proposed) - Wetland.tif")
bio_corridors <- raster("Biological Corridors.tif")

ESs<-stack(import_hidrica,carbon,organic_s,water_q,Mangroves)
bio<- stack(wetlands,species,bio_corridors)

#Possible cost layer:
HFP <- raster("Human Footprint.tif")

#Important features and protected lands

PA<-raster("Protected Areas.tif")
# bio_corridors<-raster("Biological Corridors.tif")
forest_reserv<-raster("Forest Reserve.tif")
T_indigena<- raster("Indigenous Territories.tif")
# costa_r<-readOGR("C:/Users/Jenny/Dropbox/ELSA pilot - Costa Rica/input data original/costa_rica_bound/costa_rica.shp") #Reads shapefiles


#Add planning units
PU<-raster("Planning_units_buffer.tif")

## Preparing layers for each zone



###Zone 1: only need to change agriculture value
agricutlrure1 <- agricutlrure*0

###Zone 2: 

Biodiversity2 <-Biodiversity*2
PA2<-PA*2
T_indigena2<-T_indigena*2
bio_corridors2<-bio_corridors*2
forest_reserv2<-forest_reserv*2
import_hidrica2<- import_hidrica*1.5
carbon2 <- carbon*1.5
water_q2<- water_q*1.5
wetlands2<-wetlands*1.5

###Zone 3:

Biodiversity3 <-Biodiversity*0.5
PA3<-PA*0.5
T_indigena3<-T_indigena*0.5
bio_corridors3<-bio_corridors*0.5
forest_reserv3<-forest_reserv*0.5
wetlands3<-wetlands*0.5
import_hidrica3<- import_hidrica*0.5
carbon3<-carbon*0.5
organic_s3 <- organic_s*0.75
water_q3<- water_q*0.75
Mangroves3<- Mangroves*0
species3<-species*0.5


#Setting up the cost layer: We can either set a cost as land, so prioritizR
#will try to get the most of each feature without surpassing the budget.
#or we can use human foot print. so the cost of creating a PA is 
# the human pressure.

#cost<-HFP #If we want to avoid areas with high human prossure
PU<-(PU/PU) #In this case, cost is the same across the landscape
#Create zonal layers
# HFP < 14 ~ 50% of country

HFP_in <- HFP < 14
plot(HFP_in,add=TRUE)
HFP_res <- HFP >= 14 & HFP < 20
plot(HFP_res)
HFP_mg<-HFP<20
plot(HFP_mg)
HFP_BAU<-HFP>=20
plot(HFP_BAU)

cellStats(PU,"sum")

#get country specific target value
count_tar <- function(target = NULL){
  round(cellStats(PU,"sum") / 100 * target, 0)
}


##Create planning units stack with the cost layers

pu1 <- stack(PU, PU,PU,PU)
names(pu1) <- c("zone_1", "zone_2", "zone_3", "zone_4")

##I included in each zone, all three zone layers (low, medium and high HFP)

zn1<-stack(Biodiversity,import_hidrica,carbon ,organic_s ,
           water_q,agricutlrure1 ,Mangroves, wetlands,bio_corridors,
           # PA,forest_reserv,T_indigena,
           HFP_in,HFP_res*0,HFP_mg*0,HFP_BAU*0)
zn2<-stack(Biodiversity2,import_hidrica2,carbon2 ,organic_s ,
           water_q2,agricutlrure1 ,Mangroves, wetlands2,bio_corridors2,
           # PA2,forest_reserv2,T_indigena2,
           HFP_in*0,HFP_res,HFP_mg*0,HFP_BAU*0)
zn3<-stack(Biodiversity3,import_hidrica3,carbon3 ,organic_s3 ,
           water_q3,agricutlrure ,Mangroves3, wetlands3,bio_corridors3,
           # PA3,forest_reserv3,T_indigena3,
           HFP_in*0,HFP_res*0,HFP_mg,HFP_BAU*0)
zn4<-stack(Biodiversity3*0,import_hidrica3*0,carbon3*0 ,organic_s3*0 ,
           water_q3*0,agricutlrure ,Mangroves3*0, wetlands3*0,bio_corridors3*0,
           # PA3*0,forest_reserv3*0,T_indigena3*0,
           HFP_in*0,HFP_res*0,HFP_mg,HFP_BAU)

### Create Zone file

z2 <- zones("zone_1" = zn1, "zone_2" = zn2,  "zone_3" = zn3, "zone_4" = zn4)


## Setting overall targets:
# 
t4 <- tibble::tibble(feature = names(zn1),
                     zone = list(names(pu1))[rep(1, 13)],
                     target = c(rep(0.2, 9), 0.3, 0.2, 0.2,0.3),
                     type = rep("relative", 13))

t4
# ##Problem
# 
# p4 <- problem(pu1, zones("zone_1" = zn1, "zone_2" = zn2, 
#                          "zone_3" = zn3,"zone_4" = zn4,
#                          feature_names = names(zn1))) %>%
#   add_min_set_objective() %>%
#   add_manual_targets(t4) %>%
#   add_binary_decisions()
# 
# s<-solve(p4, force=TRUE) # It was giving me a message saying: Warning in presolve_check.OptimizationProblem(compile(x)) :
#                          #features target values are (relatively) very high
# 
# plot(category_layer(s), main="solution")
# fr <- feature_representation(p4, s)
# fr[15:35,]


## Matrix for clumping rules.
# print stack
# print(pu1)
# plot(pu1)
# 
# z6 <- diag(4)
# z6[1, 2] <- 1
# z6[2, 1] <- 1
# z6[2, 3] <- 1
# z6[3, 2] <- 1
# 
# z6
# colnames(z6) <- c("zone_1", "zone_2", "zone_3", "zone_4")
# rownames(z6) <- colnames(z6)

# parallelization
n_cores <- 12
cl <- makeCluster(n_cores)
registerDoParallel(cl)

p1 <-   problem(pu1, zones("zone_1" = zn1, "zone_2" = zn2, 
                           "zone_3" = zn3,"zone_4" = zn4,
                           feature_names = names(zn1))) %>%
  add_min_set_objective() %>%
  add_manual_targets(t4) %>%
  add_binary_decisions()%>%
  # add_proportion_decisions %>%
  # add_boundary_penalties(penalty = 0.0000001)%>%
  add_gurobi_solver(threads = n_cores)

s1 <- solve(p1, force=TRUE)
setMinMax(s1)
plot(category_layer(s1), main="solution")

fr <- feature_representation(p1, s1)

fr[50:64,]

####################################################################
### Loop to run multiple scenarios of feature representation where
### zones representation of low, medium and high HFP is the same
z2<-zones("zone_1" = zn1, "zone_2" = zn2, 
      "zone_3" = zn3,"zone_4" = zn4,
      feature_names = names(zn1))

result_list <- list()
for(ii in 1:100){
  
  t4 <- tibble::tibble(feature = names(zn1),
                       zone = list(names(pu1))[rep(1, 16)],
                       target = c(rep((0.01*ii), 12), 0.3, 0.2, 0.2,0.3),
                       type = rep("relative", 16))
  
  p2<- problem(pu1, z2) %>%
        add_min_set_objective() %>%
        add_manual_targets(t4) %>%
        add_binary_decisions()%>%
        add_boundary_penalties(0.0001)%>%
        add_gurobi_solver(gap=0.1)
                                 
  s2 <- solve(p2,force=TRUE)
  
  result_list[[ii]] <- s2 
  fr <- feature_representation(p2,s2) 
  pu<- cellStats(s2, "sum") 
  
  if(ii == 1){
    feat_rep_rel <- data.frame(rbind(c(fr$relative_held)))
    feat_rep_abs <- data.frame(rbind(c(fr$absolute_held)))
    planning_u <- data.frame(rbind(c(pu)))
    names(feat_rep_rel) <- fr$feature
    names(feat_rep_abs) <- fr$feature
    names(planning_u)<- c("PU")
  } else {
    feat_rep_rel[ii,] <- rbind(c(fr$relative_held))
    feat_rep_abs[ii,] <- rbind(c(fr$absolute_held))
    planning_u[ii,] <- rbind(c(pu))
  }
  plot(category(s2), main=(paste("Scenario",ii))) 
  print(paste("End of scenario",ii))
  rm(p2, s2, fr,pu)
  
  
}

feat_rep_abs$scenario<- c(1:(nrow(feat_rep_abs)))
feat_rep_rel$scenario<- c(1:(nrow(feat_rep_abs)))
planning_u$scenario<- c(1:(nrow(feat_rep_abs)))

CR_Toff<- full_join(feat_rep_rel,feat_rep_abs,by="scenario")
CR_Toff<- full_join(CR_Toff,planning_u,by="scenario")

write.csv(CR_Toff,"CR_Toff.csv")
CR_Toff

CR_Toff_stack <- stack(result_list)
plot(category_layer(CR_Toff_stack[[1:4]]))

writeRaster(CR_Toff_stack,"CR_Toff_stack.tif", overwrite=TRUE)

#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                         
# Max utility
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                         


#cost<-HFP #If we want to avoid areas with high human prossure
PU<-(PU/PU) #In this case, cost is the same across the landscape
#Create zonal layers

# HFP < 14 ~ 50% of country
HFP_in <- HFP < 14
HFP_in[HFP_in < 1] <- NA
plot(HFP_in)
HFP_res <- HFP >= 14 & HFP < 20
HFP_res[HFP_res < 1] <- NA
plot(HFP_res)
HFP_mg<-HFP<20
HFP_mg[HFP_mg < 1] <- NA
plot(HFP_mg)
HFP_BAU<-HFP>=20
HFP_BAU[HFP_BAU < 1] <- NA
plot(HFP_BAU)

cellStats(PU,"sum")

#get country specific target value
count_tar <- function(target = NULL){
  round(cellStats(PU,"sum") / 100 * target, 0)
}


##Create planning units stack with the cost layers

pu1 <- stack(HFP_in, HFP_res, HFP_mg, HFP_BAU)
names(pu1) <- c("zone_1", "zone_2", "zone_3", "zone_4")

##I included in each zone, all three zone layers (low, medium and high HFP)

zn1<-stack(Biodiversity,
           import_hidrica,
           carbon,
           organic_s,
           water_q,
           agricutlrure1,
           Mangroves, 
           wetlands,
           bio_corridors)

zn2<-stack(Biodiversity2,
           import_hidrica2,
           carbon2,
           organic_s,
           water_q2,
           agricutlrure1,
           Mangroves, 
           wetlands2,
           bio_corridors2)

zn3<-stack(Biodiversity3,
           import_hidrica3,
           carbon3,
           organic_s3,
           water_q3,
           agricutlrure,
           Mangroves3, 
           wetlands3,
           bio_corridors3)

zn4<-stack(Biodiversity3 * 0,
           import_hidrica3 * 0,
           carbon3 * 0,
           organic_s3 * 0,
           water_q3 * 0,
           agricutlrure,
           Mangroves3 * 0, 
           wetlands3 * 0,
           bio_corridors3 * 0)


### Create Zone file
z2 <- zones("zone_1" = zn1, "zone_2" = zn2,  "zone_3" = zn3, "zone_4" = zn4)

p1 <- problem(pu1, zones("zone_1" = zn1, "zone_2" = zn2, 
                           "zone_3" = zn3,"zone_4" = zn4,
                           feature_names = names(zn1))) %>%
  add_max_utility_objective(c(count_tar(20), count_tar(5), count_tar(10), count_tar(65))) %>%
  add_gurobi_solver(gap = 0, threads = n_cores)

s1 <- solve(p1, force=TRUE)
setMinMax(s1)
plot(category_layer(s1), main="global")


w1 <- matrix(0, ncol = nlayers(pu1), nrow = nlayers(zn1))                     
w1[1,] <- 1

p2 <-   problem(pu1, zones("zone_1" = zn1, "zone_2" = zn2,
                           "zone_3" = zn3,"zone_4" = zn4,
                           feature_names = names(zn1))) %>%
  add_max_utility_objective(c(count_tar(20 / nlayers(zn1)), count_tar(5 / nlayers(zn1)), count_tar(10 / nlayers(zn1)), 1)) %>%
  add_feature_weights(w1) %>%
  add_gurobi_solver(gap = 0, threads = n_cores)

# p2 <- p1 %>% add_feature_weights(w1)
s2 <- solve(p2, force=TRUE)
setMinMax(s2)
plot(category_layer(s2), main="BII red")

# writeRaster(category_layer(s1), filename=here("output", "global.tif"), options="INTERLEAVE=BAND", overwrite=TRUE)
# writeRaster(category_layer(s2), filename=here("output", "BII.tif"), options="INTERLEAVE=BAND", overwrite=TRUE)
# clean up

#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                         
# P 25 R 5 M 10
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx     
p1_glob <- problem(pu1, zones("zone_1" = zn1, "zone_2" = zn2, 
                         "zone_3" = zn3,"zone_4" = zn4,
                         feature_names = names(zn1))) %>%
  add_max_utility_objective(c(count_tar(25), count_tar(5), count_tar(10), count_tar(65))) %>%
  add_gurobi_solver(gap = 0, threads = n_cores)

s1_glob <- solve(p1_glob, force=TRUE)
# setMinMax(s1_glob)
# plot(category_layer(s1_glob), main="global")
writeRaster(category_layer(s1_glob), filename=here("output", "P25R5M10_global.tif"), overwrite=TRUE)


for(ii in 1:nlayers(zn1)){

  if(!names(zn1)[ii] == "Agriculture_Suitability"){
    w1 <- matrix(0, ncol = nlayers(pu1), nrow = nlayers(zn1))                     
    w1[ii,] <- 1
    
    for(jj in 1:100){
      p1_tmp <-   p1_glob %>% 
        add_max_utility_objective(c(count_tar(jj * 25 / ((nlayers(zn1) - 1) * 100)), 
                                    count_tar(jj * 5 / ((nlayers(zn1) - 1) * 100)), 
                                    count_tar(jj * 10 / ((nlayers(zn1) - 1) * 100)), 
                                    100)) %>%
        add_feature_weights(w1)
      s1_tmp <- solve(p1_tmp, force=TRUE)
      # setMinMax(s1_tmp)
       # plot(category_layer(s1_tmp), main="BII red")
      
      writeRaster(category_layer(s1_tmp), 
                  filename=here("output", paste0("P25R5M10_", names(zn1)[ii], sprintf("_%03d.tif", jj))), 
                  overwrite=TRUE)
      
      rm(p1_tmp, s1_tmp)
    }
    
  }
  
}


#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                         
# P 35 R 10 M 20
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx     
p2_glob <- problem(pu1, zones("zone_1" = zn1, "zone_2" = zn2, 
                              "zone_3" = zn3,"zone_4" = zn4,
                              feature_names = names(zn1))) %>%
  add_max_utility_objective(c(count_tar(35), count_tar(10), count_tar(20), count_tar(35))) %>%
  add_gurobi_solver(gap = 0, threads = n_cores)

s2_glob <- solve(p2_glob, force=TRUE)
# setMinMax(s2_glob)
# plot(category_layer(s2_glob), main="global")
writeRaster(category_layer(s2_glob), filename=here("output", "P35R10M20_global.tif"), overwrite=TRUE)


for(ii in 1:nlayers(zn1)){
  
  if(!names(zn1)[ii] == "Agriculture_Suitability"){
    w1 <- matrix(0, ncol = nlayers(pu1), nrow = nlayers(zn1))                     
    w1[ii,] <- 1
    
    for(jj in 1:100){
      p2_tmp <-   p2_glob %>% 
        add_max_utility_objective(c(count_tar(jj * 35 / ((nlayers(zn1) - 1) * 100)), 
                                    count_tar(jj * 10 / ((nlayers(zn1) - 1) * 100)), 
                                    count_tar(jj * 20 / ((nlayers(zn1) - 1) * 100)), 
                                    100)) %>%
        add_feature_weights(w1)
      s2_tmp <- solve(p2_tmp, force=TRUE)
      # setMinMax(s2_tmp)
      # plot(category_layer(s2_tmp), main="BII red")
      
      writeRaster(category_layer(s2_tmp), 
                  filename=here("output", paste0("P35R10M20_", names(zn1)[ii], sprintf("_%03d.tif", jj))), 
                  overwrite=TRUE)
      
      rm(p2_tmp, s2_tmp)
    }
    
  }
  
}

#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx                         
# Trade-offs
#xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
names(zn1)
w3 <- matrix(0, ncol = nlayers(pu1), nrow = nlayers(zn1)) 
w3[c(1,5,6,7,9),] <- 1000
w3[2,] <- 10000

p3_glob <- problem(pu1, zones("zone_1" = zn1, "zone_2" = zn2, 
                              "zone_3" = zn3,"zone_4" = zn4,
                              feature_names = names(zn1))) %>%
  add_max_utility_objective(c(count_tar(35), count_tar(10), count_tar(20), count_tar(35))) %>%
  add_gurobi_solver(gap = 0, threads = n_cores)#%>%
  #add_feature_weights(w1)

s3_glob <- solve(p3_glob, force=TRUE)

fr3_glob<-feature_representation(p3_glob,s3_glob)
fr3_glob<-as.data.frame(fr3_glob)
# setMinMax(s3_glob)
plot(category_layer(s3_glob), main="global")
writeRaster(category_layer(s3_glob), filename=here("output_trade_off", "P35R10M20_global.tif"), overwrite=TRUE)


# Biod
w1 <- matrix(0, ncol = nlayers(pu1), nrow = nlayers(zn1))                     
w1[c(1,8,9),] <- 1

for(jj in 1:100){
  p3_tmp <-   p3_glob %>% 
    add_max_utility_objective(c(count_tar(jj * 35 / (3 * 100)), 
                                count_tar(jj * 10 / (3 * 100)), 
                                count_tar(jj * 20 / (3 * 100)), 
                                100)) %>%
    add_feature_weights(w1)
  s3_tmp <- solve(p3_tmp, force=TRUE)
  # setMinMax(s3_tmp)
  # plot(category_layer(s3_tmp), main="BII red")
  fr <- feature_representation(p3_tmp,s3_tmp) 
  pu<- cellStats(s3_tmp, "sum") 
  
  writeRaster(category_layer(s3_tmp), 
              filename=here("output_trade_off", paste0("P35R10M20_Biod", sprintf("_%03d.tif", jj))), 
              overwrite=TRUE)
  
  if(jj == 1){
    feat_rep_rel_bio <- data.frame(rbind(c(fr$relative_held)))
    planning_u_bio <- data.frame(rbind(c(pu)))
    names(feat_rep_rel_bio) <- paste(fr$feature,"_",fr$zone)
    names(planning_u_bio)<- c("zone1","zone2","zone3","zone4" )
  } else {
    feat_rep_rel_bio[jj,] <- rbind(c(fr$relative_held))
    planning_u_bio[jj,] <- rbind(c(pu))
  }
  plot(category_layer(s3_tmp), main=(paste("Scenario",jj))) 
  print(paste("End of scenario",jj))
  rm(p3_tmp,s3_tmp, fr,pu)
}

feat_rep_rel_bio$scenario<- c(1:(nrow(feat_rep_rel_bio)))
planning_u_bio$scenario<- c(1:(nrow(planning_u_bio)))

CR_bio_Toff<- full_join(feat_rep_rel_bio,planning_u_bio,by="scenario")


write.csv(CR_bio_Toff,"CR_bio_Toff.csv") 
# ES - Carb
w1 <- matrix(0, ncol = nlayers(pu1), nrow = nlayers(zn1))                     
w1[c(2,5,7),] <- 1

for(jj in 1:100){
  p3_tmp <-   p3_glob %>% 
    add_max_utility_objective(c(count_tar(jj * 35 / (3 * 100)), 
                                count_tar(jj * 10 / (3 * 100)), 
                                count_tar(jj * 20 / (3 * 100)), 
                                100)) %>%
    add_feature_weights(w1)
  s3_tmp <- solve(p3_tmp, force=TRUE)
  # setMinMax(s3_tmp)
  # plot(category_layer(s3_tmp), main="BII red")
  fr <- feature_representation(p3_tmp,s3_tmp) 
  pu<- cellStats(s3_tmp, "sum") 
  
  
  writeRaster(category_layer(s3_tmp), 
              filename=here("output_trade_off", paste0("P35R10M20_ES_no_carb", sprintf("_%03d.tif", jj))), 
              overwrite=TRUE)
  
  if(jj == 1){
    feat_rep_rel_ES <- data.frame(rbind(c(fr$relative_held)))
    planning_u_ES <- data.frame(rbind(c(pu)))
    names(feat_rep_rel_ES) <- paste(fr$feature,"_",fr$zone)
    names(planning_u_ES)<- c("zone1","zone2","zone3","zone4" )
  } else {
    feat_rep_rel_ES[jj,] <- rbind(c(fr$relative_held))
    planning_u_ES[jj,] <- rbind(c(pu))
  }
  plot(category_layer(s3_tmp), main=(paste("Scenario",jj))) 
  print(paste("End of scenario",jj))
  rm(p3_tmp,s3_tmp, fr,pu)
}

feat_rep_rel_ES$scenario<- c(1:(nrow(feat_rep_rel_ES)))
planning_u_ES$scenario<- c(1:(nrow(planning_u_ES)))

CR_ES_car_Toff<- full_join(feat_rep_rel_ES,planning_u_ES,by="scenario")


write.csv(CR_ES_car_Toff,"CR_ES_car_Toff.csv") 

# ES
w1 <- matrix(0, ncol = nlayers(pu1), nrow = nlayers(zn1))                     
w1[c(2,3,4,5,7),] <- 1

for(jj in 1:100){
  p3_tmp <-   p3_glob %>% 
    add_max_utility_objective(c(count_tar(jj * 35 / (3 * 100)), 
                                count_tar(jj * 10 / (3 * 100)), 
                                count_tar(jj * 20 / (3 * 100)), 
                                100)) %>%
    add_feature_weights(w1)
  s3_tmp <- solve(p3_tmp, force=TRUE)
  # setMinMax(s3_tmp)
  # plot(category_layer(s3_tmp), main="BII red")
  fr <- feature_representation(p3_tmp,s3_tmp) 
  pu<- cellStats(s3_tmp, "sum") 
  
  writeRaster(category_layer(s3_tmp), 
              filename=here("output_trade_off", paste0("P35R10M20_ES", sprintf("_%03d.tif", jj))), 
              overwrite=TRUE)
  
  if(jj == 1){
    feat_rep_rel <- data.frame(rbind(c(fr$relative_held)))
    planning_u <- data.frame(rbind(c(pu)))
    names(feat_rep_rel) <- paste(fr$feature,fr$zone)
    names(planning_u)<- c("zone1","zone2","zone3","zone4" )
  } else {
    feat_rep_rel[jj,] <- rbind(c(fr$relative_held))
    planning_u[jj,] <- rbind(c(pu))
  }
  plot(category_layer(s3_tmp), main=(paste("Scenario",jj))) 
  print(paste("End of scenario",jj))
  rm(p3_tmp,s3_tmp, fr,pu)
  
}


feat_rep_rel$scenario<- c(1:(nrow(feat_rep_rel)))
planning_u$scenario<- c(1:(nrow(feat_rep_rel)))

CR_ES_Toff<- full_join(feat_rep_rel,planning_u,by="scenario")


write.csv(CR_ES_Toff,"CR_ES_Toff.csv")


# Carbon
w1 <- matrix(0, ncol = nlayers(pu1), nrow = nlayers(zn1))                     
w1[c(3,4),] <- 1

for(jj in 1:100){
  p3_tmp <-   p3_glob %>% 
    add_max_utility_objective(c(count_tar(jj * 35 / (3 * 100)), 
                                count_tar(jj * 10 / (3 * 100)), 
                                count_tar(jj * 20 / (3 * 100)), 
                                100)) %>%
    add_feature_weights(w1)
  s3_tmp <- solve(p3_tmp, force=TRUE)
  # setMinMax(s3_tmp)
  # plot(category_layer(s3_tmp), main="BII red")
  fr <- feature_representation(p3_tmp,s3_tmp) 
  pu<- cellStats(s3_tmp, "sum") 
  
  writeRaster(category_layer(s3_tmp), 
              filename=here("output_trade_off", paste0("P35R10M20_CAR", sprintf("_%03d.tif", jj))), 
              overwrite=TRUE)
  
  if(jj == 1){
    feat_rep_rel_car <- data.frame(rbind(c(fr$relative_held)))
    planning_u_car <- data.frame(rbind(c(pu)))
    names(feat_rep_rel_car) <- paste(fr$feature,"_",fr$zone)
    names(planning_u_car)<- c("zone1","zone2","zone3","zone4" )
  } else {
    feat_rep_rel_car[jj,] <- rbind(c(fr$relative_held))
    planning_u_car[jj,] <- rbind(c(pu))
  }
  plot(category_layer(s3_tmp), main=(paste("Scenario",jj))) 
  print(paste("End of scenario",jj))
  rm(p3_tmp,s3_tmp, fr,pu)
}


feat_rep_rel_car$scenario<- c(1:(nrow( feat_rep_rel_car)))
planning_u_car$scenario<- c(1:(nrow(planning_u_car)))

CR_car_Toff<- full_join(feat_rep_rel_car,planning_u_car,by="scenario")


write.csv(CR_car_Toff,"CR_car_Toff.csv")

stopCluster(cl)
