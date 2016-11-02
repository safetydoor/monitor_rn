/**
 */

'use strict'

/**
 * Example:
 *
 * import $op from 'FPObjectProxy';
 * let originObject = {"key1" : "value1","key2" : {"k1":"v1"}};
 * let proxyObject = $(originObject);
 * proxyObject.getNumber('key1',12)             eq: 12
 * proxyObject.getString('key1','value2')       eq: value1
 *
 * let obj = proxyObject.getObject("key2",{})   eq: {"k1":"v1"}
 * obj.getString("k1")                          eq: v1
 *
 * */

let proxy = (object = {}) => {

    let originObject = (isObject(object) || Array.isArray(object)) ? object : {};

    let proxyObject = {};

    //let proxyObject = new Proxy(object,{
    //    get : function (target, key, receiver) {
    //        let result = Reflect.get(target, key, receiver);
    //        if (Array.isArray(result) || isObject(result)) {
    //            return proxy(result);
    //        }
    //        return result;
    //    },
    //});

    let getOriginValue = (object,keys)=> {
        keys = keys || [];
        if (object === undefined || keys.length == 0) return object;
        let key = keys.shift();
        let subObject;
        if (isObject(object))
            subObject = object[key];
        return getOriginValue(subObject,keys);
    };

    proxyObject.getValue = (keyPath,defaultValue) => {
        let keys = keyPath.split('.');
        let o = getOriginValue(originObject,keys);
        return o || defaultValue;
    };

    proxyObject.getNumber = (keyPath,defaultValue = 0) => {
        let o = proxyObject.getValue(keyPath,defaultValue);
        if (isString(o)) o = parseFloat(o);
        if (isNumber(o)) return o;
        return isNumber(defaultValue)?defaultValue:0;
    };

    proxyObject.getString = (keyPath,defaultValue = '') => {
        let o = proxyObject.getValue(keyPath,defaultValue);
        if (isNumber(o)) o = '' + o + '';
        if (isString(o)) return o;
        return isString(defaultValue)?defaultValue:'';
    };

    proxyObject.getArray = (keyPath,defaultValue = []) => {
        let o = proxyObject.getValue(keyPath,defaultValue);
        if (Array.isArray(o)) return o;
        return proxy(Array.isArray(defaultValue)?defaultValue:[]);
    };

    proxyObject.getObject = (keyPath,defaultValue = {}) =>  {
        let o = proxyObject.getValue(keyPath,defaultValue);
        if (isObject(o)) return o;
        return proxy(isObject(defaultValue)?defaultValue:{});
    };
    return proxyObject;
};


function isObject(arg) {
    return typeof arg === 'object' && arg !== null;
}
function isString(arg) {
    return typeof arg === 'string';
}
function isNumber(arg) {
    return typeof arg === 'number';
}

export default proxy;