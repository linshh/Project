;;;画ERA 的0-12小时forecast月平均的通量数据的趋势
;;
;;
;;                                         lnshuheng 2020.03.10
;**********************************************************
function  rc_test(ssta_rc)
begin
  tval = onedtond(ssta_rc@tval , dimsizes(ssta_rc))
   df   = onedtond(ssta_rc@nptxy, dimsizes(ssta_rc)) - 2
   b = tval    ; b must be same size as tval (and df)
   b = 0.5
   prob = betainc(df/(df+tval^2),df/2.0,b)    ; prob(nlat,nlon)
   copy_VarCoords(ssta_rc, prob)

return prob
end
;;;;

function  wgt_annual(total_month,season)
begin

    if season.eq."MAM"
       h = 3
    else if season.eq."JJA"
        h=6
       else if season.eq."SON"
          h = 9
      else 
          h = 0
       end if 
    end if
    end if
   print(h)
    weight1 = ispan(h,h+2,1)*1.0
    weight1 = (weight1-h+0.5)/3.0

    weight2 = ispan(h,h+2,1)*1.0
    weight2 = (h-weight2+2.5)/3.0
    
    dim = dimsizes(total_month)
    printVarSummary(total_month)



    weight1_3d = conform_dims(dimsizes(total_month(1:3,:,:)), weight1, 0)
    weight2_3d = conform_dims(dimsizes(total_month(1:3,:,:)), weight2, 0)


    total_annual_test = new((/dim(0)/12,dim(1),dim(2)/),"float")
    total_annual_test@_FillValue = default_fillvalue("float")
    printVarSummary(total_annual_test)

    h = h-1 ;;;考虑到数组index要减1  

    if season.ne."DJF" then
        do i =0,32,1
          total_annual_test(i+1,:,:) =  dim_sum_n((total_month(h+i*12:h+2+i*12,:,:)*weight1_3d),0) + dim_sum_n(total_month(h+(i+1)*12:h+2+(i+1)*12,:,:)*weight2_3d,0) + \
                                  dim_sum_n(total_month(h+3+i*12:(i+1)*12-1,:,:),0) +  dim_sum_n(total_month((i+1)*12:h-1+(i+1)*12,:,:),0)
        end do    
    end if 

    if season.eq."DJF" then
      ;;;12月的情况为
      DT12 = total_annual_test
      DT1 = DT12
      DT2 = DT12
      do i =0,31,1
          DT12(i+1,:,:) = 0.5*total_month(i*12+11,:,:) + 0.5*total_month((i+1)*12+11,:,:) + dim_sum_n(total_month((i+1)*12:(i+1)*12+10,:,:),0)
          DT1(i+1,:,:) = 0.5*total_month((i+1)*12,:,:) + 0.5*total_month((i+2)*12,:,:) + dim_sum_n(total_month((i+1)*12+1:(i+1)*12+11,:,:),0)
          DT2(i+1,:,:) = 0.5*total_month((i+1)*12+1,:,:) + 0.5*total_month((i+2)*12+1,:,:) + dim_sum_n(total_month((i+1)*12+2:(i+1)*12+11,:,:),0) + total_month((i+2)*12,:,:)
          total_annual_test(i+1,:,:) = (DT12(i+1,:,:)+DT1(i+1,:,:)+DT2(i+1,:,:))/3.0
      end do    
     total_annual_test(33,:,:) =  default_fillvalue("float")
    end if
    

return total_annual_test
end    
;;**************************************************************
;;;main program
;;***************************************************************
begin
 ;;;time span
    startmon =198001
    endmon = 201312

    startyear_r = str_split_by_length(startmon, 4)  ;; 将时间string分解成年和月
    endyear_r = str_split_by_length(endmon, 4 )

    startyear = stringtoint(startyear_r(0))
    endyear = stringtoint(endyear_r(0))

    yearnum = endyear - startyear +1
  ;;
;;;region
   ; lat1 = -5
   ; lat2 = 45
   ; lon1 = 90
   ; lon2 = 160
   lat1 = -10
   lat2 = 20
   lon1 = 100
   lon2 = 160
;;;;

 season = "SON"

