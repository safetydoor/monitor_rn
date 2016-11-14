/**
 * Created by laps on 10/29/16.
 */

import React, {
    PropTypes,
} from 'react';

import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
import Image from 'Image';
import BackAndroid from 'BackAndroid';
import InteractionManager from 'InteractionManager';
import Dimensions from 'Dimensions';

import WebScreen from '../WebScreen.js';

import PButton from '../../components/PButton.js';
import PColor from '../../utils/PColor.js';
import Interface from '../../utils/Interface.js';

const {height, width} = Dimensions.get('window');

export default class MainMenu extends React.Component {

    constructor(props) {
        super(props);
        this.renderHeaderImg = this.renderHeaderImg.bind(this);
        this._onFindPwdPress = this._onFindPwdPress.bind(this)
        this._onExitPress = this._onExitPress.bind(this)
        this.state = {
            phone: '',
            headImgUrl: ''
        }
    }

    componentDidMount() {
        Interface.getUserInfo((result)=> {
            if (result.code == '00') {
                let phone = result.phone;
                let headImgUrl = result.headImgUrl;
                InteractionManager.runAfterInteractions(() => {
                    this.setState({
                        phone: phone,
                        headImgUrl: headImgUrl,
                    })
                });
            }
        });
    }

    render() {

        return (
            <View style={styles.root}>
                <Image style={styles.bg} source={require('../../images/bg.png')}/>
                {this.renderHeaderImg()}
                <Text style={styles.phone}>{this.state.phone}</Text>
                <PButton
                    style={styles.button}
                    content={'找回密码'}
                    textColor={PColor.black}
                    textColorPressed={PColor.black}
                    backgroundColor={PColor.light}
                    backgroundColorPressed={PColor.white}
                    onPress={this._onFindPwdPress}
                    />

                <PButton
                    style={styles.button}
                    content={'退出'}
                    textColor={PColor.black}
                    textColorPressed={PColor.black}
                    backgroundColor={PColor.white}
                    backgroundColorPressed={PColor.light}
                    onPress={this._onExitPress}
                    />
            </View>
        );
    }

    renderHeaderImg() {
        if (this.state.headImgUrl) {
            return (
                <Image style={styles.logo} source={{uri: this.state.headImgUrl}}/>
            );
        } else {
            return (
                <Image style={styles.logo} source={require('../../images/app_logo.png')}/>
            );
        }
    }

    _onFindPwdPress() {
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

    _onExitPress() {
        BackAndroid.exitApp();
    }
}

const styles = StyleSheet.create({

    root: {
        flexDirection: 'column',
        backgroundColor: PColor.light,
        alignItems: 'center',
        paddingLeft: 20,
        paddingRight: 20,
        position: 'absolute',
        top: 0,
        bottom: 0,
        left: 0,
        right: 0
    },

    bg: {
        width: width * 2 / 3,
        height: height,
        position: 'absolute',
        top: 0,
        bottom: 0,
        left: 0,
        right: 0
    },

    logo: {
        width: 98,
        height: 66,
        alignSelf: 'center',
        marginTop: 50,
    },

    phone: {
        textAlign: 'center',
        color: PColor.black,
        fontSize: 18,
        marginTop: 20,
        marginBottom: 20,
    },

    button: {
        width: 200,
        height: 40,
        borderRadius: 25,
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: 20
    },
});