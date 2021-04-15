//
//  BFCombinedChartView.swift
//  RNCharts
//
//  Created by Taylor Johnson on 6/17/20.
//

import Foundation
import Charts

open class BFCombinedChartView: CombinedChartView {
	
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

            (renderer as? BFCombinedChartRenderer)?.createRenderers()
            renderer?.initBuffers()
        }
	}
}