;;;读入HadiSST海温数据
    diri="/home/ys17-19/lsh/data/sst/"
    fils1=systemfunc("ls "+diri+"HadISST_sst.nc")
    f1=addfile(fils1, "r")
    date:=cd_calendar(f1->time, 1)

    timeind:=ind(date.le.201312.and.date.ge.198001)

    sst=lonFlip(f1->sst(timeind,:,:))
    printVarSummary(sst)

    ssta=(/rmMonAnnCycTLL(sst)/)
    copy_VarCoords(sst, ssta)

    ssta_annual = month_to_season(ssta(:,{lat1:lat2},{lon1:lon2}), season)
    ssta_annual =(/dtrend_msg_n(ispan(1,yearnum,1),ssta_annual,False,True,0)/)

    ;;;sst 倾向值
     dsst = center_finite_diff_n(ssta, 1, False, 0, 0) 
     copy_VarCoords(ssta, dsst)
     dsst_annual = month_to_season(dsst(:,{lat1:lat2},{lon1:lon2}), season)
     dsst_annual =(/dtrend_msg_n(ispan(1,yearnum,1),dsst_annual,False,True,0)/)

    ;;;
    delete(date)
    delete(timeind)
;;;

   
;;;read soda data and then calculate ocean dynamic : bar(v*σT)， bar(w*σT)，bar denotes 
;;;averaged in mixed layer
    
     
    f2=addfile("/home/yangsong3/data-observation/SODA/3.4.2/soda3.4.2_u_mn_1980-2015_chazhi.nc", "r")   
    f3=addfile("/home/yangsong3/data-observation/SODA/3.4.2/soda3.4.2_v_mn_1980-2015_chazhi.nc", "r")   
    f4=addfile("/home/yangsong3/data-observation/SODA/3.4.2/soda3.4.2_wt_mn_1980-2015_chazhi.nc", "r")   
    f5=addfile("/home/yangsong3/data-observation/SODA/3.4.2/soda3.4.2_temp_mn_1980-2015_chazhi.nc", "r")
    f6=addfile("/home/ys17-19/lsh/Project/SCS-rain/SODA3.4.2_mld_density_criterion_0.8.nc", "r") 
    


    indyear = (2013-1980+1)*12-1
    u_r = f2->u(0:indyear,{0:330},{lat1:lat2},{lon1:lon2})
    v_r = f3->v(0:indyear,{0:330},{lat1:lat2},{lon1:lon2})
    wt_r = f4->wt(0:indyear,{0:330},{lat1:lat2},{lon1:lon2})
    T_r = f5->temp(0:indyear,{0:330},{lat1:lat2},{lon1:lon2})
    mlt = f6->mld(0:indyear,{lat1:lat2},{lon1:lon2})
    
    u = tofloat(u_r)
    v = tofloat(v_r)
    wt = tofloat(wt_r)
    T = tofloat(T_r)
 
   copy_VarCoords(u_r, u) 
   copy_VarCoords(v_r, v)
   copy_VarCoords(wt_r, wt)
   copy_VarCoords(T_r, T)


    delete(u_r)
    delete(v_r)
    delete(wt_r)
    delete(T_r)


 
    ;;;calculate Horizontal and Vertical advction

     
    ;;;;垂直积分平均，在混合层内进行
 

 
     z = u&depth 
    ; dz_4d = conform_dims(dimsizes(u), dz, (/1,2,3/))
      dz_4d = new(dimsizes(u),float)
      do i = 0,dimsizes(mlt&time)-1
        dz_4d(i,:,:,:) = dpres_plevel(z, mlt(i,:,:), 0, 0)
      end do 
    ;;;1混合层平均的
     T_mean = T(:,1,:,:)
     u_mean = u(:,1,:,:)
     v_mean = v(:,1,:,:)

     T_mean = dim_sum_n_Wrap(T*dz_4d,1)/dim_sum_n_Wrap(dz_4d, 1)
     u_mean = dim_sum_n_Wrap(u*dz_4d,1)/dim_sum_n_Wrap(dz_4d, 1)
     v_mean = dim_sum_n_Wrap(v*dz_4d,1)/dim_sum_n_Wrap(dz_4d, 1)

    ;;;

    gradLatLon  = grad_latlon_cfd (T_mean, T_mean&lat, T_mean&lon, True, False)
                             
    T_grad_lat  = gradLatLon[0]    ; for clarity; explicitly extract variables from returned 'list' 
    T_grad_lon  = gradLatLon[1]
    delete(gradLatLon)
    
    hadv = u_mean
    hadv = u_mean*T_grad_lon + v_mean*T_grad_lat
    hadv = (/-1*hadv/)

    ;;;温度的梯度
    T_mean_annual = month_to_season(T_mean, season)

    dT = center_finite_diff_n(T_mean_annual, 1, False, 0, 0) 
    printVarSummary(dT)



    ;;;垂直项


     ;;;将wt进行垂直方向差值，为了得到更加精确的结果
        

      ;;;mlt变化引起温度的变化，可以不考虑
          x1 = 0
          x2 = 15
          y1 = 110
          y2 = 155
          mlt_scs = mlt(:,{x1:x2},{y1:y2})
          printVarSummary(mlt_scs)
          
        ;   do i = 0,dimsizes(mlt&time)-1
        ;   mlt_scs(i,:,:) = where(ismissing(mlt_scs(i,:,:)),dim_avg_n_Wrap(mlt_scs, 0), mlt_scs(i,:,:))
        ; end do 
        mlt_scs = where(ismissing(mlt_scs),avg(mlt_scs), mlt_scs) 
          
          printMinMax(mlt_scs, 1)
          dim  =dimsizes(mlt_scs)


    f1 = addfile("/home/ys17-19/lsh/Project/SCS-rain/SODA3.4.2_wt_T_in_MLD_density_defined_0.8.nc", "r")
       
     wt_mlt = f1->wt_mlt
     T_mlt = f1->T_mlt


     vadv  = mlt_scs
     vadv = wt_mlt*(T_mean(:,{x1:x2},{y1:y2}) - T_mlt)/mlt_scs   ;;;k/s

    vadv = (/-1*vadv/)
    printVarSummary(vadv)

    ; ;;;convert to units degree ℃/year
    ;   hadv =365*86400*hadv
    ;   vadv =365*86400*vadv
    ; ;;;
    
    ;;;convert to units degree ℃/month
      hadv =30*86400*hadv
      vadv =30*86400*vadv
    ;;;

    hadv_mean = hadv
    vadv_mean  = vadv
   
    copy_VarCoords(u(:,1,:,:), hadv_mean)
    copy_VarCoords(u(:,1,{x1:x2},{y1:y2}), vadv_mean)

    hadv_mean&lat@units = "degrees_north"
    hadv_mean&lon@units = "degrees_east"
    
    vadv_mean&lat@units = "degrees_north"
    vadv_mean&lon@units = "degrees_east"
 


    ;;;年平均
       ; hadv_mean = (/rmMonAnnCycTLL(hadv_mean)/)
       ; vadv_mean = (/rmMonAnnCycTLL(vadv_mean)/)

       hadv_mean_annual = month_to_season(hadv_mean, season)
       vadv_mean_annual = month_to_season(vadv_mean, season)
       
       hadv_mean_annual = (/wgt_annual(hadv_mean,season)/)
       vadv_mean_annual = (/wgt_annual(vadv_mean,season)/)



       total_ocean_annual = vadv_mean_annual
       total_ocean_annual = hadv_mean_annual(:,{x1:x2},{y1:y2}) + vadv_mean_annual

       total_ocean_annual&lat@units = "degrees_north"
       total_ocean_annual&lon@units = "degrees_east"
 

    ;;;

