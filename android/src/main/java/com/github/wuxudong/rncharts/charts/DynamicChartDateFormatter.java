package com.github.wuxudong.rncharts.charts;

import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.components.AxisBase;
import com.github.mikephil.charting.data.DataSet;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.formatter.ValueFormatter;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.TimeZone;

public class DynamicChartDateFormatter extends ValueFormatter {
    private SimpleDateFormat mSimpleDateFormat;
    private SimpleDateFormat mISODateParser = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.ENGLISH);
    private Calendar mCalendar = Calendar.getInstance();
    private Chart mChart;

    public DynamicChartDateFormatter(Locale locale, Chart chart) {
        this.mSimpleDateFormat = new SimpleDateFormat("HH:mm", locale);
        this.mSimpleDateFormat.setTimeZone(TimeZone.getDefault());
        this.mChart = chart;
        this.mISODateParser.setTimeZone(TimeZone.getTimeZone("GMT"));
    }

    @Override
    public String getAxisLabel(float value, AxisBase axis) {
        DataSet dataSet = (DataSet) mChart.getData().getDataSetByIndex(0);
        Entry entry = dataSet.getEntryForXValue(value, Float.NaN);

        if (entry == null || entry.getX() != value) {
            return "";
        }

        Date date = getDateFromEntry(entry);
        if (date == null) {
            return "";
        }

        int entryIndex = getEntryIndexForValue(value, axis);
        if (entryIndex < 0) {
            return "";
        }
        Entry previousEntry;
        if (entryIndex == 0) {
            float entryInterval = Math.abs(axis.mEntries[1] - axis.mEntries[0]);
            previousEntry = dataSet.getEntryForXValue(value - entryInterval, Float.NaN);
        } else {
            previousEntry = dataSet.getEntryForXValue(axis.mEntries[entryIndex - 1], Float.NaN);
        }

        Date previousDate = getDateFromEntry(previousEntry);
        if (previousDate == null) {
            return "";
        }

        updateFormatting(date, previousDate);

        return mSimpleDateFormat.format(date);
    }

    private Date getDateFromEntry(Entry entry) {
        HashMap data = (HashMap) entry.getData();
        String dateString = (String) data.get("date");

        try {
            return mISODateParser.parse(dateString);
        } catch (ParseException e) {
            return null;
        }
    }

    private int getEntryIndexForValue(float value, AxisBase axis) {
        for (int i = 0; i < axis.mEntryCount; i++) {
            if (value == axis.mEntries[i]) {
                return i;
            }
        }
        return -1;
    }

    // If value diff > year
    // return year number
    // If value diff > month
    // return month number
    // If value diff > day
    // return day number
    // else
    // return HH:mm
    private void updateFormatting(Date date1, Date date2) {
        mCalendar.setTime(date1);
        int year1 = mCalendar.get(Calendar.YEAR);
        int month1 = mCalendar.get(Calendar.MONTH);
        int day1 = mCalendar.get(Calendar.DAY_OF_MONTH);
        mCalendar.setTime(date2);
        int year2 = mCalendar.get(Calendar.YEAR);
        int month2 = mCalendar.get(Calendar.MONTH);
        int day2 = mCalendar.get(Calendar.DAY_OF_MONTH);

        if (year1 != year2) {
            mSimpleDateFormat.applyPattern("yyyy");
        } else if (month1 != month2) {
            mSimpleDateFormat.applyPattern("MMM");
        } else if (day1 != day2) {
            mSimpleDateFormat.applyPattern("d");
        } else {
            mSimpleDateFormat.applyPattern("HH:mm");
        }
    }
}
