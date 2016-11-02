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
import TextInput from 'TextInput';
import PColor from '../utils/PColor.js';

export default class PTextInput extends React.Component {

    constructor(props) {
        super(props);
    }

    render() {
        return (
            <View style={[styles.root, this.props.style]}>
                <Image
                    style={styles.icon}
                    source={this.props.icon}/>
                <TextInput
                    style={[styles.input, {color:this.props.color}]}
                    underlineColorAndroid={this.props.lineColor}
                    keyboardType={this.props.keyboardType}
                    onBlur={this.props.onBlur}
                    onChangeText={this.props.onChangeText}
                    onFocus={this.props.onFocus}
                    placeholder={this.props.placeholder}
                    placeholderTextColor={this.props.placeholderTextColor}
                    secureTextEntry={this.props.secureTextEntry}
                    />
            </View>
        );
    }
}

const styles = StyleSheet.create({

    root: {
        flexDirection: 'row',
        alignItems: 'center',
        height: 50,
    },

    icon: {
        position: 'absolute',
        width: 22,
        height: 22,
        top: 14,
        left: 5,
    },

    input: {
        flex: 1,
        height: 50,
        paddingLeft: 30,
    }
});