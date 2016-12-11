/**
 * Created by laps on 9/24/16.
 */
import React, {
    PropTypes,
} from 'react';

import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
import Image from 'Image';
import TextInput from 'TextInput';
import Dimensions from 'Dimensions';
import TouchableWithoutFeedback from 'TouchableWithoutFeedback';
import BackAndroid from 'BackAndroid';

import PColor from '../utils/PColor.js';
import PTextInput from '../components/PTextInput.js';
import PButton from '../components/PButton.js';
import PToast from '../utils/PToast.js';
import PInputVerifyUtils from '../utils/PInputVerifyUtils.js';
import Interface from '../utils/Interface.js';

const DismissKeyboard = require('dismissKeyboard');
const {height, width} = Dimensions.get('window');

export default class RegisterScreen extends React.Component {

    constructor(props) {
        super(props);
        this.renderPhoneInput = this.renderPhoneInput.bind(this);
        this.renderCodeInput = this.renderCodeInput.bind(this);
        this.renderPwdInput = this.renderPwdInput.bind(this);
        this.renderDivider = this.renderDivider.bind(this);

        this._onBackPress = this._onBackPress.bind(this);
        this._onPress = this._onPress.bind(this);
        this._onRegisterPress = this._onRegisterPress.bind(this);
        this._onCodePress = this._onCodePress.bind(this);
        this._onLoginPress = this._onLoginPress.bind(this);

        this._onPhoneChangeText = this._onPhoneChangeText.bind(this);
        this._onCodeChangeText = this._onCodeChangeText.bind(this);
        this._onPwdChangeText = this._onPwdChangeText.bind(this);
        this.state = {
            totalCount: 0
        }
    }

    componentWillMount() {
        BackAndroid.addEventListener('hardwareBackPress', this._onBackPress);
    }

    componentWillUnmount() {
        this._clearInterval();
        BackAndroid.removeEventListener('hardwareBackPress', this._onBackPress);
    }

    render() {
        return (
            <TouchableWithoutFeedback onPress={this._onPress}>
                <View style={styles.root}>
                    <Image
                        style={styles.bg}
                        resizeMode={'stretch'}
                        source={require('../images/login_bg.jpg')}
                        />
                    <View style={styles.content}>
                        <Image style={styles.logo} source={require('../images/app_logo.png')}/>
                        {this.renderPhoneInput()}
                        {this.renderCodeInput()}
                        {this.renderPwdInput()}
                        <PButton
                            style={styles.registerBtn}
                            onPress={this._onRegisterPress}
                            textColor={PColor.white}
                            textColorPressed={PColor.white}
                            backgroundColor={PColor.blue}
                            backgroundColorPressed={PColor.blue_press}
                            content={'注册'}/>

                        <PButton
                            style={styles.registerBtn}
                            onPress={this._onLoginPress}
                            textColor={PColor.white}
                            textColorPressed={PColor.white}
                            backgroundColor={PColor.blue}
                            backgroundColorPressed={PColor.blue_press}
                            content={'去登陆页面'}/>
                    </View>
                </View>
            </TouchableWithoutFeedback>
        );
    }

    renderPhoneInput() {
        return (
            <PTextInput
                style={styles.input}
                keyboardType={'numeric'}
                icon={require('../images/phone_input_ic.png')}
                placeholder={'手机号'}
                color={PColor.white}
                lineColor={PColor.white}
                placeholderTextColor={PColor.light}
                onChangeText={this._onPhoneChangeText}
                />
        );
    }

