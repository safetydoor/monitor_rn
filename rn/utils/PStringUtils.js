/**
 *
 * 处理和输出字符串的工具包
 *
 */

export default class StringUtils {

    /**
     * 日期格式化: dateFormat(date, 'yyyy-MM-dd')
     *
     * @param date
     * @param formatStr
     * @returns {*}
     */
    static dateFormat(date, formatStr) {
        if (!date) return '';

        var str = formatStr;
        var Week = ['日', '一', '二', '三', '四', '五', '六'];

        str = str.replace(/yyyy|YYYY/, date.getFullYear());
        str = str.replace(/yy|YY/, (date.getYear() % 100) > 9 ? (date.getYear() % 100).toString() : '0' + (date.getYear() % 100));

        var month = date.getMonth() + 1;
        str = str.replace(/MM/, month > 9 ? month.toString() : '0' + month);
        str = str.replace(/M/g, month);

        str = str.replace(/w|W/g, Week[date.getDay()]);

        str = str.replace(/dd|DD/, date.getDate() > 9 ? date.getDate().toString() : '0' + date.getDate());
        str = str.replace(/d|D/g, date.getDate());

        str = str.replace(/hh|HH/, date.getHours() > 9 ? date.getHours().toString() : '0' + date.getHours());
        str = str.replace(/h|H/g, date.getHours());
        str = str.replace(/mm/, date.getMinutes() > 9 ? date.getMinutes().toString() : '0' + date.getMinutes());
        str = str.replace(/m/g, date.getMinutes());

        str = str.replace(/ss|SS/, date.getSeconds() > 9 ? date.getSeconds().toString() : '0' + date.getSeconds());
        str = str.replace(/s|S/g, date.getSeconds());

        return str;
    }

    /**
     * 以小数点, 分割数字: 1000.02=>[1000, 02], 1000=>[1000, 00]
     * @param num
     */
    static splitNumByDot(num) {
        if (!num) return ['', ''];

        if (typeof num != Number) num = parseFloat(num);
        let numStr = num.toFixed(2);
        return numStr.split('.');
    }

    /**
     * 小数 转化为 百分比的形式 0.034=>3.4%
     *
     * @param percent
     * @param accuracy 保留位数
     * @param dft 默认值
     * @returns {*}
     * @private
     */
    static toPercent(percent, accuracy, dft) {
        if (!percent) return '0.0%';

        //var percent = parseFloat(percent);
        if (isNaN(percent) || (typeof percent == 'string')) percent = parseFloat(percent);

        accuracy = accuracy ? accuracy : 4;
        dft = dft ? dft : 0;
        if (isNaN(percent)) {
            percent = dft;
        }
        let accuracy_base = Math.pow(10, accuracy);
        return Math.round(percent * 100 * accuracy_base) / accuracy_base + '%';
        //return this.toMinRound(Math.round(percent * 100 * accuracy_base) / accuracy_base) + '%';

        //if (isNaN(percent)) percent = parseFloat(percent);
        //return (percent * 100) + '%';
    }

    /**
     * 保留2小数位的四舍五入, 并且千位分割显示: 1000=>1,000.00
     *
     * @param value 数值
     * @returns {*}
     */
    static toSplitAndRound(value) {
        if (!value) return '';

        if (isNaN(value) || (typeof value == 'string')) value = parseFloat(value);

        let left = '', right = value;
        if (value > 1000) {
            left = Math.floor(value / 1000);
            right = value - left * 1000;
            left += ',';

            right = (right + 1000).toFixed(2);
            return left + right.substr(1, right.length - 1);
        }else {
            return right.toFixed(2);
        }
    }

    static toRound(value) {
        if (!value) return '0.00';
        if (isNaN(value) || (typeof value == 'string')) value = parseFloat(value);
        return value.toFixed(2);
    }

    /**
     * 保留至少两位
     * @param yie
     * @returns {string}
     */
    static toMinRound(value){
        if (!value) return '0.00';
        if (typeof value !== 'string') value = String(value);
        let count = 2;
        let pointIndex = value.indexOf('.');
        if (pointIndex >= 0) {
            count = value.length - pointIndex - 1;
            if (count < 0) count = 2;
        }
        return parseFloat(value).toFixed(count);
    }

    static formatString(formatted, ...args) {
        for (var i = 0; i < args.length; i++) {
            var regexp = new RegExp('\\{' + i + '\\}', 'gi');
            formatted = formatted.replace(regexp, args[i]);
        }
        return formatted;
    }
}
