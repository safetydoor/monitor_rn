package com.amenuo.monitor.utils;

import android.widget.Toast;

import com.amenuo.monitor.MainApplication;


/**
 * Created by laps on 8/4/16.
 */
public class PToast {

    public static void show(String msg){
        if (msg == null){
            return;
        }
        int length_time = Toast.LENGTH_SHORT;
        int msg_length = msg.getBytes().length;
        if (msg_length > 20){
            length_time = Toast.LENGTH_LONG;
        }
        Toast.makeText(MainApplication.getContext(), msg, length_time).show();
    }

    public static void show(int resId){
        String msg = MainApplication.getContext().getResources().getString(resId);
        show(msg);
    }
}
