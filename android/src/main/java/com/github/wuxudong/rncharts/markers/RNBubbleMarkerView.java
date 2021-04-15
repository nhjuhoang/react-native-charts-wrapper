package com.github.wuxudong.rncharts.markers;

import android.content.Context;
import android.graphics.*;

import com.github.mikephil.charting.charts.BarLineChartBase;
import com.github.mikephil.charting.components.MarkerView;
import com.github.mikephil.charting.components.YAxis;
import com.github.mikephil.charting.data.CandleEntry;
import com.github.mikephil.charting.data.Entry;
import com.github.mikephil.charting.highlight.Highlight;
import com.github.mikephil.charting.utils.MPPointF;
import com.github.mikephil.charting.utils.Utils;
import com.github.wuxudong.rncharts.R;
import com.github.wuxudong.rncharts.utils.EdgeInsets;

import java.util.List;
import java.util.Map;

public class RNBubbleMarkerView extends MarkerView {

    private final EdgeInsets insets = new EdgeInsets(10, 3, 10, 3);

    private final Paint mTextPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint mRectPaint = new Paint(Paint.ANTI_ALIAS_FLAG);

    private String mVerticalMarkerText;
    private final Rect mVerticalMarkerTextBounds = new Rect();

    private String mHorizontalMarkerText;
    private final Rect mHorizontalMarkerTextBounds = new Rect();

    public RNBubbleMarkerView(Context context, int color, int textColor, int textSize) {
        super(context, R.layout.bubble_marker);

        float mTextSize = Utils.convertDpToPixel(textSize);

        mRectPaint.setColor(color);
        mRectPaint.setStyle(Paint.Style.FILL);
        mTextPaint.setColor(textColor);
        mTextPaint.setTextSize(mTextSize);
    }

    @Override
    public void refreshContent(Entry e, Highlight highlight) {
        BarLineChartBase chart = (BarLineChartBase) super.getChartView();
        YAxis yAxis = chart.getAxis(highlight.getAxis());
        mHorizontalMarkerText = yAxis.getValueFormatter().getAxisLabel(highlight.getY(), yAxis);

        if (e instanceof CandleEntry) {
            CandleEntry ce = (CandleEntry) e;
            mVerticalMarkerText = Utils.formatNumber(ce.getClose(), 0, false);
        } else {
            mVerticalMarkerText = Utils.formatNumber(e.getY(), 0, false);
        }

        if (e.getData() instanceof Map) {
            if (((Map) e.getData()).containsKey("marker")) {

                Object marker = ((Map) e.getData()).get("marker");
                mVerticalMarkerText = marker.toString();

                if (highlight.getStackIndex() != -1 && marker instanceof List) {
                    mVerticalMarkerText = ((List) marker).get(highlight.getStackIndex()).toString();
                }

            }
        }

        mTextPaint.getTextBounds(mVerticalMarkerText, 0, mVerticalMarkerText.length(), mVerticalMarkerTextBounds);
        mTextPaint.getTextBounds(mHorizontalMarkerText, 0, mHorizontalMarkerText.length(), mHorizontalMarkerTextBounds);

        super.refreshContent(e, highlight);
    }

    @Override
    public void draw(Canvas canvas, float posX, float posY) {

        drawVerticalMarkerRect(canvas, posX);
        drawHorizontalMarkerRect(canvas, posY);

        int saveId = canvas.save();
        // translate to the correct position and draw
        canvas.translate(posX, posY);
        draw(canvas);
        canvas.restoreToCount(saveId);
    }

    private void drawVerticalMarkerRect(Canvas canvas, float posX) {
        BarLineChartBase chart = (BarLineChartBase) super.getChartView();
        float totalWidth = mVerticalMarkerTextBounds.width() + insets.getTotalHorizontalInset();
        int sideOffset = mVerticalMarkerTextBounds.width() >> 1;
        float rectHeight = mVerticalMarkerTextBounds.height() + insets.getTotalVerticalInset();
        float cornerRadius = rectHeight / 2;
        float left = posX - (sideOffset + insets.left);

        if (posX + sideOffset + insets.right > chart.getViewPortHandler().contentRight()) {
            left = chart.getViewPortHandler().contentRight() - totalWidth;
        } else if (posX - (sideOffset + insets.left) < chart.getViewPortHandler().contentLeft()) {
            left = chart.getViewPortHandler().contentLeft();
        }

        canvas.drawRoundRect(left, 0, left + totalWidth, rectHeight, cornerRadius, cornerRadius, mRectPaint);
        canvas.drawText(mVerticalMarkerText, left + insets.left, mVerticalMarkerTextBounds.height() + insets.top, mTextPaint);
    }

    private void drawHorizontalMarkerRect(Canvas canvas, float posY) {
        BarLineChartBase chart = (BarLineChartBase) super.getChartView();
        float rectHeight = mHorizontalMarkerTextBounds.height() + insets.getTotalVerticalInset();
        float rectWidth = mHorizontalMarkerTextBounds.width() + insets.getTotalHorizontalInset();
        float rectTop = posY - rectHeight / 2;
        float cornerRadius = rectHeight / 2;

        if (rectTop < chart.getViewPortHandler().contentTop()) {
            rectTop = chart.getViewPortHandler().contentTop();
        } else if (rectTop + rectHeight > chart.getViewPortHandler().contentBottom()) {
            rectTop = chart.getViewPortHandler().contentBottom() - rectHeight;
        }

        canvas.drawRoundRect(canvas.getWidth() - rectWidth, rectTop, canvas.getWidth(), rectTop + rectHeight, cornerRadius, cornerRadius, mRectPaint);
        canvas.drawText(mHorizontalMarkerText, canvas.getWidth() - mHorizontalMarkerTextBounds.width() - insets.right, rectTop + mHorizontalMarkerTextBounds.height() + insets.top, mTextPaint);
    }

}
