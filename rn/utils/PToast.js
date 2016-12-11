/**
 * Created by laps on 10/29/16.
 */

import Platform from 'Platform';
import ToastAndroid from 'ToastAndroid';
import Interface from './Interface.js'
export default class PToast {

    static show(msg) {
        if (Platform.OS === 'ios') {
            Interface.showToast(msg);
        } else {
            ToastAndroid.show(msg, ToastAndroid.SHORT)
        }
    }
}