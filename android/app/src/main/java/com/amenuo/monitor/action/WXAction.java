package com.amenuo.monitor.action;

import android.text.TextUtils;

import com.amenuo.monitor.utils.SPHelper;

/**
 * Created by laps on 9/17/16.
 */
public class WXAction {

    public static void saveUserInfo(String openId, String nickName, String headImgUrl, String unionId){
        SPHelper.getInstance().setString("openId", openId);
        SPHelper.getInstance().setString("nickName", nickName);
        SPHelper.getInstance().setString("headImgUrl", headImgUrl);
        SPHelper.getInstance().setString("unionId", unionId);
    }

    public static boolean isLogin(){
        String nickName = SPHelper.getInstance().getString("nickName", "");
        return !(TextUtils.isEmpty(nickName));
    }

    public static void loginOut(){
        SPHelper.getInstance().setString("openId", "");
        SPHelper.getInstance().setString("nickName", "");
        SPHelper.getInstance().setString("headImgUrl", "");
        SPHelper.getInstance().setString("unionId", "");
    }
}
