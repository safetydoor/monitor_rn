/**
 * Created by laps on 10/29/16.
 *
 * style:           按钮样式
 * content:         按钮内容，可以是文本string/图片<Image />。
 * tag:             tag,标识，用于回调 onPress(tag)
 * disabled:        是否禁用
 * textColor:       文本颜色
 * textColorPressed:            文本按下的颜色
 * textColorDisabled:           文本禁用的颜色
 * backgroundColor:             背景色
 * backgroundColorPressed:      按下的背景色
 * backgroundColorDisabled:     禁用的背景色
 * onPress:PropTypes.func,      点击回调
 */

import React, {PropTypes} from 'react';
import {StyleSheet, Text, View, TouchableWithoutFeedback} from 'react-native';

import PColor from '../utils/PColor.js';

export default class PButton extends React.Component {

    constructor(props) {
        super(props);
        this.renderContent = this.renderContent.bind(this);
        this._onPressIn = this._onPressIn.bind(this);
        this._onPressOut = this._onPressOut.bind(this);
        this._onPress = this._onPress.bind(this);
        this.state = {
            pressed: false,
        }
    }

    render() {
        let backgroundColor = this.props.backgroundColor;
        if (this.props.disabled) {
            backgroundColor = this.props.backgroundColorDisabled;
        } else if (this.state.pressed) {
            backgroundColor = this.props.backgroundColorPressed;
        }
        return (
            <TouchableWithoutFeedback
                onPress={this._onPress}
                onPressIn={this._onPressIn}
                onPressOut={this._onPressOut}
                >
                <View key={this.props.tag} style={[this.props.style, {backgroundColor: backgroundColor}]}>
                    {this.renderContent()}
                </View>
            </TouchableWithoutFeedback>
        )

    }

    renderContent() {
        let contentType = typeof(this.props.content);
        if (contentType == 'string') {
            let textColor = this.props.textColor;
            if (this.props.disabled) {
                textColor = this.props.textColorDisabled;
            } else if (this.state.pressed) {
                textColor = this.props.textColorPressed;
            }
            return (
                <Text style={[this.props.textStyle, {color: textColor}]}>
                    {this.props.content}
                </Text>
            )
        } else if (contentType == 'object') {
            return this.props.content;
        } else if (contentType == 'function') {
            return this.props.content();
        }
    }

    _onPress() {
        if (this.props.disabled) {
            return;
        }
        if (this.props.onPress) {
            this.props.onPress(this.props.tag);
        }
    }

    _onPressIn() {
        if (this.props.disabled) {
            return;
        }
        this.setState({pressed: true});
    }

    _onPressOut() {
        if (this.props.disabled) {
            return;
        }
        this.setState({pressed: false});
    }

}

PButton.defaultProps = {
    disabled: false,
    textColor: PColor.black,
    backgroundColor: PColor.white,
};

PButton.propTypes = {
    style: PropTypes.any,
    content: PropTypes.any,
    tag: PropTypes.string,
    disabled: PropTypes.bool,
    textColor: PropTypes.string,
    textColorPressed: PropTypes.string,
    textColorDisabled: PropTypes.string,
    backgroundColor: PropTypes.string,
    backgroundColorPressed: PropTypes.string,
    backgroundColorDisabled: PropTypes.string,
    onPress: PropTypes.func,
};
