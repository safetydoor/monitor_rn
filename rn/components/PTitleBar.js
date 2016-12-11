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
import TouchableOpacity from 'TouchableOpacity';
import Platform from 'Platform';
import PColor from '../utils/PColor.js';

export default class PTitleBar extends React.Component {

    constructor(props) {
        super(props);
        this.renderLeftIcon = this.renderLeftIcon.bind(this);
        this.renderLeftText = this.renderLeftText.bind(this);

        this._onLeftPress = this._onLeftPress.bind(this);
    }

    render() {
        let height = 50;
        let paddingTop = 0;
        if (Platform.OS === 'ios') {
            height = 70;
            paddingTop = 20;
        }
        return (
            <View style={{height: height,backgroundColor: PColor.white, paddingTop: paddingTop}}>
                <View style={[styles.root, this.props.style]}>
                    <TouchableOpacity onPress={this._onLeftPress} style={styles.left}>
                        <View>
                            {this.renderLeftIcon()}
                            {this.renderLeftText()}
                        </View>
                    </TouchableOpacity>
                    <Text style={styles.title} numberOfLines={1}>{this.props.title}</Text>
                </View>
            </View>
        );
    }

    renderLeftIcon() {
        if (this.props.leftIcon) {
            return (
                <Image style={styles.leftIcon} source={this.props.leftIcon}/>
            );
        }
    }

    renderLeftText() {
        if (this.props.leftText) {
            return (
                <Text style={styles.leftText}>{this.props.leftText}</Text>
            );
        }
    }

    _onLeftPress() {
        if (this.props.onLeftPress) {
            this.props.onLeftPress();
        } else if (this.props.navigator) {
            this.props.navigator.pop();
        }
    }
}

const styles = StyleSheet.create({

    root: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        height: 50,
        backgroundColor: PColor.white,
        borderBottomWidth: 1,
        borderColor: PColor.light,
    },

    left: {
        position: 'absolute',
        top: 0,
        left: 15,
        height: 50,
        alignItems: 'center',
        flexDirection: 'row',
    },

    leftIcon: {
        width: 30,
        height: 30,
    },

    leftText: {
        color: PColor.black,
        marginLeft: 5,
    },

    title: {
        flex: 1,
        color: PColor.black,
        fontSize: 18,
        marginLeft: 70,
        marginRight: 70,
        textAlign: 'center'
    }
});