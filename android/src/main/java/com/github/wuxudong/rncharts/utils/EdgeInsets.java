package com.github.wuxudong.rncharts.utils;

import com.github.mikephil.charting.utils.Utils;

public class EdgeInsets {
    public float left;
    public float top;
    public float right;
    public float bottom;

    public EdgeInsets(float l, float t, float r, float b) {
        left = Utils.convertDpToPixel(l);
        top = Utils.convertDpToPixel(t);
        right = Utils.convertDpToPixel(r);
        bottom = Utils.convertDpToPixel(b);
    }

    public float getTotalVerticalInset() {
        return this.top + this.bottom;
    }

    public float getTotalHorizontalInset() {
        return this.left + this.right;
    }
}
