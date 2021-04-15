package com.github.wuxudong.rncharts.charts;

import android.graphics.Canvas;
import com.github.mikephil.charting.animation.ChartAnimator;
import com.github.mikephil.charting.charts.Chart;
import com.github.mikephil.charting.charts.CombinedChart;
import com.github.mikephil.charting.data.CandleData;
import com.github.mikephil.charting.data.CandleEntry;
import com.github.mikephil.charting.data.ChartData;
import com.github.mikephil.charting.data.CombinedData;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.data.LineData;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.interfaces.dataprovider.*;
import com.github.mikephil.charting.interfaces.datasets.ICandleDataSet;
import com.github.mikephil.charting.interfaces.datasets.ILineDataSet;
import com.github.mikephil.charting.renderer.*;
import com.github.mikephil.charting.utils.MPPointD;
import com.github.mikephil.charting.utils.ViewPortHandler;

public class BFCombinedChartRenderer extends CombinedChartRenderer {
    public BFCombinedChartRenderer(CombinedChart chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
        super(chart, animator, viewPortHandler);
    }

    /**
     * Creates the renderers needed for this combined-renderer in the required order. Also takes the DrawOrder into
     * consideration.
     */
    @Override
    public void createRenderers() {

        mRenderers.clear();

        CombinedChart chart = (CombinedChart)mChart.get();
        if (chart == null)
            return;

        CombinedChart.DrawOrder[] orders = chart.getDrawOrder();

        for (CombinedChart.DrawOrder order : orders) {

            switch (order) {
                case BAR:
                    if (chart.getBarData() != null)
                        mRenderers.add(new BFBarChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case BUBBLE:
                    if (chart.getBubbleData() != null)
                        mRenderers.add(new BFBubbleChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case LINE:
                    if (chart.getLineData() != null)
                        mRenderers.add(new BFLineChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case CANDLE:
                    if (chart.getCandleData() != null)
                        mRenderers.add(new BFCandleStickChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
                case SCATTER:
                    if (chart.getScatterData() != null)
                        mRenderers.add(new BFScatterChartRenderer(chart, mAnimator, mViewPortHandler));
                    break;
            }
        }
    }

    @Override
    public void drawHighlighted(Canvas c, Highlight[] indices) {

        Chart chart = mChart.get();
        if (chart == null) return;

        for (DataRenderer renderer : mRenderers) {
            ChartData data = null;

            if (renderer instanceof BFBarChartRenderer)
                data = ((BFBarChartRenderer)renderer).getChartDataProvider().getBarData();
            else if (renderer instanceof BFLineChartRenderer)
                data = ((BFLineChartRenderer)renderer).getChartDataProvider().getLineData();
            else if (renderer instanceof BFCandleStickChartRenderer)
                data = ((BFCandleStickChartRenderer)renderer).getChartDataProvider().getCandleData();
            else if (renderer instanceof BFScatterChartRenderer)
                data = ((BFScatterChartRenderer)renderer).getChartDataProvider().getScatterData();
            else if (renderer instanceof BFBubbleChartRenderer)
                data = ((BFBubbleChartRenderer)renderer).getChartDataProvider().getBubbleData();

            int dataIndex = data == null ? -1
                    : ((CombinedData)chart.getData()).getAllData().indexOf(data);

            mHighlightBuffer.clear();

            for (Highlight h : indices) {
                if (h.getDataIndex() == dataIndex || h.getDataIndex() == -1)
                    mHighlightBuffer.add(h);
            }

            renderer.drawHighlighted(c, mHighlightBuffer.toArray(new Highlight[mHighlightBuffer.size()]));
        }
    }

    static class BFCandleStickChartRenderer extends CandleStickChartRenderer {
        public BFCandleStickChartRenderer(CandleDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
            super(chart, animator, viewPortHandler);
        }

        protected CandleDataProvider getChartDataProvider() {
            return mChart;
        }

        @Override
        public void drawHighlighted(Canvas c, Highlight[] indices) {

            CandleData candleData = mChart.getCandleData();

            for (Highlight high : indices) {

                ICandleDataSet set = candleData.getDataSetByIndex(high.getDataSetIndex());

                if (set == null || !set.isHighlightEnabled())
                    continue;

                CandleEntry e = set.getEntryForXValue(high.getX(), high.getY());

                if (!isInBoundsX(e, set))
                    continue;

                MPPointD pix = mChart.getTransformer(set.getAxisDependency()).getPixelForValues(e.getX(), high.getY());

                high.setDraw((float) pix.x, (float) pix.y);

                // draw the lines
                drawHighlightLines(c, (float) pix.x, (float) pix.y, set);
            }
        }
    }

    static class BFBarChartRenderer extends BarChartRenderer {
        public BFBarChartRenderer(BarDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
            super(chart, animator, viewPortHandler);
        }

        protected BarDataProvider getChartDataProvider() {
            return mChart;
        }
    }

    static class BFLineChartRenderer extends LineChartRenderer {
        public BFLineChartRenderer(LineDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
            super(chart, animator, viewPortHandler);
        }

        protected LineDataProvider getChartDataProvider() {
            return mChart;
        }

        @Override
        public void drawHighlighted(Canvas c, Highlight[] indices) {

            LineData lineData = mChart.getLineData();

            for (Highlight high : indices) {

                ILineDataSet set = lineData.getDataSetByIndex(high.getDataSetIndex());

                if (set == null || !set.isHighlightEnabled())
                    continue;

                Entry e = set.getEntryForXValue(high.getX(), high.getY());

                if (!isInBoundsX(e, set))
                    continue;

                MPPointD pix = mChart.getTransformer(set.getAxisDependency()).getPixelForValues(e.getX(), high.getY());

                high.setDraw((float) pix.x, (float) pix.y);

                // draw the lines
                drawHighlightLines(c, (float) pix.x, (float) pix.y, set);
            }
        }
    }

    static class BFScatterChartRenderer extends ScatterChartRenderer {
        public BFScatterChartRenderer(ScatterDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
            super(chart, animator, viewPortHandler);
        }

        protected ScatterDataProvider getChartDataProvider() {
            return mChart;
        }
    }

    static class BFBubbleChartRenderer extends BubbleChartRenderer {
        public BFBubbleChartRenderer(BubbleDataProvider chart, ChartAnimator animator, ViewPortHandler viewPortHandler) {
            super(chart, animator, viewPortHandler);
        }

        protected BubbleDataProvider getChartDataProvider() {
            return mChart;
        }
    }
}