;;;read NCEP-NCAR heat flux data
    
 
    fils3 = "/home/ys17-19/lsh/Project/SCS-rain/ERAI-heatflux-1degree.nc"
    f3 = addfile(fils3, "r")

    date:=cd_calendar(f3->time, 1)

    timeind:=ind(date.le.201312.and.date.ge.198001)
  
    
    lhtfl = f3->lhtfl(timeind,{lat1:lat2},{lon1:lon2})
       ; lhtfl = f3->lhtfl(timeind,:,:)
    shtfl = f3->shtfl(timeind,{lat1:lat2},{lon1:lon2})
    nswrs = f3->nswrs(timeind,{lat1:lat2},{lon1:lon2})
    nlwrs = f3->nlwrs(timeind,{lat1:lat2},{lon1:lon2})

    lhtfl = (/lhtfl/(24*3600)/)  ;;units j/m^2 (12hour) to w/m^2
    shtfl = (/shtfl/(24*3600)/)  ;;units j/m^2 (12hour) to w/m^2
    nswrs = (/nswrs/(24*3600)/)  ;;units j/m^2 (12hour) to w/m^2
    nlwrs = (/nlwrs/(24*3600)/)  ;;units j/m^2 (12hour) to w/m^2
    
    printVarSummary(lhtfl)
    printVarSummary(shtfl)


    ;;;nswrs_pen 
     R = 0.58
     L1 = 0.35
     L2 = 23
     nswrs_pen = nswrs
     nswrs_pen =  nswrs*(R*exp(-1*mlt/L1)+ (1-R)*exp(-1*mlt/L2))
    ;;;

    ;;;convert to units degree ℃/month
      density = 1025  ;;kg/m3
      cp  = 3850         ;;j/kg℃
      coef  = mlt*density*cp                                  
   
      
      lhtfl = 30*86400*lhtfl
      shtfl = 30*86400*shtfl
      nswrs = 30*86400*nswrs
      nlwrs = 30*86400*nlwrs
      nswrs_pen = 30*86400*nswrs_pen  
    ;;;;


      
    ;;;
    ; lhtfl  = (/rmMonAnnCycTLL(lhtfl)/)
    ; shtfl  = (/rmMonAnnCycTLL(shtfl)/)
    ; nswrs  = (/rmMonAnnCycTLL(nswrs)/)
    ; nlwrs  = (/rmMonAnnCycTLL(nlwrs)/)
    ; nswrs_pen  = (/rmMonAnnCycTLL(nswrs_pen)/)

    total = lhtfl
    total = lhtfl + shtfl  + nswrs + nlwrs - nswrs_pen


    total = (/total/coef/)

    ;;;;;
    lhtfl = (/lhtfl/coef/)
    shtfl = (/shtfl/coef/)
    nswrs= (/nswrs/coef/)
    nlwrs = (/nlwrs/coef/)


    lhtfl_annual = month_to_season(lhtfl, season)
    shtfl_annual = month_to_season(shtfl, season)
    nswrs_annual = month_to_season(nswrs, season)
    nlwrs_annual = month_to_season(nlwrs, season)
    nswrs_pen_annual = month_to_season(nswrs_pen, season)

    lhtfl_annual = wgt_annual(lhtfl,season)
    shtfl_annual = wgt_annual(shtfl,season)
    nswrs_annual = wgt_annual(nswrs,season)
    nlwrs_annual = wgt_annual(nlwrs,season)
    nswrs_pen_annual = wgt_annual(nswrs_pen,season)


    total_annual = lhtfl_annual
    total_annual  = month_to_season(total, season)
    printVarSummary(lhtfl_annual)

    total_annual = (/wgt_annual(total,season)/)
    printVarSummary(total_annual)
    total_annual = (/dT/)


       ; printMinMax(total_ocean_annual, 1)
       ; printMinMax(total_annual, 1)
       ; printMinMax(hadv_mean_annual, 1)
       ; printMinMax(vadv_mean_annual, 1)

    total_ocean_mean = dim_avg_n_Wrap(total_ocean_annual, 0)
 ; total_mean = dim_avg_n_Wrap(total_annual, 0)
 ; total = total_ocean_mean + total_mean

