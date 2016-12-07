package com.amenuo.monitor.utils;

import okhttp3.Callback;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;

/**
 * Created by laps on 8/1/16.
 */
public class HttpRequest {

    public static final int LIVE_REQUEST_SIZE = 20;
    public static final String BAIDU_API_KEY = "ade93ea486e5d4ced4bc8552978d17e6";
    private static final String DOMAIN = "http://115.28.213.201:8088";
    private static final String LUMP_CATEGORY_LIST_PATH = "/category/list";
    private static final String AD_LIST_PATH = "/ad/list";
    private static final String LIVE_LIST_PATH = "/live/list?page=%d&size=%d";
    private static final String REGISTER_PATH = "/user/add";
    private static final String WX_ACCESS_TOKEN_URL = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code";
    private static final String WX_USERINFO_URL = "https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s";
    private static final OkHttpClient mOkHttpClient = new OkHttpClient();
    public static final MediaType JSON
            = MediaType.parse("application/json; charset=utf-8");

    public static void requestWXAccessToken(String code, Callback responseCallback) {
        String url = String.format(WX_ACCESS_TOKEN_URL, Constants.WECHAT_APP_ID, Constants.WECHAT_APP_SECRET, code);
        enqueue(url, responseCallback);
    }

    public static void requestWXUserInfo(String access_token, String openid, Callback responseCallback) {
        String url = String.format(WX_USERINFO_URL, access_token, openid);
        enqueue(url, responseCallback);
    }

    public static void requestLumpCategorys(Callback responseCallback) {
        String url = DOMAIN + LUMP_CATEGORY_LIST_PATH;
        enqueue(url, responseCallback);
    }

    public static void requestLives(int page, Callback responseCallback) {
        String url = DOMAIN + String.format(LIVE_LIST_PATH, page, LIVE_REQUEST_SIZE);
        enqueue(url, responseCallback);
    }

    public static void requestAds(Callback responseCallback) {
        String url = DOMAIN + AD_LIST_PATH;
        enqueue(url, responseCallback);
    }

    public static void requestWeather(String cityName, Callback responseCallback) {
//        String url = "http://apis.baidu.com/apistore/weatherservice/cityname?cityname=" + cityName;
//        Request request = new Request.Builder()
//                .url(url)
//                .header("apikey", BAIDU_API_KEY)
//                .build();
//        enqueue(request, responseCallback);

        String url = "http://apis.baidu.com/thinkpage/weather_api/suggestion?location=" + cityName;
        Request request = new Request.Builder()
                .url(url)
                .header("apikey", BAIDU_API_KEY)
                .build();
        enqueue(request, responseCallback);
    }

    public static void requestRegister(String userName, String passWord, Callback responseCallback) {
        String url = DOMAIN + REGISTER_PATH;
        String json = String.format("{\"userName\":\"%s\",\"passWord\":\"%s\",\"phoneNumber\":\"%s\"}", userName, passWord, userName);
        RequestBody body = RequestBody.create(JSON, json);
        Request request = new Request.Builder()
                .url(url)
                .post(body)
                .build();
        enqueue(request, responseCallback);
    }

    private static void enqueue(String url, Callback responseCallback) {
        Request request = new Request.Builder()
                .url(url)
                .build();
        enqueue(request, responseCallback);
    }

    private static void enqueue(Request request, Callback responseCallback) {
        mOkHttpClient.newCall(request).enqueue(responseCallback);
    }

}
