/**
 * Created by laps on 10/30/16.
 */

import React, {
    PropTypes,
} from 'react';

import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
import Image from 'Image';
import Dimensions from 'Dimensions';
import TouchableOpacity from 'TouchableOpacity';

import WebScreen from '../WebScreen.js';

import PTitleBar from '../../components/PTitleBar.js'
import PColor from '../../utils/PColor.js';

const {height, width} = Dimensions.get('window');

export default class MainAdView extends React.Component {

    constructor(props) {
        super(props);
        this._onPress = this._onPress.bind(this);
    }

    render() {

        return (
            <TouchableOpacity onPress={this._onPress}>
                <View style={styles.root}>
                    <Image
                        style={styles.bg}
                        resizeMode={'stretch'}
                        source={{uri:this.props.imageUrl}}
                        />
                    <Text style={styles.title}>{this.props.name}</Text>
                </View>
            </TouchableOpacity>
        );
    }

    _onPress() {
        this.props.navigator.push({
            name: 'WebScreen',
            component: WebScreen,
            params: {
                title: this.props.name,
                url: this.props.adUrl
            }
        })
    }
}

const styles = StyleSheet.create({

    root: {
        width: width,
        height: 164,
        flexDirection: 'column',
    },
    bg: {
        width: width,
        height: 164,
        position: 'absolute',
        top: 0,
        left: 0,
    },
    title: {
        width: width,
        position: 'absolute',
        bottom: 0,
        left: 0,
        backgroundColor: '#00000033',
        color: PColor.white,
        textAlign: 'center',
        fontSize: 16,
        paddingTop: 10,
        paddingBottom: 10,
    }
});