;;;




print("*******开始计算趋势系数*****************")
; ;;;calculate correlation coef
;       lhtfl_annual = lhtfl_annual/(365*86400)
;       shtfl_annual = shtfl_annual/(365*86400)
;       nswrs_annual = nswrs_annual/(365*86400)
;       nlwrs_annual = nlwrs_annual/(365*86400)
; ;;;

;;;
    ;;;大气
    r_lh =  regCoef_n(ispan(1, yearnum, 1), lhtfl_annual, 0, 0)
    r_sh   = regCoef_n(ispan(1, yearnum, 1), shtfl_annual, 0, 0)

    r_ns =  regCoef_n(ispan(1, yearnum, 1), nswrs_annual, 0, 0)
    r_nl   = regCoef_n(ispan(1, yearnum, 1), nlwrs_annual, 0, 0)
    r_total = regCoef_n(ispan(1, yearnum, 1), total_annual, 0, 0)

    copy_VarCoords(ssta_annual(0,:,:), r_lh)
    copy_VarCoords(ssta_annual(0,:,:), r_sh)
    copy_VarCoords(ssta_annual(0,:,:), r_ns)
    copy_VarCoords(ssta_annual(0,:,:), r_nl)
    copy_VarCoords(ssta_annual(0,:,:), r_total)

    ;;;

    ;;;海洋
    r_hadv =  regCoef_n(ispan(1, yearnum, 1), hadv_mean_annual, 0, 0)
    r_vadv   = regCoef_n(ispan(1, yearnum, 1), vadv_mean_annual, 0, 0)
    r_total_ocean   = regCoef_n(ispan(1, yearnum, 1), total_ocean_annual, 0, 0)    

    copy_VarCoords(hadv_mean(0,:,:), r_hadv)
    copy_VarCoords(vadv_mean(0,:,:), r_vadv)
    copy_VarCoords(vadv_mean(0,:,:), r_total_ocean)
    ;;;;;

    r_lh = (/r_lh*yearnum/)
    r_sh = (/r_sh*yearnum/)
    r_ns = (/r_ns*yearnum/)
    r_nl = (/r_nl*yearnum/)
    r_total = (/r_total*yearnum/)
    
    r_hadv = (/r_hadv*yearnum/)
    r_vadv = (/r_vadv*yearnum/)
    r_total_ocean = (/r_total_ocean*yearnum/)

    ; r_total_mean = avg(dim_avg_n_Wrap(r_total({0:15},{110:155}), 1))
    ; r_total_ocean_mean = avg(dim_avg_n_Wrap(r_total_ocean({0:15},{110:155}), 1))
    
    r_lh_scs =  avg(dim_avg_n_Wrap(r_lh({0:15},{110:155}), 1))
    r_sh_scs =  avg(dim_avg_n_Wrap(r_sh({0:15},{110:155}), 1))
    r_ns_scs =  avg(dim_avg_n_Wrap(r_ns({0:15},{110:155}), 1))
    r_nl_scs =  avg(dim_avg_n_Wrap(r_nl({0:15},{110:155}), 1))

    ; print(r_lh_scs)
    ; print(r_sh_scs)
    ; print(r_ns_scs)
    ; print(r_nl_scs)
    ; exit() 





