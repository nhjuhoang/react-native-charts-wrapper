//
// Created by xudong wu on 26/02/2017.
// Copyright (c) wuxudong. All rights reserved.
//

import Foundation
import Charts
import SwiftyJSON

class RNBarLineChartViewBase: RNYAxisChartViewBase {
    fileprivate var barLineChart: BarLineChartViewBase {
        get {
            return chart as! BarLineChartViewBase
        }
    }

    @available(iOS 10.0, *)
    private(set) lazy var feedbackGenerator = UISelectionFeedbackGenerator()

    internal var _longPressGestureRecognizer: UILongPressGestureRecognizer!
    var savedVisibleRange : NSDictionary?

    var savedZoom : NSDictionary?

    var _onYaxisMinMaxChange : RCTBubblingEventBlock?
    var timer : Timer?

    override func setYAxis(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        if json["left"].exists() {
            let leftYAxis = barLineChart.leftAxis
            barLineChart.leftYAxisRenderer = CustomYAxisRenderer(viewPortHandler: barLineChart.viewPortHandler, yAxis: leftYAxis, transformer: barLineChart.getTransformer(forAxis: YAxis.AxisDependency.left), config: json["left"])
            setCommonAxisConfig(leftYAxis, config: json["left"]);
            setYAxisConfig(leftYAxis, config: json["left"]);
        }


        if json["right"].exists() {
            let rightAxis = barLineChart.rightAxis
            barLineChart.rightYAxisRenderer = CustomYAxisRenderer(viewPortHandler: barLineChart.viewPortHandler, yAxis: rightAxis, transformer: barLineChart.getTransformer(forAxis: YAxis.AxisDependency.right), config: json["right"])
            setCommonAxisConfig(rightAxis, config: json["right"]);
            setYAxisConfig(rightAxis, config: json["right"]);
        }
    }

