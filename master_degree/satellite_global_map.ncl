;----------------------------------------------------------------------
; newcolor_11.ncl
;
; Concepts illustrated:
;   - Showing features of the new color display model
;   - Recreating a JPEG topographic image as an NCL map object
;   - Using more than 256 colors per frame
;   - Using "overlay" to overlay multiple contours
;   - Changing the size of a PNG image
;----------------------------------------------------------------------
; NOTE: This example will only work with NCL V6.1.0 and later.
;
; This example only works for "x11" or "png" output, and not with
; "ps" and "pdf" output.
;
; The original JPEG file was converted to a NetCDF file with color
; separated bands using the open source tool "gdal_translate":
;
;  gdal_translate -ot Int16 -of netCDF EarthMap_2500x1250.jpg \
;           EarthMap_2500x1250.nc
;----------------------------------------------------------------------
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   

begin
  filename     = "/mnt/f/share/heng/EarthMap_2500x1250"
  jpeg_filename = filename + ".jpg"
  ; jpeg_filename = filename + ".png"
  nc_filename  = filename + ".nc"

; --You could use a system call to do the NetCDF conversion
 ; system("gdal_translate -ot Int16 -of netCDF " + jpeg_filename + " " + nc_filename)

;---Read the three bands of data
  f     = addfile(nc_filename,"r")
  Band1 = where(f->Band1.gt.255, 255, f->Band1)  ; red channel
  Band2 = where(f->Band2.gt.255, 255, f->Band2)  ; green channel
  Band3 = where(f->Band3.gt.255, 255, f->Band3)  ; blue channel

  band_dims = dimsizes(Band3)
  nlat      = band_dims(0)
  nlon      = band_dims(1)
  print("dimensions of image = " + nlat + " x " + nlon)

;
; Add lat/lon data so we can overlay on a map, and/or 
; overlay contours. We know the image is global,
; cylindrical equidistant, and centered about lon=0.
;
  ; lat       = fspan( -90, 90,nlat)
  ; lon       = fspan(-180,180,nlon)

  lat       = fspan( -90, 90,nlat)
  lon       = fspan(0,360,nlon)


  lat@units = "degrees_north"
  lon@units = "degrees_east"

  Band1!0   = "lat"
  Band1!1   = "lon"
  Band2!0   = "lat"
  Band2!1   = "lon"
  Band3!0   = "lat"
  Band3!1   = "lon"
  Band1&lat = lat
  Band1&lon = lon
  Band2&lat = lat
  Band2&lon = lon
  Band3&lat = lat
  Band3&lon = lon
  
    ; fils2=systemfunc("ls /mnt/f/share/shixiong/landsea.nc")

    ; a=addfile(fils2, "r")
    ; lsdata = a->LSMASK

     


    ; lsm = landsea_mask(lsdata,Band1&lat,Band1&lon)   ;;得到的结果，1表示land  

    ; Band1 = mask(Band1,lsm.eq.0,False)
    ; Band2 = mask(Band2,lsm.eq.0,False)
    ; Band3 = mask(Band3,lsm.eq.0,False)


    ; Band1 = where(Band1.eq.0, Band1@_FillValue ,Band1)
    ; Band2 = where(Band2.eq.3,Band2@_FillValue ,Band2)
    ; Band3 = where(Band3.eq.38,Band3@_FillValue ,Band3)


;
; Get the dimension sizes so we can properly size the
; viewport to match the image.
; NCL wants to draw to a square. So pick the largest of the
; two dimensions and make this the size of the square.
;
; Recreating jpeg images only works for X11 and PNG.
;
  wks_type          = "png"
  ; wks_type@wkWidth  = max((/nlat,nlon/))
  ; wks_type@wkHeight = max((/nlat,nlon/))
  wks = gsn_open_wks(wks_type, "/mnt/f/share/era/data/newcolor")         ; Open a workstation.

  res                 = True
  ; res@vpWidthF        = 1.0          ; Force image to fill screen.
  ; res@vpHeightF       = 1.0

  res@gsnFrame        = False        ; Don't draw or advance
  res@gsnDraw         = False        ; frame yet.

  res@cnFillOn        = True         ; Turn on filled rasters
  res@cnFillMode      = "RasterFill"

  res@cnFillDrawOrder="PreDraw"

  res@cnLevelSelectionMode  = "EqualSpacedLevels"
  res@cnMaxLevelCount       = 254  
  res@cnFillBackgroundColor = (/ 1., 1., 1., 1./)

  res@cnLinesOn       = False              ; Turn off contour lines      .
  res@cnLineLabelsOn  = False              ; Turn off contour labels
  res@cnInfoLabelOn   = False              ; Turn off info label
  res@gsnTickMarksOn  = False              ; Turn off tickmarks
  res@lbLabelBarOn    = False              ; Turn off labelbar
  res@gsnRightString  = ""                 ; Turn off subtitles
  res@gsnLeftString   = ""

