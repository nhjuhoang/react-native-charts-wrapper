//
//  CustomCombinedChartData.swift
//  RNCharts
//
//  Created by Taylor Johnson on 6/17/20.
//

import Foundation
import Charts

class CustomCombinedChartData: CombinedChartData {
	open override func entryForHighlight(_ highlight: Highlight) -> ChartDataEntry? {
		if highlight.dataIndex >= allData.count
		{
            return nil
		}
		
		let data = dataByIndex(highlight.dataIndex)
		
		if highlight.dataSetIndex >= data.dataSetCount
		{
				return nil
		}
		
		
		let entries = data.getDataSetByIndex(highlight.dataSetIndex).entriesForXValue(highlight.x)
		return entries[0]
	}
}
