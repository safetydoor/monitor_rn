/**
 * Created by laps on 9/24/16.
 */
import React, {
    PropTypes,
} from 'react';

import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
const SideMenu = require('react-native-side-menu');

class ContentView extends React.Component {
    render() {
        return (
            <View style={styles.container}>
<Text style={styles.welcome}>
Welcome to React Native!
</Text>
<Text style={styles.instructions}>
To get started, edit index.ios.js
</Text>
<Text style={styles.instructions}>
Press Cmd+R to reload,{'\n'}
Cmd+Control+Z for dev menu
</Text>
</View>
);
}
}

class Menu extends React.Component{
    render() {

        return (
           <View>
            <Text>sdfsdfsd</Text>
            </View>
    );
    }

export default class MainScreen extends React.Component{
    render() {
        const menu = <Menu navigator={navigator}/>;

        return (
            <SideMenu menu={menu}>
            <ContentView/>
            </SideMenu>
    );
}