;;;;

print("*******显著性检验*****************")

;;;t test 
   prob_lh= rc_test(r_lh)
   prob_sh= rc_test(r_sh)
   prob_nl= rc_test(r_nl)
   prob_ns= rc_test(r_ns)
   prob_total= rc_test(r_total)

   prob_hadv= rc_test(r_hadv)
   prob_vadv= rc_test(r_vadv)
   prob_total_ocean = rc_test(r_total_ocean)
   


  copy_VarCoords(r_lh, prob_lh)
  copy_VarCoords(r_lh, prob_sh)
  copy_VarCoords(r_lh, prob_nl)
  copy_VarCoords(r_lh, prob_ns)
  copy_VarCoords(r_total, prob_total)

  copy_VarCoords(r_hadv, prob_hadv)
  copy_VarCoords(r_vadv, prob_vadv)
  copy_VarCoords(r_total_ocean, prob_total_ocean)
  
  
 ;  printVarSummary(prob_p1)
 ; prob_p1 = where(prob_p1.eq.0, 2, prob_p1)
 ; prob_p2 = where(prob_p2.eq.0, 2, prob_p2)
 ; prob_p3 = where(prob_p3.eq.0, 2, prob_p3)
 ; prob_p4 = where(prob_p4.eq.0, 2, prob_p4)
 ; prob_p5 = where(prob_p5.eq.0, 2, prob_p5)
 ; prob_p6 = where(prob_p6.eq.0, 2, prob_p6)
 ; prob_p7 = where(prob_p7.eq.0, 2, prob_p7)
 ; prob_p8 = where(prob_p8.eq.0, 2, prob_p8)
