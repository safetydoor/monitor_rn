/**
 * Created by laps on 10/30/16.
 */

import { NativeModules } from 'react-native';
import Platform from 'Platform';
import WebScreen from '../screen/WebScreen.js';
import Linking from 'Linking';
const NativeInterface = NativeModules.NativeInterface;

export default class Interface {

    static showLoading() {
        NativeInterface.showLoading();
    }

    static hideLoading() {
        NativeInterface.hideLoading();
    }

    static showToast(message) {
        NativeInterface.showToast(message);
    }

    static jumpToCamera() {
        NativeInterface.jumpToCamera();
    }

    static jumpToLivePlay(options) {
        if (Platform.OS === 'ios') {
            Linking.canOpenURL(options.address).then(supported => {
                if (!supported) {
                    console.log('不能打开地址: ' + url);
                } else {
                    return Linking.openURL(options.address);
                }
            }).catch(err => console.log('An error occurred', err));
        } else {
            NativeInterface.jumpToLivePlay(options);
        }
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

    static async getWeather():Promise {
        return NativeInterface.getWeather();
    }
}