/**
 * Created by laps on 11/1/16.
 */

import PStringUtils from './PStringUtils.js';

export default class PHttpUtils {


    static requestLiveList(page) {
        let url = PStringUtils.formatString(PHttpUtils.LiveUrl, page);
        return fetch(url);
    }

    static requestCategory() {
        let url = PHttpUtils.CategoryUrl;
        return fetch(url);
    }

    static requestAdList() {
        let url = PHttpUtils.AdUrl;
        return fetch(url);
    }

    static request(url) {
        return fetch(url);
    }
}
PHttpUtils.LiveUrl = 'http://115.28.213.201:8088/live/list?page={0}&size=20';
PHttpUtils.CategoryUrl = 'http://115.28.213.201:8088/category/list';
PHttpUtils.AdUrl = 'http://115.28.213.201:8088/ad/list';