#!/bin/bash

echo "Author:     Eric Samakinwa
Affiliation:University of Bern, Switzerland
contact:    eric.samakinwa@giub.unibe.ch
November, 2019."
#############################################################################################
echo "Sea Ice Reconstruction via analog method"
#############################################################################################


Realisation=1

##############Final Reconstruction Year##############
Y_END=1849

#Depends on Season(DJF, MAM, JJA, SON) 
M=("6")

##############Input files##############

#file1=winter_sst_1851-1950_69.nc
pool_loc_NH=pool/sst_1941-2000_JJA_NH_final.nc

pool_loc_SH=pool/sst_1941-2000_JJA_SH_final.nc

#######################################

file_NH=Recon/NH_summer_1001-2010_sst_12rm_R1.nc

file_SH=Recon/SH_summer_1001-2010_sst_12rm_R1.nc

#############################################################################################
#########################################Seaice pool#########################################
#Must have the same number of timesteps as the file in pool_loc and also cover the same period of time

sic_f=sic/dummy/sic_1941-2000_JJA_NH_final.nc

#Southern Hemisphere

sic_f2=sic/dummy/sic_1941-2000_JJA_SH_final.nc
###############################Output file###################################################
Output_f=summer_rec
#############################################################################################

######################Number of analogs in the pool##########################################

timesteps=180

#############################################################################################
#Calculate for all timesteps from year 1001 to 1940 for month M[0]!!!
#############################################################################################
for j in $(seq 1001 $Y_END)
do
  #Create an empty arrays wrt. year and month
  corr_array=()
  mon_array=()
  year_array=()
  rec_mon=()
  for i in $(seq 1 $timesteps)
  do
    #Correlate reconstructed SST with Instrumental Target (HadISST) and save values corr_array.
    corr=$(cdo output -fldcor -seltimestep,$i $pool_loc_NH -selyear,$j -selmon,${M[0]} $file_NH)
    echo "$i $j for Nouthern Hemisphere" 
    echo "$i $j for Nouthern Hemisphere" 
    echo "$i $j for Nouthern Hemisphere"
    echo ${corr} 
    corr_array=("${corr_array[@]}" "$corr")
    mon_array=("${mon_array[@]}" "${M[0]}") 
    year_array=("${year_array[@]}" "$j")
    rec_mon=("${rec_mon[@]}" "${M[0]}")
  done
  #Find the maximum correlation value
  max=${corr_array[0]} 
  position=1
  for v in ${corr_array[@]}; do
      if [ "$v" \> "$max" ]; then max=$v; fi; 
  done
  echo "Highest correlation value is $max"
  #Look for the index position of the max. corr. value #note bash indexing starts from 0
  #So add one to make sure it selects the correct timestep 
  for (( k=1;k<=${#corr_array[*]};k++ ))
  do
         if [ ${corr_array[$k]} == $max ]
         then
                 increment=1
                 index=$(echo "$k + $increment" |bc)
                 echo "$max is the maximum correlation and it is found at index $index"
                 break
         fi
  done  
  echo "the max corr. val. is found for month ${mon_array[$k]} 
  in year ${year_array[$k]} as $max from pool value $index of $timesteps"
  #Select analog for Northern Hemisphere
  cdo seltimestep,$index -setyear,$j -setmon,${M[0]} $sic_f $Output_f/N.$j.${M[0]}.nc 
  #Create an empty arrays wrt. year and month but this time for Southern Hemisphere
  corr_array=()
  mon_array=()
  year_array=()
  rec_mon=()
  for i in $(seq 1 $timesteps)
  do
    #Correlate reconstructed SST with Instrumental Target (HadISST) and save values corr_array.
    corr=$(cdo output -fldcor -seltimestep,$i $pool_loc_SH -selyear,$j -selmon,${M[0]} $file_SH)
    echo "$i $j for Southern Hemisphere" 
    echo "$i $j for Southern Hemisphere" 
    echo "$i $j for Southern Hemisphere"
    echo ${corr} 
    corr_array=("${corr_array[@]}" "$corr")
    mon_array=("${mon_array[@]}" "${M[0]}") 
    year_array=("${year_array[@]}" "$j")
    rec_mon=("${rec_mon[@]}" "${M[0]}")
  done
  #Find the maximum correlation value
  max=${corr_array[0]} 
  position=1
  for v in ${corr_array[@]}; do
      if [ "$v" \> "$max" ]; then max=$v; fi; 
  done
  echo "Highest correlation value is $max"
  #Look for the index position of the max. corr. value #note bash indexing starts from 0
  #So add one to make sure it selects the correct timestep 
  for (( k=1;k<=${#corr_array[*]};k++ ))
  do
         if [[ ${corr_array[$k]} = $max ]]
         then
                 increment=1
                 index=$(echo "$k + $increment" |bc)
                 echo "$max is the maximum correlation and it is found at index $index"
                 break
         fi
  done  
  echo "the max corr. val. is found for month ${M[0]} 
  in year $j as $max from pool value $index of $timesteps"
  #Select analog for Sorthern Hemisphere
  cdo seltimestep,$index -setyear,$j -setmon,${M[0]} $sic_f2 $Output_f/S.$j.${M[0]}.nc 
  #Merge NH and SH
  cdo add $Output_f/S.$j.${M[0]}.nc $Output_f/N.$j.${M[0]}.nc $Output_f/$j.${M[0]}.nc
  rm $Output_f/N.$j.${M[0]}.nc $Output_f/S.$j.${M[0]}.nc
done 
#############################################################################################
#############################################################################################

exit