    func setOnYaxisMinMaxChange(_ callback: RCTBubblingEventBlock?) {
      self._onYaxisMinMaxChange = callback;
      self.timer?.invalidate();
      if callback == nil {
        return;
      }

      var lastMin: Double = 0;
      var lastMax: Double = 0;

      let axis = (self.chart as! BarLineChartViewBase).getAxis(.right);

      if #available(iOS 10.0, *) {
        // Interval for 16ms
        self.timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { timer in
          let minimum = axis.axisMinimum;
          let maximum = axis.axisMaximum;
          if lastMin != minimum || lastMax != maximum {
            print("Update the view", minimum, lastMin, maximum, lastMax)

            guard let callback = self._onYaxisMinMaxChange else {
              return;
            }
            callback([
              "minY": minimum,
              "maxY": maximum,
            ]);
          }
          lastMin = minimum;
          lastMax = maximum;
        }
      } else {
        // Fallback on earlier versions
      }
    }

    func setMaxHighlightDistance(_  maxHighlightDistance: CGFloat) {
        barLineChart.maxHighlightDistance = maxHighlightDistance;
    }

    func setDrawGridBackground(_  enabled: Bool) {
        barLineChart.drawGridBackgroundEnabled = enabled;
    }


    func setGridBackgroundColor(_ color: Int) {
        barLineChart.gridBackgroundColor = RCTConvert.uiColor(color);
    }


    func setDrawBorders(_ enabled: Bool) {
        barLineChart.drawBordersEnabled = enabled;
    }

    func setBorderColor(_ color: Int) {

        barLineChart.borderColor = RCTConvert.uiColor(color);
    }

    func setBorderWidth(_ width: CGFloat) {
        barLineChart.borderLineWidth = width;
    }


    func setMaxVisibleValueCount(_ count: NSInteger) {
        barLineChart.maxVisibleCount = count;
    }

    func setVisibleRange(_ config: NSDictionary) {
        // delay visibleRange handling until chart data is set
        savedVisibleRange = config
    }

    func updateVisibleRange(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        let x = json["x"]
        if x["min"].double != nil {
            barLineChart.setVisibleXRangeMinimum(x["min"].doubleValue)
        }
        if x["max"].double != nil {
            barLineChart.setVisibleXRangeMaximum(x["max"].doubleValue)
        }

        let y = json["y"]
        if y["left"]["min"].double != nil {
            barLineChart.setVisibleYRangeMinimum(y["left"]["min"].doubleValue, axis: YAxis.AxisDependency.left)
        }
        if y["left"]["max"].double != nil {
            barLineChart.setVisibleYRangeMaximum(y["left"]["max"].doubleValue, axis: YAxis.AxisDependency.left)
        }

        if y["right"]["min"].double != nil {
            barLineChart.setVisibleYRangeMinimum(y["right"]["min"].doubleValue, axis: YAxis.AxisDependency.right)
        }
        if y["right"]["max"].double != nil {
            barLineChart.setVisibleYRangeMaximum(y["right"]["max"].doubleValue, axis: YAxis.AxisDependency.right)
        }
    }

    func setAutoScaleMinMaxEnabled(_  enabled: Bool) {
        barLineChart.autoScaleMinMaxEnabled = enabled
    }

    func setKeepPositionOnRotation(_  enabled: Bool) {
        barLineChart.keepPositionOnRotation = enabled
    }

    func setScaleEnabled(_  enabled: Bool) {
        barLineChart.setScaleEnabled(enabled)
    }

    func setDragEnabled(_  enabled: Bool) {
        barLineChart.dragEnabled = enabled
    }


    func setScaleXEnabled(_  enabled: Bool) {
        barLineChart.scaleXEnabled = enabled
    }

    func setScaleYEnabled(_  enabled: Bool) {
        barLineChart.scaleYEnabled = enabled
    }

    func setPinchZoom(_  enabled: Bool) {
        barLineChart.pinchZoomEnabled = enabled
    }

    func setHighlightLongPressDragEnabled(_  enabled: Bool) {
            if enabled {
                _longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureRecognizer(_:)))
                self.chart.addGestureRecognizer(_longPressGestureRecognizer)
            } else {
                self.chart.removeGestureRecognizer(_longPressGestureRecognizer)
        }
    }

    @objc private func longPressGestureRecognizer(_ gesture: UILongPressGestureRecognizer) {
        if self.chart.data === nil {
            return
        }

        if gesture.state == .changed || gesture.state == .began {
            // update gesture when location changes
            let touchPoint = gesture.location(in: self)
            let clampedTouchPoint = CGPoint(x: touchPoint.x, y: max(min(touchPoint.y, self.chart.viewPortHandler.contentBottom), self.chart.viewPortHandler.contentTop))

            guard let h = self.chart.getHighlightByTouchPoint(clampedTouchPoint) else {
                self.chart.lastHighlighted = nil
                self.chart.highlightValue(nil, callDelegate: true)
                return
            }
            let lastHighlighted = self.chart.lastHighlighted
            let axisTransformer = self.barLineChart.getTransformer(forAxis: h.axis)

            let value = axisTransformer.valueForTouchPoint(clampedTouchPoint)

            let highlight = Highlight(x: h.x, y: Double(value.y), xPx: h.xPx, yPx: touchPoint.y, dataIndex: h.dataIndex, dataSetIndex: h.dataSetIndex, stackIndex: -1, axis: h.axis)

            if highlight != lastHighlighted {
                self.chart.lastHighlighted = highlight
                let xChanged = highlight.x != lastHighlighted?.x
                if self.hapticsEnabled && xChanged, #available(iOS 10.0, *) {
                    // TODO move haptics to its own property?
                    feedbackGenerator.selectionChanged()
                }
                // only call delegate when the x value changes (don't want to spam when y changes)
                self.chart.highlightValue(highlight, callDelegate: xChanged)
            }
        } else if gesture.state == .ended {
            // remove highlight after gesture
            self.chart.lastHighlighted = nil
            self.chart.highlightValue(nil, callDelegate: true)
            if (self.onGestureEnd != nil) {
                self.onGestureEnd!(["action": "longPressDrag"])
            }
        }
    }

    func setHighlightPerDragEnabled(_  enabled: Bool) {
        barLineChart.highlightPerDragEnabled = enabled
    }

    func setDoubleTapToZoomEnabled(_  enabled: Bool) {
        barLineChart.doubleTapToZoomEnabled = enabled
    }

    func setZoom(_ config: NSDictionary) {
        self.savedZoom = config
    }

    func updateZoom(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        if json["scaleX"].float != nil && json["scaleY"].float != nil && json["xValue"].double != nil && json["yValue"].double != nil {
            var axisDependency = YAxis.AxisDependency.left

            if json["axisDependency"].string != nil && json["axisDependency"].stringValue == "RIGHT" {
                axisDependency = YAxis.AxisDependency.right
            }
            
            barLineChart.zoom(scaleX: CGFloat(json["scaleX"].floatValue),
                    scaleY: CGFloat(json["scaleY"].floatValue),
                    xValue: json["xValue"].doubleValue,
                    yValue: json["yValue"].doubleValue,
                    axis: axisDependency)
        }
    }

    func setViewPortOffsets(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)

        let left = json["left"].double != nil ? CGFloat(json["left"].doubleValue) : 0
        let top = json["top"].double != nil ? CGFloat(json["top"].doubleValue) : 0
        let right = json["right"].double != nil ? CGFloat(json["right"].doubleValue) : 0
        let bottom = json["bottom"].double != nil ? CGFloat(json["bottom"].doubleValue) : 0

        barLineChart.setViewPortOffsets(left: left, top: top, right: right, bottom: bottom)
    }

    func setExtraOffsets(_ config: NSDictionary) {
        let json = BridgeUtils.toJson(config)
    
        let left = json["left"].double != nil ? CGFloat(json["left"].doubleValue) : 0
        let top = json["top"].double != nil ? CGFloat(json["top"].doubleValue) : 0
        let right = json["right"].double != nil ? CGFloat(json["right"].doubleValue) : 0
        let bottom = json["bottom"].double != nil ? CGFloat(json["bottom"].doubleValue) : 0
    
        barLineChart.setExtraOffsets(left: left, top: top, right: right, bottom: bottom)
    }
    
    override func onAfterDataSetChanged() {
        super.onAfterDataSetChanged()

        // clear zoom after applied, but keep visibleRange
        if let visibleRange = savedVisibleRange {
            updateVisibleRange(visibleRange)
        }

        if let zoom = savedZoom {
            updateZoom(zoom)
            savedZoom = nil
        }
    }

    func updateData(_ data: NSDictionary) {
        let json = BridgeUtils.toJson(data)

        let leftX = barLineChart.lowestVisibleX
        barLineChart.data = dataExtract.extract(json)

        if let config = savedVisibleRange {
                updateVisibleRange(config)
        }

        // reset axisMaximum after updating data
        barLineChart.xAxis.axisMaximum = originalXAxisMaximum ?? barLineChart.xAxis.axisMaximum

        barLineChart.moveViewToX(leftX)
        barLineChart.notifyDataSetChanged()
    }
	
    func setDataAndLockIndex(_ data: NSDictionary) {
        let json = BridgeUtils.toJson(data)

        let axis = barLineChart.getAxis(YAxis.AxisDependency.left).enabled ? YAxis.AxisDependency.left : YAxis.AxisDependency.right

        let contentRect = barLineChart.contentRect

        let originCenterValue = barLineChart.valueForTouchPoint(point: CGPoint(x: contentRect.midX, y: contentRect.midY), axis: axis)

        let originalVisibleXRange = barLineChart.visibleXRange
        let originalVisibleYRange = getVisibleYRange(axis)

        barLineChart.fitScreen()
        
        barLineChart.data = dataExtract.extract(json)
        barLineChart.notifyDataSetChanged()
        

        let newVisibleXRange = barLineChart.visibleXRange
        let newVisibleYRange = getVisibleYRange(axis)

        let scaleX = newVisibleXRange / originalVisibleXRange
        let scaleY = newVisibleYRange / originalVisibleYRange

        // in iOS Charts chart.zoom scaleX: CGFloat, scaleY: CGFloat, xValue: Double, yValue: Double, axis: YAxis.AxisDependency)
        // the scale is absolute scale, it will overwrite touchMatrix scale directly
        // but in android MpAndroidChart, ZoomJob getInstance(viewPortHandler, scaleX, scaleY, xValue, yValue, trans, axis, v)
        // the scale is relative scale, touchMatrix.scaleX = touchMatrix.scaleX * scaleX
        // so in iOS, we updateVisibleRange after zoom
        
        barLineChart.zoom(scaleX: CGFloat(scaleX), scaleY: CGFloat(scaleY), xValue: Double(originCenterValue.x), yValue: Double(originCenterValue.y), axis: axis)

        if let config = savedVisibleRange {
            updateVisibleRange(config)
        }
        barLineChart.notifyDataSetChanged()
    }

    func getVisibleYRange(_ axis: YAxis.AxisDependency) -> CGFloat {
        let contentRect = barLineChart.contentRect

        return barLineChart.valueForTouchPoint(point: CGPoint(x: contentRect.maxX, y:contentRect.minY), axis: axis).y - barLineChart.valueForTouchPoint(point: CGPoint(x: contentRect.minX, y:contentRect.maxY), axis: axis).y
    }
    
}