;;;;


print("*********开始画图********")

    
;;**************************************************************
;画图
;;***************************************************************
  ; wks   = gsn_open_wks("pdf", "所有通量的线性趋势-ERAI-newthod-mld_0.8-"+season+"wgt-mld")
  wks   = gsn_open_wks("pdf", "混合层温度变化的季节趋势"+season)

  res=True
  res@gsnFrame=False
  res@gsnDraw=False
  res@gsnLeftStringFontHeightF=20.0
  res@cnFillPalette="BlRe"
  res@cnFillOn=True
  res@cnLinesOn=False
  res@gsnAddCyclic = False

  res@cnLineLabelsOn=False
  res@lbLabelBarOn= True
  res@lbLabelStride=2
  res@lbOrientation="Vertical"
  res@mpLimitMode           = "LatLon"
  res@mpFillDrawOrder = "PostDraw"
  ; res@mpMinLatF             = -5
  ; res@mpMaxLatF             = 45
  ; res@mpMinLonF             =90
  ; res@mpMaxLonF             = 160
   lat1 = 0
   lat2 = 15
   lon1 = 110
   lon2 = 155

  res@mpMinLatF             = lat1
  res@mpMaxLatF             = lat2
  res@mpMinLonF             =lon1
  res@mpMaxLonF             = lon2

  res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0

  res@tmXTOn=False
  res@tmYROn=False
  res@tmXBOn=True
  res@tmYROn=False
  res@tmXBMode="Explicit"
  res@tmYLMode="Explicit"

  res@tmXBLabelFontHeightF=0.015
  res@tmYLLabelFontHeightF=0.015
  res@tmXBMajorThicknessF=3.0
  res@tmYLMajorThicknessF=3.0
  res@tmBorderThicknessF=4.0

  ; res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  ; res@cnMinLevelValF       =   -12.0
  ; res@cnMaxLevelValF       =   12.0
  ; res@cnLevelSpacingF      =  1.0

  res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  res@cnMinLevelValF       =   -.12
  res@cnMaxLevelValF       =   .12
  res@cnLevelSpacingF      =  0.01

  ; res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour level
  ; res@cnMinLevelValF       =   -120
  ; res@cnMaxLevelValF       =   120
    ; res@cnLevelSpacingF      =  10
   

  plot = new(8,graphic)

  res@gsnLeftString = "Net Heat Flux"
   
  plot(0) = gsn_csm_contour_map(wks, r_total({lat1:lat2},{lon1:lon2}), res)
  
  res@gsnLeftString = "Ocean advction"
     res@cnMinLevelValF       =   -12.0
    res@cnMaxLevelValF       =   12.0
    res@cnLevelSpacingF      =  1.0
  plot(1) = gsn_csm_contour_map(wks, r_total_ocean({lat1:lat2},{lon1:lon2}), res)
  res@gsnLeftString = "Ocean horizonal advction"
    ;  res@cnMinLevelValF       =   -12.0
    ; res@cnMaxLevelValF       =   20.0
    ; res@cnLevelSpacingF      =  2.0
  plot(2) = gsn_csm_contour_map(wks, r_hadv({lat1:lat2},{lon1:lon2}), res) 
  res@gsnLeftString = "Ocean Vertical advction"
  plot(3) = gsn_csm_contour_map(wks, r_vadv, res)

 res@cnMinLevelValF       =   -20.0
    res@cnMaxLevelValF       =   20.0
    res@cnLevelSpacingF      =  2.0

  res@gsnLeftString = "Latent heat flux"
  plot(4) = gsn_csm_contour_map(wks, r_lh({lat1:lat2},{lon1:lon2}), res)
  res@gsnLeftString = "Sensible heat flux"
   res@cnMinLevelValF       =   -4.0
    res@cnMaxLevelValF       =   4.0
    res@cnLevelSpacingF      =  .5
  plot(5) = gsn_csm_contour_map(wks, r_sh({lat1:lat2},{lon1:lon2}), res)
  res@gsnLeftString = "Net Longwave radiation"
    res@cnMinLevelValF       =   -10.0
    res@cnMaxLevelValF       =   10.0
    res@cnLevelSpacingF      =  1.0
  plot(6) = gsn_csm_contour_map(wks, r_nl({lat1:lat2},{lon1:lon2}), res)
  res@gsnLeftString = "Net Shortwave radiation"
    res@cnMinLevelValF       =   -30.0
    res@cnMaxLevelValF       =   30.0
    res@cnLevelSpacingF      =  2.0
  plot(7) = gsn_csm_contour_map(wks, r_ns({lat1:lat2},{lon1:lon2}), res)



  


  ;;;添加赤道直线
    pgx=ispan(30,390,10)
    pgy=new(dimsizes(pgx),typeof(pgx))
    pgy=0

    pgres=True
    pgres@gsLineColor="black"
    pgres@gsLineThicknessF=1.0
    pgres@gsLineDashPattern=1
  
    str = "" + ispan(1,8,1)

   do i = 0,7
     plot@$str(i)$ = gsn_add_polyline(wks, plot(i), pgx, pgy, pgres)
   end do


  ;;;添加indo-pacific warm pool
    ; ;;添加区域
   ;;warm pool
   pgres@gsLineThicknessF=2.0
   pgres@gsLineDashPattern=0
   str3=unique_string("dum3")
   str4=unique_string("dum4")
   
   ;;;画box
   lat1 = 0
   lat2 = 15
   lon1 = 110
   lon2 = 155

   pgx_pool=(/lon1,lon2,lon2,lon1,lon1/)
   pgy_pool=(/lat1,lat1,lat2,lat2,lat1/)
   ;;;
   str2 = "0" + ispan(1,8,1)
   do i = 0,7
     plot@$str2(i)$ = gsn_add_polyline(wks, plot(i), pgx_pool, pgy_pool, pgres)
   end do

    ;;;打点
    res_pro=True
    res_pro@gsnDraw=False
    res_pro@gsnFrame=False
    res_pro@cnLevelSelectionMode = "ExplicitLevels"
    res_pro@cnLinesOn=False
    res_pro@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
    res_pro@cnMinLevelValF      = 0.00        ; set min contour level
    res_pro@cnMaxLevelValF      = 1.00        ; set max contour level
    res_pro@cnLevelSpacingF     = 0.1      ; set contour spacing

    res_pro@cnLineLabelsOn=False
    res_pro@tmYRMode = "Automatic"
    res_pro@cnInfoLabelOn=False

    iplot=new(8,graphic)

    iplot(0) = gsn_csm_contour(wks,prob_total({lat1:lat2},{lon1:lon2}),res_pro)
    iplot(1) = gsn_csm_contour(wks,prob_total_ocean({lat1:lat2},{lon1:lon2}) ,res_pro)
    iplot(2) = gsn_csm_contour(wks,prob_hadv({lat1:lat2},{lon1:lon2}),res_pro)
    iplot(3) = gsn_csm_contour(wks,prob_vadv,res_pro)
    iplot(4) = gsn_csm_contour(wks,prob_lh({lat1:lat2},{lon1:lon2}),res_pro)
    iplot(5) = gsn_csm_contour(wks,prob_sh({lat1:lat2},{lon1:lon2}),res_pro)
    iplot(6) = gsn_csm_contour(wks,prob_nl({lat1:lat2},{lon1:lon2}),res_pro)
    iplot(7) = gsn_csm_contour(wks,prob_ns({lat1:lat2},{lon1:lon2}),res_pro)

 

    

    opt                      = True
    opt@gsnShadeFillType     = "pattern"
    opt@gsnShadeMid     = 6         ; stipple
    ; opt@gsnShadeFillDotSizeF =  0.0025
    ; opt@gsnShadeHigh   = "green"
    opt@gsnShadeFillScaleF   = 0.5         ; add extra density ,越大越係數


    do i = 0,7
     iplot(i) = gsn_contour_shade(iplot(i) , 0,0.1,opt)
    end do

    ;;;  
    do i = 0,7
      overlay(plot(i), iplot(i))
    end do 

  pres = True
  ; pres@gsnPanelLabelBar  = True
  pres@gsnPanelFigureStrings = (/"a","b","c","d","e","f","g","h"/)

  gsn_panel(wks, plot, (/4,2/), pres)
 


end