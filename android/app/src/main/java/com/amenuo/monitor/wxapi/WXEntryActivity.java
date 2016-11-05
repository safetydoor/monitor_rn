package com.amenuo.monitor.wxapi;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;

import com.amenuo.monitor.R;
import com.amenuo.monitor.action.WXAction;
import com.amenuo.monitor.activity.PReactActivity;
import com.amenuo.monitor.utils.Constants;
import com.amenuo.monitor.utils.HttpRequest;
import com.amenuo.monitor.utils.PLog;
import com.amenuo.monitor.utils.PToast;
import com.lib.PinWheelDialog;
import com.tencent.mm.sdk.openapi.BaseReq;
import com.tencent.mm.sdk.openapi.BaseResp;
import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.IWXAPIEventHandler;
import com.tencent.mm.sdk.openapi.SendAuth;
import com.tencent.mm.sdk.openapi.WXAPIFactory;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.Response;

public class WXEntryActivity extends Activity implements OnClickListener, IWXAPIEventHandler {

    private Button mLoginButton;
    private Button mLoginOtherMethodButton;
    private IWXAPI api;
    private PinWheelDialog mLoadingDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        PLog.e("onCreate");
        setContentView(R.layout.activity_monitor_wechat_login);

        mLoginButton = (Button) findViewById(R.id.login_login);
        mLoginButton.setOnClickListener(this);
        mLoginOtherMethodButton = (Button) findViewById(R.id.login_other_method);
        mLoginOtherMethodButton.setOnClickListener(this);

        api = WXAPIFactory.createWXAPI(this, Constants.WECHAT_APP_ID, true);
        api.registerApp(Constants.WECHAT_APP_ID);
        api.handleIntent(getIntent(), this);
    }

    @Override
    protected void onStart() {
        PLog.e("onStart");
        super.onStart();
    }

    @Override
    protected void onResume() {
        PLog.e("onResume");
        super.onResume();
    }

    @Override
    protected void onDestroy() {
        PLog.e("onDestroy");
        if (mLoadingDialog != null) {
            mLoadingDialog.dismiss();
        }
        super.onDestroy();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        PLog.e("onNewIntent");
        setIntent(intent);
        api.handleIntent(intent, this);
    }

    @Override
    public void onClick(View v) {
        int resId = v.getId();
        if (resId == R.id.login_login) {
            if(!api.isWXAppInstalled()){
                PToast.show("请先安装微信");
                return;
            }
            final SendAuth.Req req = new SendAuth.Req();
            req.scope = "snsapi_userinfo";
            req.state = "amenuo_wx_login";
            api.sendReq(req);
            mLoadingDialog = new PinWheelDialog(WXEntryActivity.this);
            mLoadingDialog.show();
        } else if (resId == R.id.login_other_method) {
            finish();
        }
    }

    @Override
    public void onReq(BaseReq baseReq) {
        PLog.e("onReq");
    }

    @Override
    public void onResp(BaseResp baseResp) {
        if (baseResp.errCode == BaseResp.ErrCode.ERR_OK){
            SendAuth.Resp response = (SendAuth.Resp)baseResp;
            String code = response.token;
            requestAccessToken(code);
        }else{
            loginFaild(null);
        }
    }

    private void requestAccessToken(String code){
        HttpRequest.requestWXAccessToken(code, new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                loginFaild(e);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String json = response.body().string();
                PLog.e("succ:" + json);
                try {
                    JSONObject jsonObject = new JSONObject(json);
                    String access_token = jsonObject.getString("access_token");
                    String openid = jsonObject.getString("openid");
                    requestUserInfo(access_token, openid);
                } catch (JSONException e) {
                    e.printStackTrace();
                    loginFaild(e);
                }
            }
        });
    }

    private void requestUserInfo(String access_token, String openid){
        HttpRequest.requestWXUserInfo(access_token, openid, new Callback() {
            @Override
            public void onFailure(Call call, IOException e) {
                loginFaild(e);
            }

            @Override
            public void onResponse(Call call, Response response) throws IOException {
                String json = response.body().string();
                PLog.e("succ:" + json);
                try {
                    JSONObject jsonObject = new JSONObject(json);
                    String nickName = jsonObject.getString("nickname");
                    String headImgUrl = jsonObject.getString("headimgurl");
                    String openId = jsonObject.getString("openid");
                    String unionId = jsonObject.getString("unionid");
                    WXAction.saveUserInfo(openId, nickName, headImgUrl, unionId);
                    WXEntryActivity.this.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            mLoadingDialog.dismiss();
                            Intent intent = new Intent();
                            intent.setClass(WXEntryActivity.this, PReactActivity.class);
                            startActivity(intent);
                            finish();
                        }
                    });
                } catch (JSONException e) {
                    e.printStackTrace();
                    loginFaild(e);
                }
            }
        });
    }

    private void loginFaild(Exception e){
        if(e != null){
            PLog.e(e.getMessage());
        }
        WXEntryActivity.this.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if(mLoadingDialog != null){
                    mLoadingDialog.dismiss();
                }
                PToast.show(R.string.error_field_login_wx);
            }
        });

    }
}
