package com.amenuo.monitor;

import android.content.Intent;

import com.amenuo.monitor.action.LoginStateAction;
import com.amenuo.monitor.action.WXAction;
import com.amenuo.monitor.activity.LivePlayerActivity;
import com.amenuo.monitor.model.WeatherModel;
import com.amenuo.monitor.task.LoginTask;
import com.amenuo.monitor.task.RegisterTask;
import com.amenuo.monitor.task.VerificationCodeTask;
import com.amenuo.monitor.utils.HttpRequest;
import com.amenuo.monitor.utils.SPHelper;
import com.amenuo.monitor.wxapi.WXEntryActivity;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.jwkj.activity.MainActivity;
import com.jwkj.entity.Account;
import com.jwkj.global.AccountPersist;
import com.jwkj.global.NpcCommon;
import com.lib.PinWheelDialog;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Response;

/**
 * Created by laps on 10/30/16.
 */
public class NativeInterface extends ReactContextBaseJavaModule {

    private PinWheelDialog mLoadingDialog;

    public NativeInterface(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "NativeInterface";
    }


    @ReactMethod
    public void showLoading() {
        hideLoading();
        mLoadingDialog = new PinWheelDialog(MainApplication.reactActivity);
        mLoadingDialog.show();
    }

    @ReactMethod
    public void hideLoading() {
        if (mLoadingDialog != null) {
            mLoadingDialog.dismiss();
            mLoadingDialog = null;
        }
    }

    @ReactMethod
    public void login(final ReadableMap props, final Promise promise) {
        String phone = props.getString("phone");
        String pwd = props.getString("pwd");
        LoginTask task = new LoginTask(new LoginTask.Callback() {
            @Override
            public void onLoginResult(boolean success) {
                if (success) {
                    WritableMap map = Arguments.createMap();
                    map.putString("code", "00");
                    map.putString("message", "登陆成功");
                    promise.resolve(map);
                } else {
                    promise.reject("01", "登录失败");
                }
            }
        });
        task.execute(phone, pwd);
    }

    @ReactMethod
    public void isLogin(Callback successCallback) {
        boolean isLogin = LoginStateAction.checkLogin();
        if (!isLogin) {
            isLogin = WXAction.isLogin();
        }
        successCallback.invoke(isLogin);
    }

    @ReactMethod
    public void register(final ReadableMap props, final Promise promise) {
        String phone = props.getString("phone");
        String pwd = props.getString("pwd");
        String code = props.getString("code");
        RegisterTask task = new RegisterTask(new RegisterTask.Callback() {
            @Override
            public void onRegisterResult(boolean success) {
                if (success) {
                    WritableMap map = Arguments.createMap();
                    map.putString("code", "00");
                    map.putString("message", "注册成功");
                    promise.resolve(map);
                } else {
                    promise.reject("01", "注册失败");
                }
            }
        });
        task.execute(phone, pwd, code);
    }

    @ReactMethod
    public void getCode(final String phone) {
        VerificationCodeTask task = new VerificationCodeTask();
        task.execute(phone);
    }

    @ReactMethod
    public void getUserInfo(Callback successCallback) {
        Account activeUser = AccountPersist.getInstance().getActiveAccountInfo(
                MainApplication.getContext());
        WritableMap map = Arguments.createMap();
        if (activeUser != null && !activeUser.three_number.equals("0517401")) {
            NpcCommon.mThreeNum = activeUser.three_number;
            map.putString("code", "00");
            map.putString("phone", activeUser.phone);
            map.putString("message", "登陆成功");
        } else if (WXAction.isLogin()) {
            map.putString("code", "00");
            map.putString("phone", SPHelper.getInstance().getString("nickName", ""));
            map.putString("headImgUrl", SPHelper.getInstance().getString("headImgUrl", ""));
            map.putString("message", "登陆成功");
        } else {
            map.putString("code", "01");
            map.putString("message", "未登陆");
        }
        successCallback.invoke(map);
    }

    @ReactMethod
    public void getWeather(final Promise promise) {
        HttpRequest.requestWeather("天津", new okhttp3.Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                promise.reject("01", "天气获取失败");
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String json = response.body().string();
                final WeatherModel weatherModel = WeatherModel.jsonToModel(json);
                if (weatherModel == null) {
                    promise.reject("01", "天气获取失败");
                } else {
                    WritableMap map = Arguments.createMap();
                    map.putString("code", "00");
                    map.putString("message", "天气获取成功");
                    map.putString("date", weatherModel.getDate());
                    map.putString("city", weatherModel.getCity());
                    map.putString("temp", weatherModel.getTemp());
                    map.putString("weather", weatherModel.getWeather());
                    map.putString("l_temp", weatherModel.getL_tmp());
                    map.putString("h_temp", weatherModel.getH_tmp());
                    promise.resolve(map);
                }
            }
        });
    }

    @ReactMethod
    public void jumpToCamera() {
        Intent intent = new Intent();
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setClass(MainApplication.getContext(), MainActivity.class);
        MainApplication.getContext().startActivity(intent);
    }

    @ReactMethod
    public void jumpToLivePlay(final ReadableMap props) {
        Intent intent = new Intent();
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.putExtra("name", props.getString("name"));
        intent.putExtra("address", props.getString("address"));
        intent.setClass(MainApplication.getContext(), LivePlayerActivity.class);
        MainApplication.getContext().startActivity(intent);
    }

    @ReactMethod
    public void jumpToWXLogin() {
        Intent intent = new Intent();
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setClass(MainApplication.getContext(), WXEntryActivity.class);
        MainApplication.getContext().startActivity(intent);
    }
}
