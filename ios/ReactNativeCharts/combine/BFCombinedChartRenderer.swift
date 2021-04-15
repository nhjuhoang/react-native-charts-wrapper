//
//  BFCombinedChartRenderer.swift
//  RNCharts
//
//  Created by Taylor Johnson on 6/17/20.
//

import Foundation
import Charts

// Support Highlighting Candle and Line charts where the horizontal highlight
// line follows the Highlight's y value
class BFCombinedChartRenderer: CombinedChartRenderer {
	
	@objc public override init(chart: CombinedChartView, animator: Animator, viewPortHandler: ViewPortHandler)
     {
        super.init(chart: chart, animator: animator, viewPortHandler: viewPortHandler)

         self.chart = chart

         createRenderers()
     }

     /// Creates the renderers needed for this combined-renderer in the required order. Also takes the DrawOrder into consideration.
     internal func createRenderers()
     {
         subRenderers = [DataRenderer]()

         guard let chart = chart else { return }

         for order in drawOrder
         {
             switch (order)
             {
             case .bar:
                 if chart.barData !== nil
                 {
                     subRenderers.append(BarChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                 }
                 break

             case .line:
                 if chart.lineData !== nil
                 {
                     subRenderers.append(BFLineChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                 }
                 break

             case .candle:
                 if chart.candleData !== nil
                 {
                     subRenderers.append(BFCandleStickChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                 }
                 break

             case .scatter:
                 if chart.scatterData !== nil
                 {
                     subRenderers.append(ScatterChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                 }
                 break

             case .bubble:
                 if chart.bubbleData !== nil
                 {
                     subRenderers.append(BubbleChartRenderer(dataProvider: chart, animator: animator, viewPortHandler: viewPortHandler))
                 }
                 break
             }
         }

     }

	open override func drawHighlighted(context: CGContext, indices: [Highlight])
	{
        for renderer in subRenderers
        {
            var data: ChartData?

            if renderer is BarChartRenderer
            {
                data = (renderer as! BarChartRenderer).dataProvider?.barData
            }
            else if renderer is LineChartRenderer
            {
                data = (renderer as! BFLineChartRenderer).dataProvider?.lineData
            }
            else if renderer is CandleStickChartRenderer
            {
                data = (renderer as! BFCandleStickChartRenderer).dataProvider?.candleData
            }
            else if renderer is ScatterChartRenderer
            {
                data = (renderer as! ScatterChartRenderer).dataProvider?.scatterData
            }
            else if renderer is BubbleChartRenderer
            {
                data = (renderer as! BubbleChartRenderer).dataProvider?.bubbleData
            }

            let dataIndex: Int? = {
                guard let data = data else { return nil }
                return (chart?.data as? CombinedChartData)?
                        .allData
                        .firstIndex(of: data)
            }()

            let dataIndices = indices.filter{ $0.dataIndex == dataIndex || $0.dataIndex == -1 }

            renderer.drawHighlighted(context: context, indices: dataIndices)
        }
	}


	class BFCandleStickChartRenderer: CandleStickChartRenderer {

		/// Checks if the provided entry object is in bounds for drawing considering the current animation phase.
		internal func isInBoundsX(entry e: ChartDataEntry, dataSet: IBarLineScatterCandleBubbleChartDataSet) -> Bool
		{
            let entryIndex = dataSet.entryIndex(entry: e)
            return Double(entryIndex) < Double(dataSet.entryCount) * animator.phaseX
		}

		open override func drawHighlighted(context: CGContext, indices: [Highlight])
		{
            guard
                let dataProvider = dataProvider,
                let candleData = dataProvider.candleData
                else { return }

            context.saveGState()

            for high in indices
            {
                    guard
                        let set = candleData.getDataSetByIndex(high.dataSetIndex) as? ICandleChartDataSet,
                        set.isHighlightEnabled
                        else { continue }

                    guard let e = set.entryForXValue(high.x, closestToY: high.y) as? CandleChartDataEntry else { continue }

                    if !isInBoundsX(entry: e, dataSet: set)
                    {
                        continue
                    }

                    let trans = dataProvider.getTransformer(forAxis: set.axisDependency)

                    context.setStrokeColor(set.highlightColor.cgColor)
                    context.setLineWidth(set.highlightLineWidth)

                    if set.highlightLineDashLengths != nil
                    {
                        context.setLineDash(phase: set.highlightLineDashPhase, lengths: set.highlightLineDashLengths!)
                    }
                    else
                    {
                        context.setLineDash(phase: 0.0, lengths: [])
                    }

                    let pt = trans.pixelForValues(x: e.x, y: high.y)

                    high.setDraw(pt: pt)

                    // draw the lines
                    drawHighlightLines(context: context, point: pt, set: set)
            }

            context.restoreGState()
		}
	}


	class BFLineChartRenderer: LineChartRenderer {

		/// Checks if the provided entry object is in bounds for drawing considering the current animation phase.
		internal func isInBoundsX(entry e: ChartDataEntry, dataSet: IBarLineScatterCandleBubbleChartDataSet) -> Bool
		{
            let entryIndex = dataSet.entryIndex(entry: e)
            return Double(entryIndex) < Double(dataSet.entryCount) * animator.phaseX
		}

		open override func drawHighlighted(context: CGContext, indices: [Highlight])
		{
            guard
                let dataProvider = dataProvider,
                let lineData = dataProvider.lineData
                else { return }

            let chartXMax = dataProvider.chartXMax

            context.saveGState()

            for high in indices
            {
                    guard let set = lineData.getDataSetByIndex(high.dataSetIndex) as? ILineChartDataSet
                            , set.isHighlightEnabled
                            else { continue }

                    guard let e = set.entryForXValue(high.x, closestToY: high.y) else { continue }

                    if !isInBoundsX(entry: e, dataSet: set)
                    {
                            continue
                    }

                    context.setStrokeColor(set.highlightColor.cgColor)
                    context.setLineWidth(set.highlightLineWidth)
                    if set.highlightLineDashLengths != nil
                    {
                            context.setLineDash(phase: set.highlightLineDashPhase, lengths: set.highlightLineDashLengths!)
                    }
                    else
                    {
                            context.setLineDash(phase: 0.0, lengths: [])
                    }

                    let x = e.x // get the x-position
                    let y = high.y

                    if x > chartXMax * animator.phaseX
                    {
                            continue
                    }

                    let trans = dataProvider.getTransformer(forAxis: set.axisDependency)

                    let pt = trans.pixelForValues(x: x, y: y)

                    high.setDraw(pt: pt)

                    // draw the lines
                    drawHighlightLines(context: context, point: pt, set: set)
            }

            context.restoreGState()
		}
	}

}
