
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

undef("level_mean")
function level_mean(msf_time)   ;;;;select 850hpa-200hpa 
begin
; msf_time=(/msf_time/10^9/)
plev=msf_time&level
psfc=conform_dims((/dimsizes(msf_time&time),dimsizes(msf_time&lon)/), 1013.0, 0)
ptop=min(plev)
dp   = dpres_plevel_Wrap(plev, psfc, ptop, 0)  ; dp(30)
; dp=(/50/)
msfdp=msf_time(level|:,time|:,lon|:)*dp
copy_VarCoords(msf_time(level|:,time|:,lon|:), msfdp)

msf_mean=dim_sum_n_Wrap(msfdp, 0)/dim_sum_n_Wrap(dp, 0)
copy_VarCoords(msf_time(time|:,lon|:,level|1), msf_mean)
return(msf_mean)
end
;************************************************
; 画20cr,ncep,era的msf的趋势
;************************************************
begin
LeftString="amip"
title="EC-EARTH"

    diri="/mnt/f/share/CMIP5/msf_AMIP/"
    fils1=systemfunc("ls "+diri+"msf_time_"+title+"_amip_r1i1p1_197901-200812.nc")
    ; fils1=systemfunc("ls "+diri+"/MERRA/MERRA/msf_time_MERRA_global.nc")
    ; fils1=systemfunc("ls "+diri+"MRE/msf_time_mre_global.nc")
    year1=1979
    year2=2008
    yearend=200812
    f1=addfile(fils1, "r")
    date=cd_calendar(f1->time, 1)
    level=f1->level
    timeind=ind(date.ge.197901.and.date.le.200812)
    levind1=ind(f1->level.eq.400)
    levind2=ind(f1->level.eq.600)
    levind3=ind(level.ge.400.and.f1->level.le.600)
    levind=ind(f1->level.eq.500)
    msf_time_20cr_r=f1->msf_time(:,:,timeind)
    msf_time_20cr_f=lonPivot(msf_time_20cr_r(time|:,level|:,lon|:), 30)
    
    
    msf_time_20cr=msf_time_20cr_f(level|:,lon|:,time|:)
    msf_time_20cr=(/msf_time_20cr/10^9/)
     
    delete(msf_time_20cr&time)
    msf_time_20cr&time=date(timeind)
    msf_time_20cr&level@units="hpa"
    delete(fils1)
    delete(f1)
    delete(date)
    delete(timeind)
;;;
if LeftString.eq."MERRA"  then
  msf_clm_20cr=dim_avg_n_Wrap(msf_time_20cr(time|:,level|:,lon|:), 0)
end if
;;;选择冬季
msf_clm_20cr=dim_avg_n_Wrap(month_to_season(msf_time_20cr(time|:,level|:,lon|:),"DJF"), 0)
;;;;;
    ;;;先得到秋季和冬季eninio年的沃克环流情况SONDJF
    msf_djf=month_to_season(msf_time_20cr(time|:,level|:,lon|:), "DJF")

    msf_djf&time=ispan(year1,year2,1)  ;;;因为这里第一个是1958 1月和2月的平均，第二个是195812,195901,195902的平均
    ;;注意点
    msf_djf(0:dimsizes(msf_djf&time)-2,:,:)=(/msf_djf(1:,:,:)/)
    msf_djf(dimsizes(msf_djf&time)-1,:,:)=(/msf_time_20cr(:,:,{yearend})/)
    printVarSummary(msf_djf)

   ; msf_djf=(/month_to_season(msf_time_20cr(time|:,level|:,lon|:), "JJA")/)
;;;

;;;计算趋势 
  msf_trend=regCoef_n(ispan(1, 30, 1), msf_djf, 0, 0)
  copy_VarCoords(msf_djf(1,:,:),msf_trend)
;;;  

    prob1=rc_test(msf_trend)
     msf_trend&level@units="hpa"
     prob1&level@units="hpa"
    printVarSummary(prob1)
 ;;;计算差值



