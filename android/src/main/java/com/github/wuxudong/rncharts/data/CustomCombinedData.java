package com.github.wuxudong.rncharts.data;

import com.github.mikephil.charting.data.ChartData;
import com.github.mikephil.charting.data.CombinedData;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.highlight.Highlight;

public class CustomCombinedData extends CombinedData {
    /**
     * Get the Entry for a corresponding highlight object
     *
     * returns first entry available
     *
     * @param highlight
     * @return the entry that is highlighted
     */
    @Override
    public Entry getEntryForHighlight(Highlight highlight) {

        if (highlight.getDataIndex() >= getAllData().size())
            return null;

        ChartData data = getDataByIndex(highlight.getDataIndex());

        if (highlight.getDataSetIndex() >= data.getDataSetCount())
            return null;

        // The value of the highlighted entry could be NaN -
        //   if we are not interested in highlighting a specific value.

        Entry firstEntry = data.getDataSetByIndex(highlight.getDataSetIndex()).getEntryForXValue(highlight.getX(), Float.NaN);
        if (firstEntry != null) {
            return firstEntry;
        }

        return null;
    }
}
