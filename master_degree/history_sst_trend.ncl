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


 begin
;;读入数据
    
    xi_model=(/"ACCESS1-0","BNU-ESM" ,"CCSM4","CSIRO-Mk3-6-0","FGOALS-s2","GFDL-ESM2M"\
           ,"GISS-E2-R-CC","inmcm4","IPSL-CM5A-MR","IPSL-CM5B-LR","MPI-ESM-LR","NorESM1-M"/)

    dong_model=(/"bcc-csm1-1","CanESM2","CMCC-CM","FGOALS-g2","GFDL-CM2P1","GFDL-CM3","GFDL-ESM2G","GISS-E2-H-CC","GISS-E2-R"\
        ,"HadGEM2-AO","IPSL-CM5A-LR","MIROC5","MPI-ESM-MR","MRI-CGCM3"/)


    model="CMCC-CM"
    diri_output="/mnt/f/share/CMIP5/msf_history/"
   ; system("if ! test -d " + diri_output +" ; then mkdir " + diri_output + " ; fi")   ;;;make dir
   ; diri_output="/mnt/f/share/CMIP5/msf_history/"+model
    yearstart=197901
    yearend=200512
    
    year1=1979
    year2=2005
    fils1=systemfunc("ls /mnt/j/CMIP5/history/tos/"+model+"/r1i1p1/tos_Omon_"+model+"_historical_r1i1p1_"+"*"+".nc")
    print(fils1)

    f1=addfiles(fils1, "join")
     printVarSummary(f1)
 
    vNames= getfilevarnames(f1[:]) ; get variable names of all groups on file
    print(vNames)
    



    if (any(vNames.eq."LONN179_180")) then 

    lon2d=f1[:]->LONN179_180
    lat2d=f1[:]->LAT
    time=f1[:]->TIME
    else 

    lon2d=f1[:]->lon
    lat2d=f1[:]->lat
    time=f1[:]->time
    end if

    date=cd_calendar(time, 1)
    print("******************日期*********************")


    timeind=ind(date.le.yearend.and.date.ge.yearstart)
    print(date(timeind))
         
    ; sst_r=lonPivot(f1[:]->tos(timeind,:,:),0.7031)  ;;;195801-201212
    if (any(vNames.eq."LONN179_180")) then 
    sst_r=lonFlip(f1[:]->TOS(timeind,:,:))
    else 
    sst_r=f1[:]->tos(timeind,:,:)
    end if

    sst_r=(/sst_r-273.15/)
    
    printVarSummary(sst_r)
    

    if (any(vNames.eq."LONN179_180"))  then
    dNames = getvardims(f1[:]->TOS)
    else
    dNames = getvardims(f1[:]->tos)
    end if       
    print(dNames)
    
    if (any(dNames.eq."rlat").or.any(vNames.eq."LONN179_180")) then 
    sst_r!0="time"
    sst_r!1="lat"
    sst_r!2="lon"

   end if 
   

   
    if (any(getvardims(lon2d).eq."j"))  then

    lonW=90.0
    lonE=300.0

    latS=-30.0
    latN=30.0
  
    ij=region_ind(lat2d, lon2d, latS, latN, lonW, lonE)
  
   ;---Store to local variables for better code readability
    ilat1 = ij(0)
    ilat2 = ij(1)
    ilon1 = ij(2)
    ilon2 = ij(3)   

    ;---Subscript variables using these index values
   
    lat2d_sub = lat2d(ilat1:ilat2,ilon1:ilon2)      ; 30 x 21
    lon2d_sub = lon2d(ilat1:ilat2,ilon1:ilon2)      ; 30 x 21


    ; sst=sst_r(:,latind(0):latind(1),lonind(0):lonind(1))
    sst=sst_r(:,ilat1:ilat2,ilon1:ilon2)

    delete(sst&j)
    delete(sst&i)
    
     sst!1="lat"
     sst!2="lon"

    ; sst&lat=lat(latind(0):latind(1),1)
    ; sst&lon=lon(1,lonind(0):lonind(1))

    sst&lat=lat2d(ilat1:ilat2,1)
    sst&lon=lon2d(1,ilon1:ilon2)
    
     else 
 
    sst=sst_r(:,{30:-30},{90:300})

    sst!1="lat"
    sst!2="lon"
    end if
    

    delete(sst&time)
    sst&time=date(timeind)
    sst&lat@units="degrees_north"
    sst&lon@units="degrees_east"
    
    printVarSummary(sst)


    ; print("*****************开始水平插值************************")  
    ; xo=fspan(0,357.5,144)
    ; yo=fspan(-87.5, 87.5, 71)
   
    ; sst=linint2_Wrap(sst_r&lon, sst_r&lat, sst_r, \
    ;                   True, xo, yo, 0)

    ;  sst!1="lat" 
    ;  sst!2="lon"
    ; sst&lat@units="degrees_north"
    ; sst&lon@units="degrees_east"
    ; delete(sst_r)
    ; printVarSummary(sst)
   

    ; lat=sst&lat
    ; lon=sst&lon 
    ; lon@units="degree_east"



     print("*****************计算趋势************************")  
    
    
    ;;;先得到秋季和冬季的SONDJF海温
    sst_son=month_to_season(sst(time|:,lat|:,lon|:), "SON")
    sst_djf=month_to_season(sst(time|:,lat|:,lon|:), "DJF")
    printVarSummary(sst_son)

    sst_son&time=ispan(year1,year2,1)
    sst_djf&time=ispan(year1,year2,1)  ;;;因为这里第一个是1958 1月和2月的平均，第二个是195812,195901,195902的平均
    ;;注意点
    sst_djf(0:dimsizes(sst_djf&time)-2,:,:)=(/sst_djf(1:,:,:)/)
    sst_djf(dimsizes(sst_djf&time)-1,:,:)=(/sst({200512},:,:)/)
    
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

   ; sst_mean_annual=where(sst_mean_annual.eq.sst_mean_annual@_FillValue, 0, sst_mean_annual)
 

    sst_rc1=regCoef_n(ispan(1,dimsizes(sst_mean_annual&time),1),sst_mean_annual(:,:,:),0,0)  
    copy_VarCoords(sst_mean_annual(0,:,:), sst_rc1)
    printVarSummary(sst_rc1)
    ; sst_rc1=where(sst_rc1.eq.0, sst_rc1@_FillValue, sst_rc1)
   

