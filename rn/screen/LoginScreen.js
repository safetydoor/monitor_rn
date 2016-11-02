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
import RegisterScreen from './RegisterScreen.js';
import MainScreen from './MainScreen.js';
import WebScreen from './WebScreen.js';

const DismissKeyboard = require('dismissKeyboard');
const {height, width} = Dimensions.get('window');

export default class LoginScreen extends React.Component {

    constructor(props) {
        console.log('xxx');
        super(props);
        this.renderPhoneInput = this.renderPhoneInput.bind(this);
        this.renderPwdInput = this.renderPwdInput.bind(this);
        this.renderDivider = this.renderDivider.bind(this);

        this._onPress = this._onPress.bind(this);
        this._onForgetPwdPress = this._onForgetPwdPress.bind(this);
        this._onRegisterPress = this._onRegisterPress.bind(this);
        this._onLoginPress = this._onLoginPress.bind(this);
        this._onWXLoginPress = this._onWXLoginPress.bind(this);
        this._onPhoneChangeText = this._onPhoneChangeText.bind(this);
        this._onPwdChangeText = this._onPwdChangeText.bind(this);

        this._onBackPress =  this._onBackPress.bind(this);
    }

    componentDidMount() {
        BackAndroid.addEventListener('hardwareBackPress', this._onBackPress);
    }

    componentWillUnmount() {
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
                        {this.renderPwdInput()}
                        <Text style={styles.forgetPwd} onPress={this._onForgetPwdPress}>忘记密码</Text>
                        <PButton
                            style={styles.loginBtn}
                            onPress={this._onLoginPress}
                            textColor={PColor.white}
                            textColorPressed={PColor.white}
                            backgroundColor={PColor.blue}
                            backgroundColorPressed={PColor.blue_press}
                            content={'登陆'}/>
                        <Text style={styles.register} onPress={this._onRegisterPress}>创建账号</Text>
                        {this.renderDivider()}
                        <PButton
                            style={styles.wxLoginBtn}
                            onPress={this._onWXLoginPress}
                            textColor={PColor.black}
                            textColorPressed={PColor.black}
                            backgroundColor={PColor.white}
                            backgroundColorPressed={PColor.light}
                            content={'微信账号登陆'}/>
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

    _onForgetPwdPress() {
        let url = 'http://www.cloudlinks.cn/pw/';
        this.props.navigator.push({
            name: 'WebScreen',
            component: WebScreen,
            params: {
                title: '忘记密码',
                url: url
            }
        })
    }

    _onRegisterPress() {
        this.props.navigator.push({
            name: 'Register',
            component: RegisterScreen,
        })
    }

    _onLoginPress() {
        if (!PInputVerifyUtils.verifyMobileNo(this.phoneNumber)) {
            PToast.show('请输入正确手机号');
            return;
        }

        if (!(this.password && this.password.length >= 6)) {
            PToast.show('密码太短');
            return;
        }
        Interface.showLoading();
        Interface.login(this.phoneNumber, this.password).then((result)=> {
            this.props.navigator.replace({
                name: 'Main',
                component: MainScreen,
            });
            Interface.hideLoading();
        }).catch((error)=>{
            Interface.hideLoading();
            PToast.show(error.message);
        })
    }

    _onWXLoginPress() {
        Interface.jumpToWXLogin();
    }

    _onPhoneChangeText(text) {
        this.phoneNumber = text;
    }

    _onPwdChangeText(text) {
        this.password = text;
    }

    _onBackPress() {
        BackAndroid.exitApp();
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
    input: {},
    forgetPwd: {
        alignSelf: 'flex-end',
        marginTop: 20,
        color: PColor.white,
    },
    loginBtn: {
        flex: 1,
        height: 50,
        borderRadius: 25,
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: 40
    },
    wxLoginBtn: {
        flex: 1,
        height: 50,
        borderRadius: 25,
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: 10
    },
    register: {
        marginTop: 10,
        alignSelf: 'center',
        color: PColor.white,
    },
    dividerContainer: {
        marginTop: 10,
        flexDirection: 'row',
        justifyContent: 'center',
        alignItems: 'center',
    },
    dividerLine: {
        height: 1,
        flex: 1,
        backgroundColor: PColor.white
    },
    dividerText: {
        marginLeft: 10,
        marginRight: 10,
        color: PColor.white,
    }
});