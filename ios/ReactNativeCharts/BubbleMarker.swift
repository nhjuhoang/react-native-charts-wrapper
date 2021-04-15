//
//  BubbleMarker.swift
//  RNCharts
//
//  Created by Taylor Johnson on 6/16/20.
//

import Foundation;
import Charts;
import SwiftyJSON;

// Maybe label X needs to be called vertical and labelY horizontal??
open class BubbleMarker: MarkerView {
    open var color: UIColor?
    open var arrowSize = CGSize(width: 15, height: 11)
    open var font: UIFont?
    open var textColor: UIColor?
    open var minimumSize = CGSize()

    // TODO parameterize
    fileprivate var insets = UIEdgeInsets(top: 3.0,left: 10.0,bottom: 3.0,right: 10.0)

    fileprivate var labelX: NSString?
		fileprivate var labelY: NSString?
    fileprivate var _labelXSize: CGSize = CGSize()
		fileprivate var _labelYSize: CGSize = CGSize()
    fileprivate var _sizeXLabel: CGSize = CGSize()
		fileprivate var _sizeYLabel: CGSize = CGSize()
		// TODO maybe remove and always keep center??
    fileprivate var _paragraphStyle: NSMutableParagraphStyle?
    fileprivate var _drawAttributes = [NSAttributedString.Key: Any]()


  public init(color: UIColor, font: UIFont, textColor: UIColor, textAlign: NSTextAlignment) {
        super.init(frame: CGRect.zero);
        self.color = color
        self.font = font
        self.textColor = textColor

        _paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle
        _paragraphStyle?.alignment = textAlign
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented");
    }


	func drawXHighlightRect(context: CGContext, point: CGPoint) -> CGRect{

        let chart = super.chartView
        let width = _sizeXLabel.width

        var rect = CGRect(origin: point, size: _sizeXLabel)
        rect.origin.x -= _sizeXLabel.width / 2.0

        rect.origin.y = chart?.bounds.minY ?? 0

        if (chart != nil && point.x + width - _sizeXLabel.width / 2.0 > (chart?.bounds.width)!) {
            rect.origin.x = (chart?.viewPortHandler.contentRight)! - _sizeXLabel.width
        } else if point.x - _sizeXLabel.width / 2.0 < 0 {
            rect.origin.x = (chart?.viewPortHandler.contentLeft)!
        }
        drawRect(context: context, rect: rect)

        rect.origin.y += self.insets.top
        rect.size.height -= self.insets.top + self.insets.bottom

        return rect
    }

	func drawYHighlightRect(context: CGContext, point: CGPoint) -> CGRect {
        let chart = super.chartView

        var rect = CGRect(origin: point, size: _sizeYLabel)

        rect.origin.x = (chart?.viewPortHandler.contentRight)! - _sizeYLabel.width
        rect.origin.y -= _sizeYLabel.height / 2.0

        if rect.origin.y < (chart?.viewPortHandler.contentTop)! {
            rect.origin.y = (chart?.viewPortHandler.contentTop)!
        } else if rect.origin.y + _sizeYLabel.height > (chart?.viewPortHandler.contentBottom)! {
            rect.origin.y = (chart?.viewPortHandler.contentBottom)! - _sizeYLabel.height
        }
        drawRect(context: context, rect: rect)

        rect.origin.y += self.insets.top
        rect.size.height -= self.insets.top + self.insets.bottom

        return rect
    }

	func drawRect(context: CGContext, rect: CGRect) {
		context.setFillColor((color?.cgColor)!)
		let clipPath: CGPath = UIBezierPath(roundedRect: rect, cornerRadius: rect.height / 2).cgPath
		context.addPath(clipPath)
		context.fillPath()
	}

    open override func draw(context: CGContext, point: CGPoint) {
        if (labelX == nil || labelX?.length == 0) {
            return
        }

        context.saveGState()

        let rectX = drawXHighlightRect(context: context, point: point)

        labelX?.draw(in: rectX, withAttributes: _drawAttributes)

        let rectY = drawYHighlightRect(context: context, point: point)

        labelY?.draw(in: rectY, withAttributes: _drawAttributes)

        context.restoreGState()
    }

    open override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let chart = chartView as? BarLineChartViewBase
        let axis = chart?.getAxis(highlight.axis)
        labelY = (axis?.valueFormatter?.stringForValue(highlight.y, axis: axis) ?? "") as NSString

        var label : String;
        if let candleEntry = entry as? CandleChartDataEntry {

        label = candleEntry.close.description
        } else {
            label = entry.y.description
        }

        if let object = entry.data as? JSON {
            if object["marker"].exists() {
                label = object["marker"].stringValue;

                if highlight.stackIndex != -1 && object["marker"].array != nil {
                    label = object["marker"].arrayValue[highlight.stackIndex].stringValue
                }
            }
        }

        labelX = label as NSString

        _drawAttributes.removeAll()
        _drawAttributes[NSAttributedString.Key.font] = self.font
        _drawAttributes[NSAttributedString.Key.paragraphStyle] = _paragraphStyle
        _drawAttributes[NSAttributedString.Key.foregroundColor] = self.textColor

        _labelXSize = labelX?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        _sizeXLabel.width = _labelXSize.width + self.insets.left + self.insets.right
        _sizeXLabel.height = _labelXSize.height + self.insets.top + self.insets.bottom
        _sizeXLabel.width = max(minimumSize.width, _sizeXLabel.width)
        _sizeXLabel.height = max(minimumSize.height, _sizeXLabel.height)

        _labelYSize = labelY?.size(withAttributes: _drawAttributes) ?? CGSize.zero
        _sizeYLabel.width = _labelYSize.width + self.insets.left + self.insets.right
        _sizeYLabel.height = _labelYSize.height + self.insets.top + self.insets.bottom
        _sizeYLabel.width = max(minimumSize.width, _sizeYLabel.width)
        _sizeYLabel.height = max(minimumSize.height, _sizeYLabel.height)

    }
}


