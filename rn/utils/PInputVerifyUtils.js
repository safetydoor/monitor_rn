/**
 * Created by laps on 7/14/16.
 *
 * 输入框校验工具
 */

const Regex = {
    IdNo_15: "^[1-9]\\d{7}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}$",
    IdNo_18: "^[1-9]\\d{5}[1-9]\\d{3}((0\\d)|(1[0-2]))(([0|1|2]\\d)|3[0-1])\\d{3}([0-9]|X|x)$",
    Email: "[\\w!#$%&'*+/=?^_`{|}~-]+(?:\\.[\\w!#$%&'*+/=?^_`{|}~-]+)*@(?:[\\w](?:[\\w-]*[\\w])?\\.)+[\\w](?:[\\w-]*[\\w])?",
    MobileNo: "^1\\d{10}$",
    Chinese: "^[\\u4e00-\\u9fff]{1,}$",//参考http://jicheng.tw/hanzi/unicode.html
};

export default class PInputVerifyUtils {

    static verifyName(cnName) {
        let patt = new RegExp(Regex.Chinese);
        return patt.test(cnName)
    }

    static verifyIdNo(idNo) {
        let patt_15 = new RegExp(Regex.IdNo_15);
        let patt_18 = new RegExp(Regex.IdNo_18);
        return (patt_18.test(idNo) || patt_15.test(idNo));
    }

    static verifyEmail(email) {
        let patt = new RegExp(Regex.Email);
        return patt.test(email);
    }

    static verifyMobileNo(mobileNo) {
        let patt = new RegExp(Regex.MobileNo);
        return patt.test(mobileNo);
    }

    static extractBirthdayFromIdNo(idNo) {
        let birthdayno;
        if (idNo.length == 18) {
            birthdayno = idNo.substring(6, 14);
        } else if (idNo.length == 15) {
            birthdayno = "19" + idNo.substring(6, 12);
        } else {
            return undefined;
        }
        let birthday = birthdayno.substring(0, 4) + "-" + birthdayno.substring(4, 6) + "-" + birthdayno.substring(6, 8);
        return birthday;
    }

    static extractSexFromIdNo(idNo) {
        let sexno, sex;
        if (idNo.length == 18) {
            sexno = idNo.substr(16, 1);
        } else if (idNo.length == 15) {
            sexno = idNo.substr(14, 1);
        } else {
            return undefined;
        }
        if (sexno % 2 == 0) {
            sex = '女';
        } else {
            sex = '男';
        }
        return sex;
    }
}