;---Construct RGBA colormaps...
  ramp   = fspan(0., 1., 255)
  reds   = new((/255, 4/), float)
  greens = new((/255, 4/), float)
  blues  = new((/255, 4/), float)

  reds   = 0
  greens = 0
  blues  = 0

  reds(:,0)   = ramp
  greens(:,1) = ramp
  blues(:,2)  = ramp

  ; The red contour map is plotted fully opaque; the green and blue
  ; are plotted completely transparent. When overlain, the colors 
  ; combine (rather magically).
  reds(:,3)   = 1.
  greens(:,3) = 0 
  blues(:,3)  = 0

  res@cnFillColors = greens 
  greenMap = gsn_csm_contour(wks, Band2, res) 

  res@cnFillColors = blues
  blueMap = gsn_csm_contour(wks, Band3, res) 
 
;---This will be our base, so make it a map plot.
  res@cnFillColors             = reds 
  res@gsnAddCyclic             = False

  ; res@mpDataBaseVersion        = "MediumRes"
  ; res@mpOutlineBoundarySets    = "National"
  ; res@mpNationalLineThicknessF = 2.0
  ; res@mpFillOn                 = False  

  redMap = gsn_csm_contour(wks, Band1, res) 


; ;---Overlay everything and draw
;   overlay(redMap, greenMap)
;   overlay(redMap, blueMap)



  ;;;读入海温数据
   diri="/mnt/f/share/ersst/"
  fils1=systemfunc("ls "+diri+"sst.mnmean.v4.nc")
  f1=addfile(fils1, "r")
  date=cd_calendar(f1->time, 1)
  timeind=ind(date.le.201312.and.date.ge.197901)
  ; sst=lonFlip(f1->sst(timeind,:,:))
  sst=f1->sst(timeind,:,:)
  printVarSummary(sst)

  sst!0="time"
  sst!1="lat"
  sst!2="lon"
  delete(date)
  delete(f1)

  
  ; xo=fspan(0,358,1433)
  ; yo=fspan(-88, 88, 705)

  ; print("*****************开始水平插值************************")  
  ; sst_cha=linint2_Wrap(sst&lon, sst&lat(::-1), sst(:,::-1,:), \
  ;                 True, xo, yo, 0)
  ;    ; uwnd!0="time"
  ;    sst_cha!1="lat"
  ;    sst_cha!2="lon"
  ;   sst_cha&lat@units="degrees_north"
  ;   sst_cha&lon@units="degrees_east"

  ;  printVarSummary(sst_cha)
  ;  delete(sst)


  ssta=(/rmMonAnnCycTLL(sst(:,:,:))/)
  copy_VarCoords(sst(:,:,:), ssta)
  delete(sst)

  ssta_djf=month_to_season(ssta, "DJF")
  ssta_s=(/ssta_djf(1:,:,:)/)*1.0
  copy_VarCoords(ssta_djf(0:dimsizes(ssta_djf&time)-2,:,:), ssta_s)
  delete(ssta_s&time)
  ssta_s&time=ispan(1979, 2012, 1)  
  ;;;;

  ;;;两个时间段的海温异常
  nino3=dim_avg_n(ssta_s(:,{5:-5},{210:270}), (/1,2/))
  nino3_std=dim_standardize_n(nino3, 1, 0)
  
  ;;;挑选年份 canino  enino year
  caind=ind(nino3_std.ge.1)
  laind=ind(nino3_std.le.-1)
  midind=ind(nino3_std.le.1.and.nino3_std.ge.-1)
  
  ssta_e=dim_avg_n_Wrap(ssta_s(caind,:,:),0)
  ssta_l=dim_avg_n_Wrap(ssta_s(laind,:,:),0)
  ssta_n=dim_avg_n_Wrap(ssta_s(midind,:,:),0)

;;写nc文件

fout=addfile("/mnt/f/share/heng/ssta_enino.nc", "c")
fout->ssta=ssta_e


; ;;;
 ;; 叠上去的海温
  res2=True
  res2@gsnFrame=False
  res2@gsnDraw=False
  res2@cnFillOn=True
  res2@cnLinesOn=False
  res2@cnInfoLabelOn=False
  res2@cnLevelSelectionMode = "ManualLevels"      ; set manual contour levels
  res2@cnMinLevelValF       =  -2
  res2@cnMaxLevelValF       =  2
  res2@cnLevelSpacingF      = 0.25
  res2@mpFillOn=False
  ; res2@mpFillColors="green"
  res2@mpGeophysicalLineColor ="black"

  ; res2@cnFillDrawOrder="PreDraw"
  res2@cnFillDrawOrder="PostDraw"
  res2@mpLimitMode           = "LatLon"
  res2@mpMinLatF                = min(Band1&lat)
  res2@mpMaxLatF                = max(Band1&lat)
  res2@mpMinLonF                = min(Band1&lon)
  res2@mpMaxLonF                = max(Band1&lon)
  res2@mpCenterLonF          =avg(Band1&lon) 
  ; res2@cnFillDrawOrder="PostDraw"

plot1=gsn_csm_contour_map(wks, ssta_e, res2)


;---Overlay on existing map and draw.

; ---Overlay everything and draw
  ; overlay(redMap, greenMap)
  ; overlay(redMap, blueMap)
  overlay(plot1, redMap)
  ; overlay(plot1, greenMap)
  ; overlay(plot1, blueMap)
  ; overlay(redMap, plot1)

  draw(plot1)
  frame(wks)


end