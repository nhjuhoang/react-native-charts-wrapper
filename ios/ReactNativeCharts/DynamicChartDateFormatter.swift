//
//  DynamicChartDateFormatter.swift
//  ReactNativeCharts
//
//  Created by Taylor Johnson on 6/5/20.
//

import Foundation
import Charts
import SwiftyJSON

extension Date {
    func isEqual(to date: Date, toGranularity component: Calendar.Component, in calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, equalTo: date, toGranularity: component)
    }

    func isInSameYear(as date: Date) -> Bool { isEqual(to: date, toGranularity: .year) }
    func isInSameMonth(as date: Date) -> Bool { isEqual(to: date, toGranularity: .month) }
    func isInSameWeek(as date: Date) -> Bool { isEqual(to: date, toGranularity: .weekOfYear) }

    func isInSameDay(as date: Date) -> Bool { Calendar.current.isDate(self, inSameDayAs: date) }
}

// assumes values are -Index
// TODO take timeUnit
open class DynamicChartDateFormatter: NSObject, IValueFormatter, IAxisValueFormatter {

    open var dateFormatter = DateFormatter()

	private let isoFormatter = DateFormatter()

	private let _chart: ChartViewBase

	public init(locale: String?, chart: ChartViewBase) {
		self._chart = chart
        self.dateFormatter.timeZone = TimeZone.current
        self.dateFormatter.locale = Locale(identifier: locale ?? Locale.current.languageCode ?? "en_US")
		self.isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    }

    open func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		let entry = _chart.data?.dataSets.first?.entryForXValue(value, closestToY: .nan)
		if entry == nil || entry?.x != value {
			return ""
		}
		guard let date = getDateFromEntry(entry) else { return "" }

        let entries = axis?.entries ?? []
        guard let entryIndex = entries.firstIndex(of: value) else { return "" }

		var previousEntry: ChartDataEntry?
        if (entryIndex == 0) {
            let entryInterval = abs(entries[1] - entries[0])
			previousEntry = _chart.data?.dataSets.first?.entryForXValue(value - entryInterval, closestToY: .nan)
		} else {
			previousEntry = _chart.data?.dataSets.first?.entryForXValue(entries[entryIndex - 1], closestToY: .nan)
		}

		guard let previousDate = getDateFromEntry(previousEntry) else { return "" }

		updateFormatting(date1: date, date2: previousDate)
		return dateFormatter.string(from: date)
    }

    public func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        // TODO impl
        return ""
    }

	private func getDateFromEntry(_ entry: ChartDataEntry?) -> Date? {
		let entryData = entry?.data as! JSON
		guard entryData["date"].string != nil else { return nil }
		guard let date = isoFormatter.date(from: entryData["date"].stringValue) else { return nil }

		return date
	}

    // If value diff > year
        // return year number
    // If value diff > month
        // return month number
    // If value diff > day
        // return day number
    // else
        // return HH:mm
    private func updateFormatting(date1: Date, date2: Date) {
        if (!date1.isInSameYear(as: date2)) {
            dateFormatter.dateFormat = "yyyy"
        } else if (!date1.isInSameMonth(as: date2)) {
            dateFormatter.dateFormat = "MMM"
        } else if (!date1.isInSameDay(as: date2)) {
            dateFormatter.dateFormat = "d"
        } else {
            dateFormatter.dateFormat = "HH:mm"
        }
    }

}
