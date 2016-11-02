package com.amenuo.monitor;

import android.app.Activity;
import android.content.Context;

import com.amenuo.monitor.utils.SPHelper;
import com.facebook.react.ReactApplication;
import com.facebook.react.ReactNativeHost;
import com.facebook.react.ReactPackage;
import com.facebook.react.shell.MainReactPackage;
import com.jwkj.global.MyApp;

import java.util.Arrays;
import java.util.List;

public class MainApplication extends MyApp implements ReactApplication {

    private static MainApplication application;
    public static Activity reactActivity;

    @Override
    public void onCreate() {
        super.onCreate();
        SPHelper.getInstance().init(this.getApplicationContext());
        application = this;
    }

    public static Context getContext() {
        if (application != null) {
            return application.getApplicationContext();
        }
        return null;
    }

    private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
        @Override
        protected boolean getUseDeveloperSupport() {
            return BuildConfig.DEBUG;
        }

        @Override
        protected List<ReactPackage> getPackages() {
            return Arrays.<ReactPackage>asList(
                    new MainReactPackage(),
                    new PReactPackage()
            );
        }
    };

    @Override
    public ReactNativeHost getReactNativeHost() {
        return mReactNativeHost;
    }
}
