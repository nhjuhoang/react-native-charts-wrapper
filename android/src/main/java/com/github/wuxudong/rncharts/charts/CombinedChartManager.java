package com.github.wuxudong.rncharts.charts;


import android.util.Log;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.github.mikephil.charting.charts.CombinedChart;
import com.github.mikephil.charting.components.XAxis;
import com.github.mikephil.charting.data.BarDataSet;
import com.github.mikephil.charting.data.BarEntry;
import com.github.mikephil.charting.data.BarLineScatterCandleBubbleData;
import com.github.mikephil.charting.data.CandleDataSet;
import com.github.mikephil.charting.data.CandleEntry;
import com.github.mikephil.charting.data.DataSet;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineDataSet;
import com.github.wuxudong.rncharts.data.CombinedDataExtract;
import com.github.wuxudong.rncharts.data.DataExtract;
import com.github.wuxudong.rncharts.listener.RNOnChartGestureListener;
import com.github.wuxudong.rncharts.listener.RNOnChartValueSelectedListener;
import com.github.wuxudong.rncharts.utils.BridgeUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import javax.annotation.Nullable;

public class CombinedChartManager extends BarLineChartBaseManager<CombinedChart, Entry> {

    @Override
    public String getName() {
        return "RNCombinedChart";
    }

    @Override
    protected CombinedChart createViewInstance(ThemedReactContext reactContext) {
        CombinedChart combinedChart = new CombinedChart(reactContext);
        combinedChart.setOnChartValueSelectedListener(new RNOnChartValueSelectedListener(combinedChart));
        combinedChart.setOnChartGestureListener(new RNOnChartGestureListener(combinedChart));
        combinedChart.setRenderer(new BFCombinedChartRenderer(combinedChart, combinedChart.getAnimator(), combinedChart.getViewPortHandler()));
        return combinedChart;
    }

    @Nullable
    @Override
    public Map<String, Integer> getCommandsMap() {
        Map<String, Integer> commandsMap = super.getCommandsMap();

        Map<String, Integer> map = MapBuilder.of(
                "appendN", APPEND_N,
                "updateFirstN", UPDATE_FIRST_N);

        if (commandsMap != null) {
            map.putAll(commandsMap);
        }
        return map;
    }

    @Override
    public void receiveCommand(CombinedChart root, int commandId, @Nullable ReadableArray args) {
        switch(commandId) {
            case APPEND_N:
                appendN(root, args.getMap(0));
                return;
            case UPDATE_FIRST_N:
                updateFirstN(root, args.getMap(0));
                return;
        }
        super.receiveCommand(root, commandId, args);
    }

    @ReactProp(name = "drawOrder")
    public void setDrawOrder(CombinedChart chart, ReadableArray array) {
        List<CombinedChart.DrawOrder> orders = new ArrayList<>();

        for (int i = 0; i < array.size(); i++) {
            orders.add(CombinedChart.DrawOrder.valueOf(array.getString(i)));
        }

        chart.setDrawOrder(orders.toArray(new CombinedChart.DrawOrder[orders.size()]));
    }

    @ReactProp(name = "drawValueAboveBar")
    public void setDrawValueAboveBar(CombinedChart chart, boolean enabled) {
        chart.setDrawValueAboveBar(enabled);
    }

    @ReactProp(name = "drawBarShadow")
    public void setDrawBarShadow(CombinedChart chart, boolean enabled) {
        chart.setDrawBarShadow(enabled);
    }

    @ReactProp(name = "highlightFullBarEnabled")
    public void setHighlightFullBarEnabled(CombinedChart chart, boolean enabled) {
        chart.setHighlightFullBarEnabled(enabled);
    }

    @Override
    DataExtract getDataExtract() {
        return new CombinedDataExtract();
    }

    private void appendN(CombinedChart chart, ReadableMap data) {
        CombinedDataExtract combinedDataExtract = (CombinedDataExtract) getDataExtract();
        int dataAdded = 0;

        dataAdded = updateEntriesForKey("barEntries", data, chart.getBarData(), combinedDataExtract.barDataExtract, false);
        updateEntriesForKey("candleEntries", data, chart.getCandleData(), combinedDataExtract.candleDataExtract, false);
        updateEntriesForKey("lineEntries", data, chart.getLineData(), combinedDataExtract.lineDataExtract, false);

        // update the axis maximum for each data point we added
        // might be better to rely on the original axis maximum compared to original highest x, and then increment?
        XAxis xAxis = chart.getXAxis();
        xAxis.setAxisMaximum(xAxis.mAxisMaximum + dataAdded);

        chart.notifyDataSetChanged();
        chart.postInvalidate();
    }

    private void updateFirstN(CombinedChart chart, ReadableMap data) {
        CombinedDataExtract combinedDataExtract = (CombinedDataExtract) getDataExtract();

        updateEntriesForKey("barEntries", data, chart.getBarData(), combinedDataExtract.barDataExtract, true);
        updateEntriesForKey("candleEntries", data, chart.getCandleData(), combinedDataExtract.candleDataExtract, true);
        updateEntriesForKey("lineEntries", data, chart.getLineData(), combinedDataExtract.lineDataExtract, true);

        chart.notifyDataSetChanged();
        chart.postInvalidate();
    }

    private int updateEntriesForKey(String key, ReadableMap newData, BarLineScatterCandleBubbleData data, DataExtract extractor, boolean removeEntry) {
        if (BridgeUtils.validate(newData, ReadableType.Array, key) && data != null) {
            ArrayList entries = extractor.createEntries(newData.getArray(key));
            DataSet dataSet = (DataSet) data.getDataSets().get(0);

            for (int i = 0; i < entries.size(); i++) {
                Entry entry = (Entry) entries.get(i);
                if (removeEntry)
                    dataSet.removeEntryByXValue(entry.getX());
                dataSet.addEntryOrdered(entry);
            }
            return entries.size();
        }
        return 0;
    }
}
