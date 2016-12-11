/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
    AppRegistry,
    Navigator,
    Text,
    View,
} from 'react-native';
import LoginScreen from './screen/LoginScreen.js';
import MainScreen from './screen/MainScreen.js';
//import LiveListView from './screen/MainScreen.js';

import Interface from './utils/Interface.js';

class monitor extends Component {

    constructor(props) {
        super(props);
        this._configureScene = this._configureScene.bind(this);
        this.renderScene = this.renderScene.bind(this);
        this.state = {
            loginState: '-'
        }
    }

    componentDidMount() {
        Interface.isLogin((isLogin)=>{
            this.setState({
                loginState: isLogin
            })
        });
    }

    
    render() {
        if (this.state.loginState === '-') {
            return (<View />);
        } else {
            let component = this.state.loginState? MainScreen: LoginScreen;
            return (
                <Navigator
                    initialRoute={{ name: 'LoginScreen', component: component }}
                    configureScene={this._configureScene}
                    renderScene={this.renderScene}/>
            );
        }
    }

    renderScene(route, navigator) {
        let Component = route.component;
        return <Component {...route.params} navigator={navigator}/>
    }

    _configureScene(route) {
        return Navigator.SceneConfigs.PushFromRight;
    }
}

AppRegistry.registerComponent('monitor', () => monitor);
