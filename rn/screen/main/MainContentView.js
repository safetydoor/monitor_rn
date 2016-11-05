/**
 * Created by laps on 10/29/16.
 */


import React, {
    PropTypes,
} from 'react';

import StyleSheet from 'StyleSheet';
import View from 'View';
import Text from 'Text';
import Dimensions from 'Dimensions';
import ListView from 'ListView';
import Image from 'Image';
import RefreshControl from 'RefreshControl';

import PTitleBar from '../../components/PTitleBar.js';
import PTabBar from '../../components/PTabBar.js';
import PListRowView from '../../components/PListRowView.js';
import LiveListScreen from '../LiveListScreen.js';
import WebScreen from '../WebScreen.js';

import MainWeatherView from './MainWeatherView.js';
import MainLumpView from './MainLumpView.js';
import MainAdView from './MainAdView.js';

import PColor from '../../utils/PColor.js';
import Interface from '../../utils/Interface.js';
import PToast from '../../utils/PToast.js';
import PHttpUtils from '../../utils/PHttpUtils.js';
import $op from '../../utils/PObjectProxy.js';

const {height, width} = Dimensions.get('window');
const Swiper = require('react-native-swiper');

export default class MainContentView extends React.Component {

    weather = {};
    category = [];
    ads = [];
    tabIndex = 0;

    constructor(props) {
        super(props);
        this.renderHeader = this.renderHeader.bind(this);
        this.renderAdViews = this.renderAdViews.bind(this);
        this.renderRow = this.renderRow.bind(this);
        this.renderFooter = this.renderFooter.bind(this);
        this.renderSeparator = this.renderSeparator.bind(this);
        this.renderRowLeft = this.renderRowLeft.bind(this);
        this.renderRefreshControl = this.renderRefreshControl.bind(this);

        this._onTabSelectedChange = this._onTabSelectedChange.bind(this);
        this._onCameraPress = this._onCameraPress.bind(this);
        this._onRowPress = this._onRowPress.bind(this);
        this._onTVPress = this._onTVPress.bind(this);
        this._reload = this._reload.bind(this);
        this._buildBlob = this._buildBlob.bind(this);
        this.ds = new ListView.DataSource({
            rowHasChanged: (r1, r2) => r1 !== r2,
        });
        this.state = {
            dataSource: this.ds,
            weather: this.weather,
            refreshing: false,
            tabIndex: this.tabIndex,
        };
    }

    componentDidMount() {
        Interface.showLoading();
        Interface.getWeather().then((result)=> {
            this.weather = result;
            return PHttpUtils.requestCategory();
        }).then((response)=> {
            return response.json()
        }).then((responseData)=> {
            this.category = responseData.result;
            return PHttpUtils.requestAdList();
        }).then((response)=> {
            return response.json()
        }).then((responseData)=> {
            this.ads = responseData.result;
            this._buildBlob();
        }).catch((error)=> {
            this._buildBlob();
            PToast.show('数据加载失败')
        })
    }

    render() {

        return (
            <View style={styles.root}>
                <PTitleBar
                    leftIcon={require('../../images/main_title_ic.png')}
                    title={'首页'}
                    onLeftPress={this.props.onLeftPress}
                    />
                {this.renderAdViews()}
                <ListView
                    style={styles.listView}
                    dataSource={this.state.dataSource}
                    renderRow={this.renderRow}
                    renderHeader={this.renderHeader}
                    renderFooter={this.renderFooter}
                    renderSeparator={this.renderSeparator}
                    refreshControl={this.renderRefreshControl()}
                    />
            </View>
        );
    }

    renderAdViews() {
        let adViews = [];
        for (let ad of this.ads) {
            adViews.push((
                <MainAdView
                    key={ad.id}
                    adUrl={ad.adUrl}
                    imageUrl={ad.imageUrl}
                    name={ad.name}
                    navigator={this.props.navigator}
                    />
            ));
        }
        if (adViews.length > 0) {
            return (
                <Swiper
                    height={164}
                    loop={true}
                    index={0}
                    autoplay={true}
                    >
                    <MainWeatherView weather={this.weather}/>
                    {adViews}
                </Swiper>
            )
        } else {
            return (
                <Swiper
                    height={164}
                    loop={true}
                    index={0}
                    autoplay={true}
                    >
                    <MainWeatherView weather={this.weather}/>
                </Swiper>
            )
        }
    }

