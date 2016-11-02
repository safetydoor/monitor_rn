/**
 * Created by laps on 10/30/16.
 */

import { NativeModules } from 'react-native';
const NativeInterface = NativeModules.NativeInterface;

export default class Interface {

    static showLoading() {
        NativeInterface.showLoading();
    }

    static hideLoading() {
        NativeInterface.hideLoading();
    }

    static jumpToCamera() {
        NativeInterface.jumpToCamera();
    }

    static jumpToLivePlay(options) {
        NativeInterface.jumpToLivePlay(options);
    }

    static jumpToWXLogin() {
        NativeInterface.jumpToWXLogin();
    }

    static async login(phone, pwd):Promise {
        let options = {
            phone: phone,
            pwd: pwd
        };
        return NativeInterface.login(options);
    }

    static isLogin(callback) {
        NativeInterface.isLogin(callback);
    }

    static getUserInfo(callback) {
        NativeInterface.getUserInfo(callback);
    }

    static async register(phone, pwd, code):Promise {
        let options = {
            phone: phone,
            pwd: pwd,
            code: code
        };
        return NativeInterface.register(options);
    }

    static getCode(phone):Promise {
        return NativeInterface.getCode(phone);
    }

    static async getWeather(): Promise {
        return NativeInterface.getWeather();
    }
}