    renderCodeInput() {
        let btnContent = '获取验证码';
        let btnDisabled = false;
        if (this.state.totalCount && this.state.totalCount > 0) {
            btnContent = this.state.totalCount + '秒后重新获取';
            btnDisabled = true;
        }
        return (
            <View style={styles.codeInputContainer}>
                <PTextInput
                    style={[styles.input, {flex:1}]}
                    keyboardType={'numeric'}
                    icon={require('../images/validate_input_ic.png')}
                    placeholder={'验证码'}
                    color={PColor.white}
                    lineColor={PColor.white}
                    placeholderTextColor={PColor.light}
                    onChangeText={this._onCodeChangeText}
                    />
                <PButton
                    style={styles.getCodeBtn}
                    onPress={this._onCodePress}
                    disabled={btnDisabled}
                    textColor={PColor.white}
                    textColorPressed={PColor.white}
                    backgroundColor={PColor.blue}
                    backgroundColorPressed={PColor.blue_press}
                    backgroundColorDisabled={PColor.gray}
                    content={btnContent}/>
            </View>
        )
    }

    renderPwdInput() {
        return (
            <PTextInput
                style={styles.input}
                icon={require('../images/pwd_input_text_ic.png')}
                placeholder={'密码'}
                color={PColor.white}
                lineColor={PColor.white}
                placeholderTextColor={PColor.light}
                secureTextEntry={true}
                onChangeText={this._onPwdChangeText}
                />
        );
    }

    renderDivider() {
        return (
            <View style={styles.dividerContainer}>
                <View style={styles.dividerLine}/>
                <Text style={styles.dividerText}>OR</Text>
                <View style={styles.dividerLine}/>
            </View>
        );
    }

    _onPress() {
        DismissKeyboard();
    }

    _onCodePress() {
        if (!PInputVerifyUtils.verifyMobileNo(this.phoneNumber)) {
            PToast.show('请输入正确手机号');
            return;
        }
        this._countDown();
        Interface.getCode(this.phoneNumber);
    }

    _onRegisterPress() {
        if (!PInputVerifyUtils.verifyMobileNo(this.phoneNumber)) {
            PToast.show('请输入正确手机号');
            return;
        }

        if (!(this.code && this.code.length > 0)) {
            PToast.show('请输入短信验证码');
            return;
        }

        if (!(this.password && this.password.length >= 6)) {
            PToast.show('密码太短');
            return;
        }
        Interface.showLoading();
        Interface.register(this.phoneNumber, this.password, this.code).then((result)=> {
            Interface.hideLoading();
            PToast.show(result.message);
            this.props.navigator.pop();
        }).catch((error)=>{
            Interface.hideLoading();
            PToast.show(error.message);
        })
    }

    _onLoginPress() {
        this.props.navigator.pop();
    }

    _onPhoneChangeText(text) {
        this.phoneNumber = text;
    }

    _onCodeChangeText(text) {
        this.code = text;
    }

    _onPwdChangeText(text) {
        this.password = text;
    }

    _countDown() {
        this._clearInterval();

        this.totalCount = 60;
        this.setState({
            totalCount: this.totalCount
        });
        this.interval = setInterval(
            () => {
                if (this.totalCount == 0) {
                    this._clearInterval();
                    return;
                }
                this.totalCount = this.totalCount -1;
                this.setState({
                    totalCount: this.totalCount
                })
            },
            1000
        );
    }

    _clearInterval() {
        if (this.interval) {
            clearInterval(this.interval);
        }
        this.interval = undefined;
    }

    _onBackPress() {

        this.props.navigator.pop();
        return true;
    }
}

const styles = StyleSheet.create({

    root: {
        width: width,
        height: height,
    },
    bg: {
        width: width,
        height: height,
        position: 'absolute',
        top: 0,
        left: 0,
    },
    content: {
        marginLeft: 35,
        marginRight: 35,
        flexDirection: 'column',
    },
    logo: {
        width: 98,
        height: 66,
        alignSelf: 'center',
        marginTop: 40,
        marginBottom: 40,
    },
    input: {

    },
    codeInputContainer: {
        marginTop: 5,
        flex: 1,
        flexDirection: 'row',
        height: 50,
        justifyContent: 'center',
    },
    getCodeBtn: {
        height: 40,
        width: 140,
        borderRadius: 5,
        alignItems: 'center',
        justifyContent: 'center',
    },

    registerBtn: {
        flex: 1,
        height: 50,
        borderRadius: 25,
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: 40
    },

});