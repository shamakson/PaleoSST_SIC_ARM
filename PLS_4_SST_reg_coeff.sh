#!/bin/bash
# A shell script to compute partial least squares regression, using multiple "cdo" commands.
# CHECK:Intercept is 0 eveywhere, if the inputs are standardized

clear

echo "The script starts now!!!"

#Realization=1-50 *first loop
#Months=1-12 *Second loop

mkdir Coefficients

R_END=50

# Beginning of outer loop. For Realizations 1-50.
for i in $(seq 1 $R_END)
do
  echo "working on $i"
  #==Create a directory to store different realizations, seperately.
  mkdir $i.R_coeff
  ##Predictor (if your files are timeseries, use "cdo enlarge <gridsize> filename" to make it spatial
  pred1=Nino34/S_Nino34/enlarged_Nino34_1880-2010_R$i.nc
  pred2=DMI/S_DMI/enlarged_DMI_1880-2010_R$i.nc
  pred3=TASI/S_TASI/enlarged_TASI_1880-2010_R$i.nc
  M_END=12 #=========================================================================================
  # Beginning of inner loop. For Months 1-12.
  # In principle, We could pipe out this lines, but we can also write them individually for simplicity
  for j in $(seq 1 $M_END)
  do 
    ##Predictand
    sst=Monthly/S_Monthly/HadISST_v2_69_$j.nc
    echo "working on realization $i and month $j"
    cdo timmean $sst sst_timmean.nc
    cdo timmean $pred1 pred1_timmean.nc
    cdo sub $sst sst_timmean.nc covY.nc
    cdo sub $pred1 pred1_timmean.nc covX1.nc
    cdo mul covY.nc covX1.nc mulcovYX1.nc
    cdo timsum mulcovYX1.nc covYX1.nc
    cdo mul covX1.nc covX1.nc mulX1X1.nc
    cdo timsum mulX1X1.nc VarX1.nc
    cdo div covYX1.nc VarX1.nc $i.R_coeff/Beta_pred1_month_$j.nc
    cdo mul -invertlat $i.R_coeff/Beta_pred1_month_$j.nc $pred1 Beta_pred1_mul_X1.nc
    cdo sub -invertlat $sst Beta_pred1_mul_X1.nc Residual_1.nc
    cdo mul $i.R_coeff/Beta_pred1_month_$j.nc pred1_timmean.nc Beta_pred1_X1_timmean.nc
    #==First Least Squares performed, now to the Second by regressing Pred2 on Pred1
    echo "Partioning the variance of Pred1 and Pred2!!!!!!"
    #=========================================================================================
    cdo timmean $pred2 pred2_timmean.nc
    cdo sub $pred2 pred2_timmean.nc covX2.nc
    cdo mul covX1.nc covX2.nc mulcovX1X2.nc
    cdo timsum mulcovX1X2.nc covX1X2.nc
    cdo mul covX2.nc covX2.nc mulX2X2.nc
    cdo timsum mulX2X2.nc VarX2.nc
    cdo div covX1X2.nc VarX2.nc $i.R_coeff/Beta_x1_on_x2_$j.nc
    cdo mul -invertlat $i.R_coeff/Beta_x1_on_x2_$j.nc $pred2 Beta_pred2_mul_X1.nc
    cdo sub -invertlat $pred1 Beta_pred2_mul_X1.nc Residual_2.nc
    #==Second Least Squares performed, now to the Third by regressing Pred3 on Pred1
    echo "Partioning the variance of Pred1 and Pred3!!!!!!!"
    #=========================================================================================
    cdo timmean $pred3 pred3_timmean.nc
    cdo sub $pred3 pred3_timmean.nc covX3.nc
    cdo mul covX1.nc covX3.nc mulcovX1X3.nc
    cdo timsum mulcovX1X3.nc covX1X3.nc
    cdo mul covX3.nc covX3.nc mulX3X3.nc
    cdo timsum mulX3X3.nc VarX3.nc
    cdo div covX1X3.nc VarX3.nc $i.R_coeff/Beta_x1_on_x3_$j.nc
    cdo mul -invertlat $i.R_coeff/Beta_x1_on_x3_$j.nc $pred3 Beta_pred3_mul_X1.nc
    cdo sub -invertlat $pred3 Beta_pred3_mul_X1.nc Residual_3.nc
    echo "Variance Partioned, now regressing Residuals on each other!!!!!" 
    #=========================================================================================
    cdo timmean Residual_1.nc Residual_1_timmean.nc
    cdo sub Residual_1.nc Residual_1_timmean.nc Cov_Res_1.nc
    cdo timmean Residual_2.nc Residual_2_timmean.nc
    cdo sub Residual_2.nc Residual_2_timmean.nc Cov_Res_2.nc
    cdo mul Cov_Res_2.nc Cov_Res_2.nc mul_Res2_Res2.nc
    cdo timsum mul_Res2_Res2.nc Var_Res2.nc
    cdo mul Cov_Res_1.nc Cov_Res_2.nc mulcovRes_1_2.nc
    cdo timsum mulcovRes_1_2.nc cov_Res_1_2.nc
    cdo div cov_Res_1_2.nc Var_Res2.nc $i.R_coeff/Beta_pred2_month_$j.nc
    #=========================================================================================
    cdo mul $i.R_coeff/Beta_pred2_month_$j.nc pred2_timmean.nc Beta_pred2_mul_X2.nc
    #=========================================================================================
    cdo timmean Residual_3.nc Residual_3_timmean.nc
    cdo sub Residual_3.nc Residual_3_timmean.nc Cov_Res_3.nc
    cdo mul Cov_Res_3.nc Cov_Res_3.nc mul_Res3_Res3.nc
    cdo timsum mul_Res3_Res3.nc Var_Res3.nc
    cdo mul Cov_Res_1.nc Cov_Res_3.nc mulcovRes_1_3.nc
    cdo timsum mulcovRes_1_3.nc cov_Res_1_3.nc
    cdo div cov_Res_1_3.nc Var_Res3.nc $i.R_coeff/Beta_pred3_month_$j.nc  #=========================================================================================
    cdo mul $i.R_coeff/Beta_pred3_month_$j.nc pred3_timmean.nc Beta_pred3_mul_X3.nc  #=========================================================================================                 #=========================================================================================
    #=========================================================================================
    cdo add -invertlat Beta_pred1_X1_timmean.nc Beta_pred2_mul_X2.nc Beta_pred_X1_X2.nc
    cdo add Beta_pred_X1_X2.nc Beta_pred3_mul_X3.nc Beta_pred_X1_X2_X3.nc
    cdo sub -invertlat sst_timmean.nc Beta_pred_X1_X2_X3.nc $i.R_coeff/$j._intercept_sst.nc
    rm $i.R_coeff/Beta_x1*
  done
 echo ""
 echo "!!!!" 
 rm *.nc
done 

mv *.R_coeff Coefficients/


#=========================================================================================
#=========================================================================================

exit 0
