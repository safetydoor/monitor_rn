/**
 *
 * 日期时间操作工具
 */

export default class PDateUtils {

    /**
     * 将日期时间字符串转为Date类型。
     * @param dateString
     * @returns {Date}
     */
    static toDate(dateString) {
        let date = new Date(dateString);
        //有的js解析器不支持date的部分格式。例如iOS的解析器不支持 2016-10-10 10:10:10这样的格式

        if (date == 'Invalid Date') {
            dateString = dateString.replace(/:/g, '-').replace(/\//g, '-').replace(/\s+/g, '-');
            let arr = dateString.split('-');
            //长度不够6，都加0
            for (let i = arr.length; i < 6; i++) {
                arr[i] = 0;
            }
            date = new Date(arr[0], (parseInt(arr[1]) - 1), arr[2], arr[3], arr[4], arr[5]);
        }
        return date;
    }

    /**
     * 日期格式化: dateFormat(date, 'yyyy-MM-dd hh:mm:ss');
     *
     * @param date
     * @param formatStr
     * @returns {String}
     */
    static format(date, formatStr) {
        if (!date) {
            return '';
        }
        if (typeof date === 'string') {
            date = FPDateUtils.toDate(date);
        }

        let str = formatStr;
        let weeks = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'];

        let fullYear = date.getFullYear();
        let year = date.getYear() % 100;
        year = year > 9 ? year.toString() : '0' + year;
        let month = date.getMonth() + 1;
        month = month > 9 ? month.toString() : '0' + month;
        let week = weeks[date.getDay()];
        let day = date.getDate() > 9 ? date.getDate().toString() : '0' + date.getDate();
        let hours = date.getHours() > 9 ? date.getHours().toString() : '0' + date.getHours();
        let minutes = date.getMinutes() > 9 ? date.getMinutes().toString() : '0' + date.getMinutes();
        let seconds = date.getSeconds() > 9 ? date.getSeconds().toString() : '0' + date.getSeconds();


        str = str.replace(/yyyy|YYYY/, fullYear)
            .replace(/yy|YY/, year)
            .replace(/MM/, month)
            .replace(/M/g, (date.getMonth() + 1))
            .replace(/w|W/g, week)
            .replace(/dd|DD/, day)
            .replace(/d|D/g, date.getDate())
            .replace(/hh|HH/, hours)
            .replace(/h|H/g, date.getHours())
            .replace(/mm/, minutes)
            .replace(/m/g, date.getMinutes())
            .replace(/ss|SS/, seconds)
            .replace(/s|S/g, date.getSeconds());
        return str;
    }
}