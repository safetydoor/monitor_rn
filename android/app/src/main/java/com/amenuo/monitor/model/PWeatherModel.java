package com.amenuo.monitor.model;

import android.text.TextUtils;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Created by laps on 8/2/16.
 */
public class PWeatherModel {

    private String city;
    private String date;
    private String weather;
    private String temp;
    private String l_tmp;
    private String h_tmp;

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }

    public String getWeather() {
        return weather;
    }

    public void setWeather(String weather) {
        this.weather = weather;
    }

    public String getTemp() {
        return temp;
    }

    public void setTemp(String temp) {
        this.temp = temp;
    }

    public String getL_tmp() {
        return l_tmp;
    }

    public void setL_tmp(String l_tmp) {
        this.l_tmp = l_tmp;
    }

    public String getH_tmp() {
        return h_tmp;
    }

    public void setH_tmp(String h_tmp) {
        this.h_tmp = h_tmp;
    }

    public static PWeatherModel jsonToModel(String json){
        try {
            if (TextUtils.isEmpty(json)){
                return null;
            }
            JSONObject object = new JSONObject(json);
            JSONArray results = object.getJSONArray("results");
            JSONObject result = results.getJSONObject(0);
            JSONObject daily = result.getJSONArray("daily").getJSONObject(0);

            PWeatherModel weather = new PWeatherModel();
            weather.setDate(daily.getString("date"));
            weather.setWeather(daily.getString("text_day"));
            weather.setTemp(daily.getString("high"));
            weather.setL_tmp(daily.getString("low"));
            weather.setH_tmp(daily.getString("high"));
            return weather;

        } catch (JSONException e) {
            e.printStackTrace();
        }
        return null;
    }
}
