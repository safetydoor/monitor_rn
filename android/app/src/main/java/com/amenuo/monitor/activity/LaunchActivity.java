package com.amenuo.monitor.activity;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.support.v7.app.ActionBarActivity;
import android.widget.ImageView;

import com.amenuo.monitor.R;
import com.squareup.picasso.Picasso;

public class LaunchActivity extends ActionBarActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_launch);
        ImageView imageView = (ImageView) this.findViewById(R.id.launch_image);
        Picasso.with(getApplicationContext()).load(R.drawable.launch).into(imageView);
    }

    @Override
    protected void onStart() {
        super.onStart();
        new Handler().postDelayed(new Runnable() {
            public void run() {
                jump();
            }
        }, 2000);
    }

    private void jump() {
        Intent intent = new Intent();
        intent.setClass(this, PReactActivity.class);
        startActivity(intent);
        finish();
    }
}
