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

function  sst_cold_annual(sst,timeind,year1,year2)
begin 

    ;;;先得到秋季和冬季的SONDJF海温
    sst_son=month_to_season(sst(time|:,lat|:,lon|:), "SON")
    sst_djf=month_to_season(sst(time|:,lat|:,lon|:), "DJF")
    printVarSummary(sst_son)

    sst_son&time=ispan(year1,year2,1)
    sst_djf&time=ispan(year1,year2,1)  ;;;因为这里第一个是1958 1月和2月的平均，第二个是195812,195901,195902的平均
    ;;注意点
    sst_djf(0:dimsizes(sst_djf&time)-2,:,:)=(/sst_djf(1:,:,:)/)
    sst_djf(dimsizes(sst_djf&time)-1,:,:)=(/sst(dimsizes(timeind)-1,:,:)/)
    
    ;;;
    sst_mean_annual=new((/dimsizes(timeind)/12,dimsizes(sst&lat),dimsizes(sst&lon)/),typeof(sst))
    printVarSummary(sst_mean_annual)
    ; sst_mean_annual=month_to_annual(sst_mean, 1)
     sst_mean_annual=(/sst_son(:,:,:)+sst_djf(:,:,:)/)*0.5
    delete(sst_son)
    delete(sst_djf)

    sst_mean_annual!0="time"
    sst_mean_annual!1="lat"
    sst_mean_annual!2="lon"
    sst_mean_annual&time=ispan(0,dimsizes(timeind)/12-1,1)
    sst_mean_annual&lon=sst&lon
    sst_mean_annual&lat=sst&lat
    printVarSummary(sst_mean_annual)
return sst_mean_annual
end
   
function draw_cmip_sst(xi_model,wks)
 begin
;;读入数据
    diri_output="/mnt/f/share/CMIP5/msf_history/"
  
    yearstart=197901
    yearend=200512
    
    year1=1979
    year2=2005

    if xi_model.eq."FGOALS-s2" then

    yearstart=197901
    yearend=200412

    year1=1979
    year2=2004
    end if

    fils1=systemfunc("ls /mnt/j/CMIP5/history/tos_new/"+xi_model+"/r1i1p1/tos_Omon_"+xi_model+"_historical_r1i1p1_"+"*"+".nc")
    printVarSummary(fils1)
    print("******************"+xi_model+"*********************")
    f1=addfiles(fils1, "join")
    delete(fils1)
    vNames= getfilevarnames(f1[:]) ; get variable names of all groups on file
    print(vNames)
    
    if (any(vNames.eq."LONN179_180")) then 

    lon2d=f1[:]->LONN179_180
    lat2d=f1[:]->LAT
    time=f1[:]->TIME
 
    date=cd_calendar(time, 1)
    print("******************日期*********************")
    timeind=ind(date.le.yearend.and.date.ge.yearstart)
    
    if xi_model.eq."FGOALS-s2" then
    sst_r=f1[:]->TOS(timeind,:,:)
    else
    sst_r=lonFlip(f1[:]->TOS(timeind,:,:))
    end if    
    sst_r=(/sst_r-273.15/)
    printVarSummary(sst_r)
    dNames = getvardims(f1[:]->TOS)
      delete(f1)
    print(dNames)
    sst_r!0="time"
    sst_r!1="lat"
    sst_r!2="lon"
    end if

  
    delete(vNames)
    delete(lon2d)
    delete(lat2d)
    delete(dNames)

    delete(sst_r&time)
    sst_r&time=date(timeind)
    if xi_model.eq."FGOALS-s2"  then
    sst=sst_cold_annual(sst_r(:,{50:-50},{90:300}),timeind,1979,2004)
    else 
    sst=sst_cold_annual(sst_r(:,{50:-50},{90:300}),timeind,1979,2005)
end if
    delete(sst_r)
    delete(time)
    delete(date)
    printVarSummary(sst)
 
 print("******************读入风场*********************")
    fils1=systemfunc("ls /mnt/j/CMIP5/history/ua/"+xi_model+"/r1i1p1/ua_Amon_"+xi_model+"_historical_r1i1p1_"+"*"+".nc")
    fils2=systemfunc("ls /mnt/j/CMIP5/history/va/"+xi_model+"/r1i1p1/va_Amon_"+xi_model+"_historical_r1i1p1_"+"*"+".nc")

    print(fils1)
    print(fils2)
    
    f1=addfiles(fils1, "join")
    f2=addfiles(fils2, "join")

    time=f1[:]->time    
    date=cd_calendar(time, 1)
    print("******************日期*********************")
    timeind=ind(date.le.yearend.and.date.ge.yearstart)
    print(date(timeind))
    print("读入风场")
    z0=(/1000.0/)*100.0
    levind=get1Dindex(f1[0]->plev,z0)

    uwnd=f1[:]->ua(timeind,levind,:,:)  ;;;195801-201212
    vwnd=f2[:]->va(timeind,levind,:,:)  ;;;
    delete(f1)
    delete(f2)

     ;;;interp missing value
     print("****************interp missing value*********************")
       
    ;******************************************************************
    ; use poisson_grid_fill to fill missing value
    ;******************************************************************
    nscan = 1500           ; usually *much* fewer
    eps   = 0.001            ; variable depended
    gtype = False            ; "gendat" does not generate cyclic fields
    guess = 0                ; use zonal means
    relc  = 0.6              ; standard relaxation coef
    opt   = 0
    
    poisson_grid_fill(uwnd, gtype, guess, nscan, eps, relc, opt)
    
    poisson_grid_fill(vwnd, gtype, guess, nscan, eps, relc, opt)

