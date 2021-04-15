package com.github.wuxudong.rncharts.charts;

import com.facebook.react.uimanager.ThemedReactContext;
import com.github.mikephil.charting.charts.CandleStickChart;
import com.github.mikephil.charting.data.CandleEntry;
import com.github.wuxudong.rncharts.data.CandleDataExtract;
import com.github.wuxudong.rncharts.data.DataExtract;
import com.github.wuxudong.rncharts.listener.RNOnChartGestureListener;
import com.github.wuxudong.rncharts.listener.RNOnChartValueSelectedListener;

public class CandleStickChartManager extends BarLineChartBaseManager<CandleStickChart, CandleEntry> {

    @Override
    public String getName() {
        return "RNCandleStickChart";
    }

    @Override
    protected CandleStickChart createViewInstance(ThemedReactContext reactContext) {
        CandleStickChart candleStickChart = new CandleStickChart(reactContext);
        candleStickChart.setOnChartValueSelectedListener(new RNOnChartValueSelectedListener(candleStickChart));
        candleStickChart.setOnChartGestureListener(new RNOnChartGestureListener(candleStickChart));
        // cheat set setDrawOrder before combinedChart lib default
        combinedChart.setDrawOrder(
                new CombinedChart.DrawOrder[]{
                        CombinedChart.DrawOrder.CANDLE,
                        CombinedChart.DrawOrder.LINE,
                }
        );
        return candleStickChart;
    }


    @Override
    DataExtract getDataExtract() {
        return new CandleDataExtract();
    }
}