    renderRefreshControl() {
        return (
            <RefreshControl
                onRefresh={this._reload}
                refreshing={this.state.refreshing}
                tintColor={'#b7242c'}
                colors={['#b7242c']}/>
        )
    }

    renderHeader() {
        let size = {
            width: (width - 45) / 2,
            height: 94,
        };
        let tabs = [];
        for (let item of this.category) {
            tabs.push(item.name);
        }
        return (
            <View>
                <View style={styles.lumps}>
                    <MainLumpView
                        size={size}
                        bg={require('../../images/menu_camera.png')}
                        onPress={this._onCameraPress}
                        />
                    <MainLumpView
                        size={size}
                        bg={require('../../images/menu_tv.png')}
                        onPress={this._onTVPress}
                        />
                </View>
                <PTabBar
                    style={styles.tab}
                    tabs={tabs}
                    themeColor={PColor.blue}
                    selectedIndex={this.state.selectedIndex}
                    onSelectedChange={this._onTabSelectedChange}
                    />
            </View>
        );
    }

    renderRow(rowData) {
        return (
            <PListRowView
                style={styles.row}
                accessoryType={'indicator'}
                renderLeftView={this.renderRowLeft(rowData)}
                title={rowData.name}
                subTitle={rowData.desc}
                onPress={()=>{this._onRowPress(rowData)}}
                />
        )
    }

    renderRowLeft(rowData) {
        return (
            <Image
                style={styles.rowLeftImage}
                source={{uri:rowData.iconUrl}}
                />
        );
    }

    renderFooter() {
        return (<View style={styles.footer}/>);
    }

    renderSeparator(sectionID, rowID) {
        return (
            <View key={rowID} style={styles.separator}/>
        )
    }

    _onTabSelectedChange(index) {
        this.tabIndex = index;
        this._buildBlob();
    }

    _onCameraPress() {
        Interface.jumpToCamera();
    }

    _onTVPress() {
        this.props.navigator.push({
            name: 'LiveList',
            component: LiveListScreen,
        })
    }

    _onRowPress(rowData) {
        this.props.navigator.push({
            name: 'WebScreen',
            component: WebScreen,
            params: {
                title: rowData.name,
                url: rowData.url
            }
        })
    }

    _reload() {
        this.setState({
            refreshing: true,
        });
        PHttpUtils.requestCategory(this.pageNum)
            .then((response) => {
                return response.json()
            }).then((responseData) => {
                this.category = responseData.result;
                this._buildBlob();
            }).catch((error)=> {
                PToast.show('数据加载失败');
            });
    }

    _buildBlob() {
        Interface.hideLoading();
        if (this.category && this.category.length > 0 && this.category.length > this.tabIndex) {
            let datas = this.category[this.tabIndex].lumps;
            this.setState({
                refreshing: false,
                weather: this.weather,
                dataSource: this.ds.cloneWithRows(datas)
            })
        }
    }

}

const styles = StyleSheet.create({

    root: {
        position: 'absolute',
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
        flexDirection: 'column',
        backgroundColor: PColor.light
    },

    lumps: {
        marginTop: 10,
        backgroundColor: PColor.white,
        padding: 15,
        flexDirection: 'row',
        justifyContent: 'space-between'
    },
    tab: {
        flex: 1,
        marginTop: 10,
        backgroundColor: PColor.white,
        paddingLeft: 30,
        paddingRight: 30,
        paddingTop: 20,
        marginBottom: 1,
    },
    listView: {
        flex: 1,
    },
    row: {
        backgroundColor: PColor.white,
        padding: 15,
    },
    rowLeftImage: {
        width: 40,
        height: 40,
        marginRight: 10,
    },
    footer: {
        backgroundColor: PColor.light,
        height: 10,
        flex: 1
    },
    separator: {
        height: 1,
        width: 15,
        backgroundColor: PColor.white
    }
});