//  Created by xudong wu on 24/02/2017.
//  Copyright wuxudong
//

import Charts
import SwiftyJSON

class RNCombinedChartView: RNBarLineChartViewBase {

    let _chart: CombinedChartView;
    let _dataExtract : CombinedDataExtract;

    override var chart: CombinedChartView {
        return _chart
    }
    
    override var dataExtract: DataExtract {
        return _dataExtract
    }    

    override init(frame: CoreGraphics.CGRect) {

        self._chart = BFCombinedChartView(frame: frame)
        self._chart.renderer = BFCombinedChartRenderer(chart: self._chart, animator: self._chart.chartAnimator, viewPortHandler: self._chart.viewPortHandler)
        self._dataExtract = CombinedDataExtract()

        super.init(frame: frame)

        self._chart.delegate = self
        self.addSubview(_chart)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setDrawOrder(_ config: NSArray) {
        var array : [Int] = []
        for object in RCTConvert.nsStringArray(config) {
            array.append(BridgeUtils.parseDrawOrder(object).rawValue)
        }
        _chart.drawOrder = array
    }
    
    func setDrawValueAboveBar(_ enabled: Bool) {
        _chart.drawValueAboveBarEnabled = enabled
    }

    func setDrawBarShadow(_ enabled: Bool) {
        _chart.drawBarShadowEnabled = enabled
    }

    func setHighlightFullBarEnabled(_ enabled: Bool) {
        _chart.highlightFullBarEnabled = enabled
    }

    func updateFirstN(_ data: NSDictionary) {
    		let json = BridgeUtils.toJson(data)
    		let allData = self.chart.combinedData!.allData

    		for data in allData {
    			// must update specific data type by finding the respective key in the json
    			switch (data) {
    			case is CandleChartData:
    				if json["candleEntries"].array != nil {
    					_updateDataSetForEntries(json["candleEntries"].arrayValue, data: data, extractor: self._dataExtract.candleDataExtract, removeEntry: true)
    				}
    				break
    			case is BarChartData:
    				if json["barEntries"].array != nil {
    					_updateDataSetForEntries(json["barEntries"].arrayValue, data: data, extractor: self._dataExtract.barDataExtract, removeEntry: true)
    				}
    				break
    			case is LineChartData:
    				if json["lineEntries"].array != nil {
    					_updateDataSetForEntries(json["lineEntries"].arrayValue, data: data, extractor: self._dataExtract.lineDataExtract, removeEntry: true)
    				}
    				break
    			default:
    				break
    			}
    		}
    		self.chart.notifyDataSetChanged()
    	}

    	func appendN(_ data: NSDictionary) {
    		let json = BridgeUtils.toJson(data)
    		let allData = self.chart.combinedData!.allData
    		var entriesAdded = 0

    		for data in allData {
    			// must update specific data type by finding the respective key in the json
    			switch (data) {
    			case is CandleChartData:
    				if json["candleEntries"].array != nil {
    					_updateDataSetForEntries(json["candleEntries"].arrayValue, data: data, extractor: self._dataExtract.candleDataExtract, removeEntry: false)
    				}
    				break
    			case is BarChartData:
    				if json["barEntries"].array != nil {
    					let barsAdded = _updateDataSetForEntries(json["barEntries"].arrayValue, data: data, extractor: self._dataExtract.barDataExtract, removeEntry: false)
    					// use bars as source of truth for number of added entries
    					if barsAdded > entriesAdded {
    						entriesAdded = barsAdded
    					}
    				}
    				break
    			case is LineChartData:
    				if json["lineEntries"].array != nil {
    					_updateDataSetForEntries(json["lineEntries"].arrayValue, data: data, extractor: self._dataExtract.barDataExtract, removeEntry: false)
    				}
    				break
    			default:
    				break
    			}
    		}

    		// update max X in visible range since we've added more data
    		let xAxisMaximum = chart.xAxis.axisMaximum + Double(entriesAdded)
    		chart.xAxis.axisMaximum = xAxisMaximum

    		self.chart.notifyDataSetChanged()
    	}

    	@discardableResult private func _updateDataSetForEntries(_ jsonEntries: [JSON], data: ChartData, extractor: DataExtract, removeEntry: Bool) -> Int {
    		let entries = extractor.createEntries(jsonEntries)
    		let dataSet = data.dataSets.first

    		for entry in entries {
    			if removeEntry {
    				dataSet?.removeEntry(x: entry.x)
    			}
    			dataSet?.addEntryOrdered(entry)
    		}
    		return entries.count
    	}
}
