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
import Dimensions from 'Dimensions';

import PTitleBar from '../../components/PTitleBar.js'
import PColor from '../../utils/PColor.js';
import PDateUtils from '../../utils/PDateUtils.js';
import $op from '../../utils/PObjectProxy.js';

const {height, width} = Dimensions.get('window');

export default class MainWeatherView extends React.Component {

    constructor(props) {
        super(props);
    }

    render() {
        let date = new Date();
        let dateString = PDateUtils.format(date, 'MM月dd日 w');
        let timeString = PDateUtils.format(date, 'hh:mm');

        let city = $op(this.props.weather).getString('city');
        let temp = $op(this.props.weather).getString('temp');
        let l_temp = $op(this.props.weather).getString('l_temp');
        let weather = $op(this.props.weather).getString('weather');
        let h_temp = $op(this.props.weather).getString('h_temp');
        let locationString = city ? city + ' ' + temp + '°' : ' ';
        let temperature = weather ? weather + ' ' + l_temp + '° ~ ' + h_temp + '°' : ' ';
        return (
            <View style={styles.root}>
                <Image
                    style={styles.bg}
                    resizeMode={'stretch'}
                    source={require('../../images/weather_bg.png')}
                    />
                <View style={styles.content}>
                    <Text style={styles.date}>{dateString}</Text>
                    <Text style={styles.time}>{timeString}</Text>
                    <Text style={styles.location}>{locationString}</Text>
                    <Text style={styles.temperature}>{temperature}</Text>
                </View>
            </View>
        );
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
    content: {
        marginLeft: 15,
        marginRight: 15,
        flexDirection: 'column',
    },
    date: {
        flex: 1,
        color: PColor.white,
        marginTop: 30,
        fontSize: 14,
    },
    time: {
        flex: 1,
        color: PColor.white,
        marginTop: 10,
        fontSize: 20,
    },
    location: {
        flex: 1,
        color: PColor.white,
        marginTop: 10,
        fontSize: 18,
    },
    temperature: {
        flex: 1,
        color: PColor.white,
        marginTop: 10,
        fontSize: 15,
        textAlign: 'right',
    },
});