/**
 * Created by laps on 9/24/16.
 */
import React, {
    PropTypes,
} from 'react';

import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
import BackAndroid from 'BackAndroid';

import MainContentView from './main/MainContentView.js'
import MainMenu from './main/MainMenu.js'

const SideMenu = require('react-native-side-menu');

import PToast from '../utils/PToast.js';

export default class MainScreen extends React.Component {

    backTimes = 0;
    lastBackTime = 0;
    menuOpen = false;
    constructor(props) {
        super(props);
        this._onBackPress = this._onBackPress.bind(this);
        this._onLeftPress = this._onLeftPress.bind(this);
        this._onMenuChange = this._onMenuChange.bind(this);
        this.state = {
            menuOpen: this.menuOpen,
        }
    }

    render() {
        const menu = <MainMenu navigator={this.props.navigator}/>;
        return (
            <SideMenu menu={menu} ref={'sideMenu'} isOpen={this.menuOpen} onChange={this._onMenuChange}>
                <MainContentView navigator={this.props.navigator} onLeftPress={this._onLeftPress}/>
            </SideMenu>
        );
    }

    componentDidMount() {
        BackAndroid.addEventListener('hardwareBackPress', this._onBackPress);
    }

    componentWillUnmount() {
        BackAndroid.removeEventListener('hardwareBackPress', this._onBackPress);
    }

    _onMenuChange(isOpen) {
        this.menuOpen = isOpen;
    }

    _onLeftPress() {
        this.menuOpen = !this.menuOpen;
        this.setState({
            menuOpen: this.menuOpen
        })
    }

    _onBackPress() {
        let nowTime = new Date().getTime();
        if (nowTime - this.lastBackTime > 1500) {
            this.backTimes = 0;
        }
        this.backTimes = this.backTimes + 1;
        this.lastBackTime = nowTime;
        if (this.backTimes >= 2) {
            BackAndroid.exitApp();
        } else {
            PToast.show('再按一次退出');
        }

        return true;
    }
}