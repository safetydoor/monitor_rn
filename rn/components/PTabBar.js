/**
 * Created by laps on 7/1/16.
 *
 * tabs:            ['Tab1', 'Tab2', 'Tab3'],
 * selectedIndex    默认选中的索引         默认为0
 * spaceWidth:      每个tab中间的宽度 ，如果宽度小于等于0，那么就会自动均等适配        默认为0
 * themeColor:      选中tab的标题颜色      默认为Color.Accent
 * onSelectedChange(index)       tab切换后的回调
 */
'use strict';

import React, {
  PropTypes,
} from 'react';
import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
import Image from 'Image';
import TouchableWithoutFeedback from 'TouchableWithoutFeedback';

import PColor from '../utils/PColor.js';

export default class PTabBar extends React.Component {

    constructor(props) {
        super(props);
        this.renderTab = this.renderTab.bind(this);
        this.onTabPress = this.onTabPress.bind(this);
        this.state = {
            selectedIndex: this.props.selectedIndex,
        }
    }

    render() {
        let index = 0;
        let rootStyle = {};
        if (this.props.spaceWidth <= 0) {
            rootStyle = {justifyContent: 'space-between'};
        }
        return (
            <View style={[styles.root, rootStyle, this.props.style]}>
                {
                    this.props.tabs.map((title)=> {
                        return this.renderTab(title, index++);
                    })
                }
            </View>
        );
    }

    renderTab(title, index) {
        let tabStyle = {};
        let titleStyle;
        let tabSelected = (index == this.state.selectedIndex);
        if (tabSelected) {
            tabStyle = {borderBottomColor: this.props.themeColor, borderBottomWidth: 2};
            titleStyle = {color: this.props.themeColor}
        } else {
            titleStyle = {color: PColor.subGrey}
        }
        const isLast = (index == (this.props.tabs.length - 1));
        return (
            <TouchableWithoutFeedback key={'tab' + index} onPress={()=>{this.onTabPress(index)}}>
                <View style={styles.tabContiner}>
                    <View style={[styles.tab, tabStyle]}>
                        <Text style={[styles.title, titleStyle]}>{title}</Text>
                    </View>
                    {!isLast && this.renderSpace(index)}
                </View>
            </TouchableWithoutFeedback>
        );
    }

    renderSpace(index) {
        return (
            <View key={'space' + index} style={{width: this.props.spaceWidth}}></View>
        );
    }

    onTabPress(index) {
        if (index !== this.state.selectedIndex) {
            this.setState({
                selectedIndex: index,
            });
            if (this.props.onSelectedChange) {
                this.props.onSelectedChange(index);
            }
        }
    }

}

PTabBar.defaultProps = {
    tabs: ['Tab1', 'Tab2', 'Tab3'],
    selectedIndex: 0,
    spaceWidth: 0,
    themeColor: '#000000'
};

PTabBar.propTypes = {
    tabs: PropTypes.array,
    spaceWidth: PropTypes.number,
    selectedIndex: PropTypes.number,
    themeColor: PropTypes.string,
    onSelectedChange: PropTypes.func,
};

const styles = StyleSheet.create({

    root: {
        flexDirection: 'row',
    },

    tabContiner: {
        flexDirection: 'row',
    },

    tab: {
        paddingLeft: 10,
        paddingRight: 10,
        paddingBottom: 10,
    },

    title: {
        fontSize: 15,
    }
});
