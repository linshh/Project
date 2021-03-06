begin

	; 读取 .nc 文件
    path     = "/home/ys17-19/lsh/Project/other/assginment3/"
    fili1    = "uwnd.assignment3.nc"
    fili2    = "vwnd.assignment3.nc"
    fili3    = "tp.assignment3.nc"
    f1       = addfile(path+fili1,"r")
	f2       = addfile(path+fili2,"r")
	f3       = addfile(path+fili3,"r")

    timetp            = f3->time
    timeu             = f1->time
    timev             = f2->time

	; ========================================================================
	; 提取 .nc 文件指定的时间位置
	; (建议使用 cd_calendar 及 ind)
	
	; 2018年6月27日

    timetpcon         = cd_calendar(timetp, 2)
    timeucon          = cd_calendar(timeu, 2)
    timevcon          = cd_calendar(timev, 2)

	timetp1          = ind(timetpcon.eq.20180627)
	timeu1           = ind(timeucon.eq.20180627)
    timev1           = ind(timevcon.eq.20180627)

	; 2018年6月15日至7月15日
	timetp2          = ind(timetpcon.ge.20180615.and.timetpcon.le.20180715)
    timetp2_         = f3->time(timetp2)
	timetp3          = cd_calendar(timetp2_, 2)
	; ========================================================================
	; 提取 2018年6月27日的降水数据
	; 单位需要由 m 转为 mm
	p1             = f3->tp (timetp1,:,:)
	p1            := (/p1*1000/)
    p1@units       = "mm"

	; 提取 2018年6月15日至7月15日北纬35度，东经127.5的降水数据
	; 单位需要由 m 转为 mm
	p2             = f3->tp (timetp2,{35},{127.5})
	p2            := (/p2*1000/)
    p2@units       = "mm"
	
	
	; 提取 2018年6月27日 700百帕的风场
    u       = f1 ->uwnd (time|timeu1,{level|700},lat|:,lon|:)
    v       = f2 ->vwnd (time|timev1,{level|700},lat|:,lon|:)
	
	
	
	; ========================================================================
	; 打开工作空间
    pltName = "18304097.assignment3.q1"
    wks =gsn_open_wks("eps" , pltName)
	
	
	; =========================================================================
	; 定义绘图属性
	
	res 								= True
	res@gsnDraw 						= False
	res@gsnFrame 						= False
	res@gsnLeftString 					= ""
	res@gsnRightString 					= ""
	
	resxy	 							= res
	
	res@gsnAddCyclic					= False
	rescn								= res
	resvc 								= res
				
	res@vpWidthF 						= 0.7
				
	res@cnFillOn 						= True		 
	res@cnLinesOn						= False
	
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	; res: 图 (a) 底图
	
	; 标题
	
	res@tiMainString                    = "Precipitation on June 27, 2018 and 700 hPa Wind Field"
	
	; 地图范围
	; mpMinLatF, mpMaxLatF, mpMinLonF, mpMaxLonF
	res@mpMinLatF                       = 15.
    res@mpMaxLatF                       = 45.
    res@mpMinLonF                       = 100.
    res@mpMaxLonF                       = 140.
    res@mpCenterLonF                    = 120.	
	
	; 高分辨率地图
	; mpDataBaseVersion
	res@mpDataBaseVersion               = "HighRes"

	; 色板
	; cnFillPalette
	res@cnFillPalette                   = "BlueDarkRed18"
	
	
	; 等值线间距
	; cnLevelSelectionMode 及相应属性

	res@cnLevelSelectionMode            = "ManualLevels"
    res@cnMaxLevelValF                  = 30
    res@cnMinLevelValF                  = 0
    res@cnLevelSpacingF                 = 2
	
	
	; (可选) 字体大小
	; XY轴：tmXBLabelFontHeightF, tmYLLabelFontHeightF
	; 主标题: tiMainFontHeightF
	; 副标题: gsnCenterStringFontHeightF
    ;res@tmXBLabelFontHeightF    = 0.003
    ;res@tmYLLabelFontHeightF    = 0.003
    ;res@tiMainFontHeightF       = 0.003
	
	
	; (可选) 主标题Y方向移动位置
	; tiMainOffsetYF
	
	
	
	; ---------------------------------------------------------------------------
	; rescn: 图 (a) 等值线：降水=30mm
	;rescn@cnFillOn                      = True

	; 等值线间距
	; cnLevelSelectionMode 及相应属性
	rescn@cnLevelSelectionMode          = "ExplicitLevels"
	rescn@cnLevels                      = 30

	; 等值线颜色及粗细度
	; cnLineColor, cnLineThicknessF
	rescn@cnLineColor                   = "Purple"
    rescn@cnLineDashPattern             = 1
    rescn@cnLineThicknessF              = 3
	
	
	; 不显示等值线标签及信息
	; cnLineLabelsOn, cnInfoLabelOn
	rescn@cnLineLabelsOn                = False
    rescn@cnInfoLabelOn                 = False
	
	
	; ---------------------------------------------------------------------------
	; resvc: 图 (a) 矢量
	
	; 矢量样式
	; vcGlyphStyle
	resvc@vcGlyphStyle                  = "LineArrow"
	
	
	; (可选) 矢量的粗细度及最短距离(NDC单位)
	; vcLineArrowThicknessF, vcMinDistanceF
    resvc@vcLineArrowThicknessF  =  2.
	
	

	; 参考矢量的长度(NDC单位)及其表示的数值
	; vcRefLengthF, vcRefMagnitudeF
	resvc@vcRefLengthF                  = 0.1
    resvc@vcRefMagnitudeF               = 20

	
	
	; 参考矢量信息的X,Y方向的位置
	; vcRefAnnoParallelPosF, vcRefAnnoOrthogonalPosF
	resvc@vcRefAnnoParallelPosF         = 1
    resvc@vcRefAnnoOrthogonalPosF       = 0.05
	
	
	; (可选) 参考矢量信息的字体大小
	;vcRefAnnoFontHeightF

	
	
	; ---------------------------------------------------------------------------
	; resxy: 图 (b) XY 图
	
	resxy@vpWidthF 					   	 = 0.7
	resxy@vpHeightF 					 = 0.4
	
	resxy@tmXTOn 						 = False
	resxy@tmYROn 						 = False
	
	resxy@trYMinF 						 = 0.
	
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	; 以柱状图表示
	; 标题
	resxy@tiMainString                   = "Time Series of Total Precipitation from 2018.6.15 to 7.15"                 
	
	
	; X,Y轴标题
	; tiXAxisString, tiYAxisString
	resxy@tiXAxisString                  = "Time(day)"
 	resxy@tiYAxisString                  = "Total Precipitation(mm)"
	
	
	; gsnXYBarChart
	resxy@gsnXYBarChart                  = True
	
	
	; X 轴
	; tmXBMode 及相应属性
    resxy@tmXBOn                         = True
    resxy@tmXBMode                       = "Explicit"
    resxy@tmXBValues                     = (/1,6,11,16,21,26/)
    resxy@tmXBLabels                     = (/"6.16","6.21","6.26","7.1","7.6","7.11"/)
    resxy@tmXBMinorValues               = ispan(0,30,1)

	
	; (可选) XY线及柱状的颜色
	resxy@gsnXYBarChartColors            = "Blue"
	
	
	; (可选) 字体大小
	; 主标题: tiMainFontHeightF
	; X,Y轴标题: tiXAxisFontHeightF, tiYAxisFontHeightF

	
	; ---------------------------------------------------------------------------
	; 标记 (北纬35度，东经127.5度)
	; gsMarkerIndex, gsMarkerColor, gsMarkerSizeF
	; (可选) gsMarkerThicknessF

    text                        = (/"35~S~o~N~N 127.5~S~o~N~E"/)
    resText                     = True
    resText@txFontHeightF       = 0.03
    resText@txFontColor         = "Red"

	resMark                     = True
    resMark@gsMarkerIndex       = 7
    resMark@gsMarkerColor       = "Red"
    resMark@gsMarkerSizeF       = 0.02
	resMark@gsMarkerThicknessF  = 3.
	
	; =========================================================================
	; 画图
	
	; 图 (a)
	
	; 降水地图
	plot            = gsn_csm_contour_map(wks, p1, res)
	
	; 降水=30 mm
	plotcn          = gsn_csm_contour(wks, p1, rescn)


	; 700百帕风场
	plotvc          = gsn_csm_vector(wks,u,v,resvc)

	; 添加标记

	plotText       = gsn_add_text(wks,plot,text,127.5,40,resText)
    plotM          = gsn_add_polymarker(wks,plot,127.5,35.,resMark)
    
    ;draw(plot)
    ;frame(wks)
	
	; --------------------------------------------------------------------------
	; 图 (b)
    ti             = fspan(0,30,31)
	plot1          = gsn_csm_xy(wks,ti,p2,resxy)

	
	; =========================================================================
	; 绘画展板
	; gsnPanelXF 设定图(a)及(b)在X方向的位置(NDC坐标)
	; gsnPanelYF 设定图(a)及(b)在Y方向的位置(NDC坐标)
    overlay(plot, plotcn)
    overlay(plot, plotvc)   


    resPanel                            = True 
    resPanel@gsnPanelMainString         = "Zhang Xinwen(18304097)"
    resPanel@gsnPanelMainFontHeightF    = 0.02

    resPanel@gsnPanelYWhiteSpacePercent = 5.
    

    gsn_panel(wks, (/plot,plot1/) ,(/2,1/), resPanel)
	
	
	
	; =========================================================================
	; 去掉空白空间
    delete (wks) 
    system("convert -geometry 3000x3000 -density 600x600 -trim " + pltName + ".eps " + pltName + ".png")
    system("rm " + pltName + ".eps -f")

end