;************************************************
; 画图气候态
;************************************************
 wks=gsn_open_wks("pdf", "/mnt/f/share/era/data/AMIP资料DJF的趋势")
    res = True
    res@gsnDraw=False
    res@gsnFrame=False
    res@gsnLeftString=title
   
    res@gsnMaximize=False

    res@cnFillPalette="BlueWhiteOrangeRed"
    res@cnLinesOn=False
    res@cnLevelSelectionMode ="ManualLevels"
    res@cnMinLevelValF = -0.09
    res@cnMaxLevelValF = 0.09
    ; res@cnLevelSpacingF = 0.01
    res@cnFillOn = True 

    res@cnLineLabelsOn=False
    res@cnLineLabelInterval=2
    res@cnMonoFillScale=True
    res@cnInfoLabelOn=False


    res@lbLabelBarOn=True
    ; res@cnLineColors=(/0,0,0,0,0,0,18,18,18,18,18,18/)
    res@tmYRMode="Automatic"
    res@tmXTOn=False
    res@tmYROn=False
    res@tmXBMode="Explicit"

    res@tmXBValues=(/30,90,150,210,270,330,387.5/)
    res@tmXBLabels=(/"30~S~o~N~E","90~S~o~N~E","150~S~o~N~E","150~S~o~N~W"\
                    ,"90~S~o~N~W","30~S~o~N~W","30~S~o~N~E"/)

    res@tmXBMinorOn=True
    res@tmXBMinorValues=ispan(30,390,10)
     
    res@tiYAxisString=""
    res@vpHeightF=0.3
    res@vpWidthF=0.7
   
      ; plot=gsn_csm_pres_hgt(wks, msf_diff(:,:), res)
    plot=gsn_csm_pres_hgt(wks, msf_trend(:,:), res)

 

    res@cnLevelSelectionMode ="ManualLevels"
    res@cnMinLevelValF = -6
    res@cnMaxLevelValF = 6
    res@cnLinesOn=True
    res@cnFillOn=False
    plot1=gsn_csm_pres_hgt(wks,msf_clm_20cr(:,:),res)


    res@cnLevelSelectionMode ="ExplicitLevels"
    res@cnLevels=(/-0.5/)

    res@cnFillOn=False
    res@cnMonoLineColor=True
    res@cnLineColor="blue"
    res@cnLineDashPattern=0
    res@cnLineThicknessF =4.0

   plot2=gsn_csm_pres_hgt(wks,msf_clm_20cr(:,{31:180}),res)
    res@cnLineColor="black"
    res@cnLineDashPattern=0
     res@cnLevels=(/0/)
   plot3=gsn_csm_pres_hgt(wks,msf_clm_20cr(:,{120:}),res)

   overlay(plot, plot1)
   overlay(plot, plot2)
   overlay(plot, plot3)
;;;打点
  res_pro=True
  res_pro@gsnDraw=False
  res_pro@gsnFrame=False
  res_pro@cnLevelSelectionMode = "ExplicitLevels"
  res_pro@cnLinesOn=False
  res_pro@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
  res_pro@cnMinLevelValF      = 0.00        ; set min contour level
  res_pro@cnMaxLevelValF      = 1.00        ; set max contour level
  res_pro@cnLevelSpacingF     = 0.2       ; set contour spacing

  res_pro@cnLineLabelsOn=False
  res_pro@tmYRMode = "Automatic"
  res_pro@cnInfoLabelOn=False
  
  iplot=new(1,graphic)

  iplot(0)=gsn_csm_pres_hgt(wks,prob1,res_pro)


  opt                      = True
  opt@gsnShadeFillType     = "pattern"
  opt@gsnShadeMid     = 17         ; stipple
  ; opt@gsnShadeHigh   = "green"
  opt@gsnShadeFillScaleF   = 1.0         ; add extra density
  opt@gsnShadeFillDotSizeF = 0.0      ; make dots larger

  
  iplot= gsn_contour_shade(iplot, 0,0.2, opt)

;;;  

overlay(plot, iplot)

 ;;---Resources for the polyline  添加下垫面的陆地
      ployres                  = True          ; polyline mods desired
      ployres@gsLineThicknessF = 15.0            ; line thickness   
      ployres@gsLineColor      = "black"         ; color of lines
      ployres@gsLineDashPattern=15
 ;---Attach the polyline
      ploylevel=1000
      ploylon1=fspan(9, 30, 25)+360.0
      ploylon2=fspan(100, 149, 25)
      ploylon3=fspan(280, 315, 25)
      ploylon6=fspan(30, 39, 25)


      ploylevel1=conform_dims(dimsizes(ploylon1), ploylevel, 0)
      ploylevel2=conform_dims(dimsizes(ploylon2), ploylevel, 0)
      ploylevel3=conform_dims(dimsizes(ploylon3), ploylevel, 0)
      ploylevel6=conform_dims(dimsizes(ploylon6), ploylevel, 0)
    

    str1 = unique_string("dum1")  ; "unique_string" will return a unique                                     ; string every time it is called fro                                 ;  within a single NCL session.
    str2 = unique_string("dum2")
    str3 = unique_string("dum3")
    str31 = unique_string("dum31")
    ployres@gsLineDashPattern=0
     
    plot@$str1$= gsn_add_polyline(wks,plot,  ploylon1,ploylevel1,  ployres)

    ployres@gsLineDashPattern=16

    plot@$str2$= gsn_add_polyline(wks,plot,  ploylon2,ploylevel2,  ployres)

    ployres@gsLineDashPattern=0
    plot@$str3$= gsn_add_polyline(wks,plot,  ploylon3,ploylevel3,  ployres)
    ployres@gsLineDashPattern=0
    plot@$str31$= gsn_add_polyline(wks,plot,  ploylon6,ploylevel6,  ployres)

draw(plot)
frame(wks)
end 