;************************************************
; 显著性检验
;************************************************
    ; prob1=rc_test(sst_rc1)
    ; sst_rc1=(/sst_rc1/)*10
    ; printVarSummary(sst_rc1)
    ; copy_VarCoords(sst_mean_annual(1,:,:), sst_rc1)
    
    
    print("**********************海温*****************************")


if any(xi_model.eq.model) then 
 wks=gsn_open_wks("pdf", "/mnt/f/share/CMIP5/tos_group/xi_model/"+model+"_sst趋势变化")
else
 wks=gsn_open_wks("pdf", "/mnt/f/share/CMIP5/tos_group/dong_model/"+model+"_sst趋势变化")
end if



   ; gsn_define_colormap(wks, "GMT_polar")



    colormap=read_colormap_file("BlWhRe")
    printVarSummary(colormap)

    cmap=new((/18,4/),typeof(colormap))
     
    printVarSummary(colormap)
  
    cmap(0:4,:)=colormap(0:40:10,:)
    cmap(5:17,:)=colormap(52:100:4,:)


    res=True
    res@gsnDraw=False
    res@gsnFrame=False
    res@gsnAddCyclic=False

    res@cnLineColors="Transparent"  ;
    res@lbLabelBarOn=False
    res@cnFillOn = True 
    res@cnLinesOn =False
    res@cnLineLabelsOn=False
    res@lbLabelBarOn=True
    ; res@cnFillMode="RasterFill"
    ; res@cnRasterSmoothingOn=True
    res@cnFillPalette=cmap
    res@cnLevelSelectionMode = "ManualLevels"      ; set manual contour levels
    
    res@gsnLeftString=model
    res@cnMinLevelValF       =   -0.02
    res@cnMaxLevelValF       =   0.06
    res@cnLevelSpacingF      =  0.005

    res@tmXTOn=False
    res@tmYROn=False
    
    if (any(getvardims(lon2d).eq."j"))  then   
   ;---Plot this "zoomed in data"
    res@sfYArray          := lat2d_sub
    res@sfXArray          := lon2d_sub
    end if


    res@mpLimitMode           = "LatLon"
    res@mpMinLatF             = min(sst_rc1&lat)
    res@mpMaxLatF             = max(sst_rc1&lat)
    res@mpMinLonF             = min(sst_rc1&lon)
    res@mpMaxLonF             = max(sst_rc1&lon)
    res@mpCenterLonF          = (res@mpMinLonF+res@mpMaxLonF)/2.0
    
   




    res@mpShapeMode = "FreeAspect"
    res@vpWidthF = 0.7
    res@vpHeightF = 0.3

    plot=new(1,graphic)
    plot(0)= gsn_csm_contour_map(wks,sst_rc1,res)

;   iplot=new(1,graphic)


; ;;打点
;   res=True
;   res@gsnDraw=False
;   res@gsnFrame=False
;   res@cnLevelSelectionMode = "ExplicitLevels"
;   res@cnFillPatterns=8
;   res@cnLevels=0.05
;   res@cnLinesOn=False
;   res@cnFillOn=True
;   res@cnFillDotSizeF=1.0
  
;   iplot(0) = gsn_csm_contour(wks, prob1, res)

; ;;;  

; overlay(plot(0), iplot(0))

draw(plot)
frame(wks)
end
    
  
