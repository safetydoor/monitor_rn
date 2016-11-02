/**
 * Created by laps on 10/29/16.
 */

import Platform from 'Platform';
import ToastAndroid from 'ToastAndroid';
export default class PToast {

    static show(msg) {
        if (Platform.OS === 'ios') {

        } else {
            ToastAndroid.show(msg, ToastAndroid.SHORT)
        }
    }
}