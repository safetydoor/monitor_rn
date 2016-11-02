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

import PColor from '../../utils/PColor.js';

export default class MainLumpView extends React.Component {

    constructor(props) {
        super(props);
    }

    render() {

        return (
            <TouchableOpacity onPress={this.props.onPress}>
                <View style={[styles.root, {...this.props.size}]}>
                    <Image
                        style={[styles.bg, {...this.props.size}]}
                        resizeMode={'stretch'}
                        source={this.props.bg}
                        />
                    <Text style={styles.title}>{this.props.title}</Text>
                </View>
            </TouchableOpacity>
        );
    }
}

const styles = StyleSheet.create({

    root: {
        width: 165,
        height: 94,
    },

    bg: {
        width: 165,
        height: 94,
        position: 'absolute',
        top: 0,
        left: 0,
    },
});