/**
 * Created by laps on 7/1/16.
 * 列表行组件，适用于各种列表样式
 *
 * title:           标题            string/function(自定义render)
 * subTitle:        子标题          string/function(自定义render)
 * notesTitle:      标题备注        string/function(自定义render)
 * image:           左边图片        source
 * renderLeftView:  自定义左侧view
 * accessoryType:   右侧的附加类型 默认none(什么都不显示), indicator(显示小箭头)
 * renderRightView: 自定义右侧view
 * onPress          点击事件
 */
'use strict';

import React, {
    PropTypes,
} from 'react';
import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
import Image from 'Image';
import TouchableOpacity from 'TouchableOpacity';

import PColor from '../utils/PColor.js';

export default class PListRowView extends React.Component {

    constructor(props) {
        super(props);
        this.renderContent = this.renderContent.bind(this);
        this.renderLeftView = this.renderLeftView.bind(this);
        this.renderSubTitle = this.renderSubTitle.bind(this);
        this.renderNotesTitle = this.renderNotesTitle.bind(this);
        this.renderRightView = this.renderRightView.bind(this);
        this.renderTitle = this.renderTitle.bind(this);
        this.onPress = this.onPress.bind(this);
    }

    render() {
        if (this.props.onPress) {
            return (
                <TouchableOpacity onPress={this.onPress}>
                    {this.renderContent()}
                </TouchableOpacity>
            );
        } else {
            return this.renderContent();
        }
    }

    renderContent() {
        let canRenderLeft = (this.props.image != undefined || this.props.renderLeftView != undefined);
        let canRenderRight = (this.props.accessoryType != 'none' || this.props.renderRightView != undefined);
        let canRenderSubTitle = (this.props.subTitle != undefined);
        let canRenderNotesTitle = (this.props.notesTitle != undefined);
        return (
            <View style={[styles.root, this.props.style]}>
                {canRenderLeft && this.renderLeftView()}
                <View style={styles.middleView}>
                    <View style={styles.titleView}>
                        {this.renderTitle()}
                        {canRenderNotesTitle && this.renderNotesTitle()}
                    </View>
                    {canRenderSubTitle && this.renderSubTitle()}
                </View>
                {canRenderRight && this.renderRightView()}
            </View>
        )
    }

    renderLeftView() {
        let type = typeof(this.props.renderLeftView);
        if (type == 'object') {
            return this.props.renderLeftView;
        } else if (type == 'function') {
            return this.props.renderLeftView();
        } else {
            return (
                <Image
                    style={styles.leftView}
                    source={this.props.image}/>
            );
        }
    }

    renderTitle() {
        const type = typeof(this.props.title);
        if (type == 'object') {
            return this.props.title;
        } else if (type == 'function') {
            return this.props.title();
        } else {
            return (
                <Text style={styles.title} numberOfLines={1}>{this.props.title}</Text>
            );
        }
    }

    renderSubTitle() {
        const type = typeof(this.props.subTitle);
        if (type == 'object') {
            return this.props.subTitle;
        } else if (type == 'function') {
            return this.props.subTitle();
        } else {
            return (
                <Text style={styles.subTitle}>{this.props.subTitle}</Text>
            );
        }
    }

    renderNotesTitle() {
        const type = typeof(this.props.notesTitle);
        if (type == 'object') {
            return this.props.notesTitle;
        } else if (type == 'function') {
            return this.props.notesTitle();
        } else {
            return (
                <Text style={styles.notesTitle}>{this.props.notesTitle}</Text>
            );
        }
    }

    renderRightView() {
        const type = typeof(this.props.renderRightView);
        if (type == 'object') {
            return this.props.renderRightView;
        } else if (type == 'function') {
            return this.props.renderRightView();
        } else if (this.props.accessoryType == 'indicator') {
            let source = require('../images/arrow_ic.png')
            return (
                <Image
                    style={styles.rightView}
                    source={source}/>
            );
        } else {
            return (<View />);
        }
    }

    onPress() {
        if (this.props.onPress) {
            this.props.onPress();
        }
    }
}

PListRowView.defaultProps = {
    accessoryType: 'none',
};

PListRowView.propTypes = {
    title: PropTypes.any,
    subTitle: PropTypes.any,
    notesTitle: PropTypes.any,
    image: PropTypes.any,
    renderLeftView: PropTypes.any,
    accessoryType: PropTypes.oneOf(['none', 'indicator']),
    renderRightView: PropTypes.any,
};


const styles = StyleSheet.create({

    root: {
        flexDirection: 'row',
    },

    leftView: {
        marginRight: 3 * 10,
        alignItems: 'center',
        justifyContent: 'center',
    },

    rightView: {
        width: 11,
        height: 18,
        marginRight: 3 * 10,
        alignSelf: 'center',
    },

    middleView: {
        flex: 1,
        flexDirection: 'column',
    },

    titleView: {
        flexDirection: 'row',
    },

    title: {
        flex: 1,
        color: PColor.black,
        fontSize: 15,
    },

    notesTitle: {
        color: PColor.black,
        fontSize: 12,
    },

    subTitle: {
        flex: 1,
        color: PColor.gray,
        fontSize: 12,
        marginTop: 5,
    },
});
