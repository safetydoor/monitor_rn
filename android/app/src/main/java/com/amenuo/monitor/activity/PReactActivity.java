package com.amenuo.monitor.activity;

import com.amenuo.monitor.MainApplication;
import com.facebook.react.ReactActivity;

public class PReactActivity extends ReactActivity {

    @Override
    protected String getMainComponentName() {
        MainApplication.reactActivity = this;
        return "monitor";
    }
}
