/**
 * Created by laps on 10/31/16.
 */

import React, {
    PropTypes,
} from 'react';

import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
import WebView from 'WebView';
import Image from 'Image';
import Dimensions from 'Dimensions';
import BackAndroid from 'BackAndroid';

import PColor from '../utils/PColor.js';
import PTitleBar from '../components/PTitleBar.js';
import PButton from '../components/PButton.js';

const {height, width} = Dimensions.get('window');

export default class WebScreen extends React.Component {

    constructor(props) {
        super(props);
        this.renderBack = this.renderBack.bind(this);
        this.renderForward = this.renderForward.bind(this);
        this.renderRefresh = this.renderRefresh.bind(this);
        this._onLoad = this._onLoad.bind(this);
        this._onLoadStart = this._onLoadStart.bind(this);
        this._onLoadEnd = this._onLoadEnd.bind(this);
        this._onBackPress = this._onBackPress.bind(this);
        this._onForwardPress = this._onForwardPress.bind(this);
        this._onRefreshPress = this._onRefreshPress.bind(this);
        this._onNavigationStateChange = this._onNavigationStateChange.bind(this);
        this.state = {
            progress: 0,
            backButtonEnabled: false,
            forwardButtonEnabled: false,
            url: this.props.url,
            title: this.props.title,
        }
    }

    componentWillMount() {
        BackAndroid.addEventListener('hardwareBackPress', this._onBackPress);
    }

    componentWillUnmount() {
        BackAndroid.removeEventListener('hardwareBackPress', this._onBackPress);
    }

    render() {
        return (
            <View style={styles.root}>
                <PTitleBar
                    leftIcon={require('../images/back_ic.png')}
                    title={this.state.title}
                    navigator={this.props.navigator}
                    />
                <WebView
                    ref={'webView'}
                    style={styles.webView}
                    automaticallyAdjustContentInsets={false}
                    source={{uri: this.state.url}}
                    javaScriptEnabled={true}
                    domStorageEnabled={true}
                    decelerationRate="normal"
                    startInLoadingState={true}
                    scalesPageToFit={true}
                    onLoad={this._onLoad}
                    onLoadStart={this._onLoadStart}
                    onLoadEnd={this._onLoadEnd}
                    onNavigationStateChange={this._onNavigationStateChange}
                    />
                <View style={styles.toolBar}>
                    <PButton style={styles.button}
                             onPress={this._onBackPress}
                             content={this.renderBack}
                             disabled={!this.state.backButtonEnabled}
                             backgroundColor={PColor.white}
                             backgroundColorPressed={PColor.light}
                        />
                    <PButton style={styles.button}
                             onPress={this._onRefreshPress}
                             content={this.renderRefresh}
                             backgroundColor={PColor.white}
                             backgroundColorPressed={PColor.light}
                        />
                    <PButton style={styles.button}
                             onPress={this._onForwardPress}
                             content={this.renderForward}
                             disabled={!this.state.forwardButtonEnabled}
                             backgroundColor={PColor.white}
                             backgroundColorPressed={PColor.light}
                        />
                </View>
            </View>
        );
    }

    renderBack() {
        if (this.state.backButtonEnabled) {
            return (
                <Image style={styles.toolBarImage} source={require('../images/webview_back_normal.png')}/>
            )
        } else {
            return (
                <Image style={styles.toolBarImage} source={require('../images/webview_back_disabled.png')}/>
            )
        }
    }

    renderRefresh() {
        return (
            <Image style={styles.toolBarImage} source={require('../images/webview_refresh_normal.png')}/>
        )
    }

    renderForward() {
        if (this.state.forwardButtonEnabled) {
            return (
                <Image style={styles.toolBarImage} source={require('../images/webview_forward_normal.png')}/>
            )
        } else {
            return (
                <Image style={styles.toolBarImage} source={require('../images/webview_forward_disabled.png')}/>
            )
        }
    }

    _onBackPress() {
        this.refs.webView.goBack();
    }

    _onForwardPress() {
        this.refs.webView.goForward();
    }

    _onRefreshPress() {
        this.refs.webView.reload();
    }

    _onLoad() {
        console.log('_onLoad')
    }

    _onLoadStart() {
        console.log('_onLoadStart')
    }

    _onLoadEnd() {
        console.log('_onLoadEnd')
    }

    _onNavigationStateChange(navState) {
        console.log('_onNavigationStateChange: ' + JSON.stringify(navState));
        let title = this.state.title;
        if (!navState.loading) {
            title = navState.title
            this.setState({
                backButtonEnabled: navState.canGoBack,
                forwardButtonEnabled: navState.canGoForward,
                title: title
            });
        }
    }

    _onBackPress() {
        this.props.navigator.pop();
        return true;
    }
}

const styles = StyleSheet.create({
    root: {
        flexDirection: 'column',
        position: 'absolute',
        right: 0,
        left: 0,
        top: 0,
        bottom: 0,
        backgroundColor: PColor.white,
    },

    webView: {
        backgroundColor: PColor.light,
        flex: 1,
    },

    toolBar: {
        flexDirection: 'row',
        marginTop: 1,
        borderTopWidth: 1,
        borderColor: PColor.light,
        height: 44,
    },

    button: {
        width: 44,
        height: 44,
        alignItems: 'center',
        justifyContent: "center",
    },

    toolBarImage: {
        width: 30,
        height: 30,
    }

});