;;;;

     print("*****************计算趋势************************")  

    sst_rc1=regCoef_n(ispan(1,dimsizes(sst&time),1),sst(:,:,:),0,0)  
    copy_VarCoords(sst(0,:,:), sst_rc1)
    delete(sst)
    printVarSummary(sst_rc1)
    
    prob1=rc_test(sst_rc1)
    copy_VarCoords(sst_rc1, prob1)
    printVarSummary(prob1)
    
    sst_rc1=(/sst_rc1/)*10
    
    
    print("**********************画图*****************************")


    ; colormap=read_colormap_file("BlWhRe")
    ; printVarSummary(colormap)
    ; cmap=new((/18,4/),typeof(colormap))
    ; printVarSummary(colormap)
    ; cmap(0:4,:)=colormap(0:40:10,:)
    ; cmap(5:17,:)=colormap(52:100:4,:)

    colormap=read_colormap_file("GMT_jet")
    printVarSummary(colormap)
    cmap=new((/18,4/),typeof(colormap))
    printVarSummary(colormap)
    cmap(0:4,:)=colormap(0:92:23,:)
    cmap(5:17,:)=colormap(106:250:12,:)



    res=True
    res@gsnDraw=False
    res@gsnFrame=False
    res@gsnAddCyclic=False
 
   
    res@gsnCenterString =xi_model
    res@gsnCenterStringFontHeightF=0.02
    res@cnLineColors="Transparent"  ;
    res@lbLabelBarOn=False
    res@cnFillOn = True 
    res@cnLinesOn =False
    res@cnLineLabelsOn=False
    res@lbLabelBarOn=False
  
    res@cnFillPalette=cmap
    res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour levels
    
    ; res@cnMinLevelValF       =   -0.02
    ; res@cnMaxLevelValF       =   0.06
    ; res@cnLevelSpacingF      =  0.005
    
    res@cnMinLevelValF       =   -0.2
    res@cnMaxLevelValF       =   0.6
    res@cnLevelSpacingF      =  0.05

    res@tmXTOn=False
    res@tmYROn=False
  
    ; res@mpLimitMode           = "LatLon"
    ; res@mpMinLatF             = min(sst_rc1&lat)
    ; res@mpMaxLatF             = max(sst_rc1&lat)
    ; res@mpMinLonF             = min(sst_rc1&lon)
    ; res@mpMaxLonF             = max(sst_rc1&lon)
    ; res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0
    
   
    res@mpLimitMode           = "LatLon"
    res@mpMinLatF             = -50.0
    res@mpMaxLatF             = 50.0
    res@mpMinLonF             = 90
    res@mpMaxLonF             = 300
    res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0
    
   
    ; res@mpShapeMode = "FreeAspect"
    ; res@vpWidthF = 0.7
    ; res@vpHeightF = 0.3
    plot= gsn_csm_contour_map(wks,sst_rc1,res)


         ;;;打点
        res_pro=True
        res_pro@gsnDraw=False
        res_pro@gsnFrame=False
        res_pro@cnLevelSelectionMode = "ExplicitLevels"
        res_pro@cnLinesOn=False
        res_pro@cnLevelSelectionMode = "ManualLevels" ; set manual contour levels
        res_pro@cnMinLevelValF      = 0.00        ; set min contour level
        res_pro@cnMaxLevelValF      = 1.00        ; set max contour level
        res_pro@cnLevelSpacingF     = 0.05       ; set contour spacing

        res_pro@cnLineLabelsOn=False
        res_pro@tmYRMode = "Automatic"
        res_pro@cnInfoLabelOn=False

        iplot=new(1,graphic)

        iplot=gsn_csm_contour(wks,prob1,res_pro)
     
        opt                      = True
        opt@gsnShadeFillType     = "pattern"
        opt@gsnShadeMid     = 17         ; stipple
        ; opt@gsnShadeHigh   = "green"
        opt@gsnShadeFillScaleF   = 0.2         ; add extra density
        opt@gsnShadeFillDotSizeF = 0.0      ; make dots larger

        iplot = gsn_contour_shade(iplot, 0,0.05, opt)
        ;;;  
        overlay(plot, iplot)
  return plot
end 

;;;********************************************************************
;;;主程序
;;;******************************************************************
begin

xi_model=(/"ACCESS1-0","CCSM4","CSIRO-Mk3-6-0","GFDL-ESM2M"\
,"FGOALS-s2","INMCM4","IPSL-CM5A-MR","IPSL-CM5B-LR","MPI-ESM-LR","NorESM1-M"/)


dong_model=(/"BCC-CSM1-1","CanESM2","CMCC-CM","FGOALS-g2","GFDL-CM2P1","GFDL-CM3","GFDL-ESM2G","GISS-E2-H-CC","GISS-E2-R"\
,"HadGEM2-AO","IPSL-CM5A-LR","MIROC5","MPI-ESM-MR","MRI-CGCM3"/)

plot_xi=new(dimsizes(xi_model),graphic)
plot_dong=new(dimsizes(dong_model),graphic)

wks1=gsn_open_wks("pdf", "/mnt/f/share/CMIP5/tos_group/变宽模式的sst趋势变化")
wks2=gsn_open_wks("pdf", "/mnt/f/share/CMIP5/tos_group/变窄模式的sst趋势变化")

do i=0,dimsizes(xi_model)-1
    plot_xi(i)=draw_cmip_sst(xi_model(i),wks1)
end do

do i=0,dimsizes(dong_model)-1
    plot_dong(i)=draw_cmip_sst(dong_model(i),wks2)
end do

pres=True
pres@gsnPanelLabelBar=True
pres@lbOrientation="Vertical"

gsn_panel(wks1, plot_xi, (/5,2/), pres)
gsn_panel(wks2, plot_dong,(/5,3/), pres)

end
    
  
