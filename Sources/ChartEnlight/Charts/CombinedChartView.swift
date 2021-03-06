//
//  CombinedChartView.swift
//  Charts
//
//  Copyright 2015 Daniel Cohen Gindi & Philipp Jahoda
//  A port of MPAndroidChart for iOS
//  Licensed under Apache License 2.0
//
//  https://github.com/danielgindi/Charts
//

import Foundation
import CoreGraphics

/// This chart class allows the combination of lines, bars, scatter and candle data all displayed in one chart area.
@objc 
open class CombinedChartView: BarLineChartViewBase, CombinedChartDataProvider
{
    /// the fill-formatter used for determining the position of the fill-line
    internal var _fillFormatter: IFillFormatter!
    
    /// enum that allows to specify the order in which the different data objects for the combined-chart are drawn
    @objc(CombinedChartDrawOrder)
    public enum DrawOrder: Int
    {
        case bar
        case bubble
        case line
        case candle
        case scatter
    }
    
    open override func initialize()
    {
        super.initialize()
        
        self.highlighter = CombinedHighlighter(chart: self, barDataProvider: self)
        
        // Old default behaviour
        self.highlightFullBarEnabled = true
        
        _fillFormatter = DefaultFillFormatter()
        
        renderer = CombinedChartRenderer(chart: self, animator: _animator, viewPortHandler: _viewPortHandler)
    }
    
    open override var data: ChartData?
    {
        get
        {
            return super.data
        }
        set
        {
            super.data = newValue
            
            self.highlighter = CombinedHighlighter(chart: self, barDataProvider: self)
            
            (renderer as! CombinedChartRenderer?)!.createRenderers()
            renderer?.initBuffers()
        }
    }
    
    open var fillFormatter: IFillFormatter
    {
        get
        {
            return _fillFormatter
        }
        set
        {
            _fillFormatter = newValue
            if _fillFormatter == nil
            {
                _fillFormatter = DefaultFillFormatter()
            }
        }
    }
    
    /// - returns: The Highlight object (contains x-index and DataSet index) of the selected value at the given touch point inside the CombinedChart.
    open override func getHighlightByTouchPoint(_ pt: CGPoint) -> Highlight?
    {
        if _data === nil
        {
            Swift.print("Can't select by touch. No data set.")
            return nil
        }
        
        guard let h = self.highlighter?.getHighlight(x: pt.x, y: pt.y)
            else { return nil }
        
        if !isHighlightFullBarEnabled { return h }
        
        // For isHighlightFullBarEnabled, remove stackIndex
        return Highlight(
            x: h.x, y: h.y,
            xPx: h.xPx, yPx: h.yPx,
            dataIndex: h.dataIndex,
            dataSetIndex: h.dataSetIndex,
            stackIndex: -1,
            axis: h.axis)
    }
    
    /// - returns: The bounding box of the specified Entry in the specified DataSet. Returns null if the Entry could not be found in the charts data.
    open func getBarBounds(entry e: BarChartDataEntry) -> CGRect
    {
        guard let
            data = _data as? BarChartData,
            let set = data.getDataSetForEntry(e) as? IBarChartDataSet
            else { return CGRect.null }
        
        let y = e.y
        let x = e.x
        
        let barWidth = data.barWidth
        
        let left = x - barWidth / 2.0
        let right = x + barWidth / 2.0
        let top = y >= 0.0 ? y : 0.0
        let bottom = y <= 0.0 ? y : 0.0
        
        var bounds = CGRect(x: left, y: top, width: right - left, height: bottom - top)
        
        getTransformer(forAxis: set.axisDependency).rectValueToPixel(&bounds)
        
        return bounds
    }
    
    // MARK: - CombinedChartDataProvider
    
    open var combinedData: CombinedChartData?
    {
        get
        {
            return _data as? CombinedChartData
        }
    }
    
    // MARK: - LineChartDataProvider
    
    open var lineData: LineChartData?
    {
        get
        {
            if _data === nil
            {
                return nil
            }
            return (_data as! CombinedChartData?)!.lineData
        }
    }
    
    // MARK: - BarChartDataProvider
    
    open var barData: BarChartData?
    {
        get
        {
            if _data === nil
            {
                return nil
            }
            return (_data as! CombinedChartData?)!.barData
        }
    }
    
    // MARK: - ScatterChartDataProvider
    
    open var scatterData: ScatterChartData?
    {
        get
        {
            if _data === nil
            {
                return nil
            }
            return (_data as! CombinedChartData?)!.scatterData
        }
    }
    
    // MARK: - CandleChartDataProvider
    
    open var candleData: CandleChartData?
    {
        get
        {
            if _data === nil
            {
                return nil
            }
            return (_data as! CombinedChartData?)!.candleData
        }
    }
    
    // MARK: - BubbleChartDataProvider
    
    open var bubbleData: BubbleChartData?
    {
        get
        {
            if _data === nil
            {
                return nil
            }
            return (_data as! CombinedChartData?)!.bubbleData
        }
    }
    
    // MARK: - Accessors
    
    /// if set to true, all values are drawn above their bars, instead of below their top
    open var drawValueAboveBarEnabled: Bool
        {
        get { return (renderer as! CombinedChartRenderer?)!.drawValueAboveBarEnabled }
        set { (renderer as! CombinedChartRenderer?)!.drawValueAboveBarEnabled = newValue }
    }
    
    /// if set to true, a grey area is drawn behind each bar that indicates the maximum value
    open var drawBarShadowEnabled: Bool
    {
        get { return (renderer as! CombinedChartRenderer?)!.drawBarShadowEnabled }
        set { (renderer as! CombinedChartRenderer?)!.drawBarShadowEnabled = newValue }
    }
    
    /// - returns: `true` if drawing values above bars is enabled, `false` ifnot
    open var isDrawValueAboveBarEnabled: Bool { return (renderer as! CombinedChartRenderer?)!.drawValueAboveBarEnabled }
    
    /// - returns: `true` if drawing shadows (maxvalue) for each bar is enabled, `false` ifnot
    open var isDrawBarShadowEnabled: Bool { return (renderer as! CombinedChartRenderer?)!.drawBarShadowEnabled }
    
    /// the order in which the provided data objects should be drawn.
    /// The earlier you place them in the provided array, the further they will be in the background. 
    /// e.g. if you provide [DrawOrder.Bar, DrawOrder.Line], the bars will be drawn behind the lines.
    open var drawOrder: [Int]
    {
        get
        {
            return (renderer as! CombinedChartRenderer?)!.drawOrder.map { $0.rawValue }
        }
        set
        {
            (renderer as! CombinedChartRenderer?)!.drawOrder = newValue.map { DrawOrder(rawValue: $0)! }
        }
    }
    
    /// Set this to `true` to make the highlight operation full-bar oriented, `false` to make it highlight single values
    open var highlightFullBarEnabled: Bool = false
    
    /// - returns: `true` the highlight is be full-bar oriented, `false` ifsingle-value
    open var isHighlightFullBarEnabled: Bool { return highlightFullBarEnabled }
}
