/**
 * Created by laps on 10/30/16.
 */


import React, {PropTypes} from 'react';
import {StyleSheet, Text, View, Image, ListView, RefreshControl, TouchableOpacity, TouchableWithoutFeedback} from 'react-native';
import AsyncStorage from 'AsyncStorage';
import InteractionManager from 'InteractionManager';
import BackAndroid from 'BackAndroid';

import PTitleBar from '../components/PTitleBar.js';
import PListRowView from '../components/PListRowView.js';
import PButton from '../components/PButton.js';
import PColor from '../utils/PColor.js';
import Interface from '../utils/Interface.js';
import PHttpUtils from '../utils/PHttpUtils.js';
import PToast from '../utils/PToast.js';
import $op from '../utils/PObjectProxy.js';

const FavoritesKey = 'FavoritesKey';

export default class LiveListScreen extends React.Component {

    ds = undefined;
    dataBlob = [[], []];
    sectionIDs = [0, 1];
    sectionTitles = ['收藏列表', '直播列表'];
    pageNum = 0;

    constructor(props) {
        super(props);
        this.renderRefreshControl = this.renderRefreshControl.bind(this);
        this.renderSectionHeader = this.renderSectionHeader.bind(this);
        this.renderEmptyView = this.renderEmptyView.bind(this);
        this.renderHeader = this.renderHeader.bind(this);
        this.renderRow = this.renderRow.bind(this);
        this.renderFooter = this.renderFooter.bind(this);
        this.renderNoMoreView = this.renderNoMoreView.bind(this);
        this.renderSeparator = this.renderSeparator.bind(this);
        this.renderRowLeft = this.renderRowLeft.bind(this);

        this._onBackPress = this._onBackPress.bind(this);
        this._onRowPress = this._onRowPress.bind(this);
        this._reload = this._reload.bind(this);
        this._loadMore = this._loadMore.bind(this);
        this._loadMore = this._loadMore.bind(this);
        this._buildDataBlob = this._buildDataBlob.bind(this);

        this.ds = new ListView.DataSource({
            rowHasChanged: (r1, r2) => r1 !== r2,
            sectionHeaderHasChanged: (s1, s2) => s1 !== s2,
        });
        this.state = {
            dataSource: this.ds,
            refreshing: false,
            hasMore: true,
        };
    }

    componentWillMount() {
        BackAndroid.addEventListener('hardwareBackPress', this._onBackPress);
    }

    componentWillUnmount() {
        BackAndroid.removeEventListener('hardwareBackPress', this._onBackPress);
    }

    componentDidMount() {
        AsyncStorage.getItem(FavoritesKey, (err, result) => {
            if (result) {
                let favorites = JSON.parse(result);
                this.dataBlob[0] = favorites;
            }
            this._reload();
        });
    }

    render() {
        return (
            <View style={styles.root}>
                <PTitleBar
                    leftIcon={require('../images/back_ic.png')}
                    title={'直播列表'}
                    navigator={this.props.navigator}
                    />
                <ListView
                    style={styles.listView}
                    ref={"listView"}
                    dataSource={this.state.dataSource}
                    renderHeader={this.renderHeader}
                    renderSectionHeader={this.renderSectionHeader}
                    renderRow={this.renderRow}
                    renderFooter={this.renderFooter}
                    showsVerticalScrollIndicator={false}
                    refreshControl={this.renderRefreshControl()}
                    />
            </View>);
    }

    renderHeader() {
        if (this.dataBlob[1].length == 0) {
            return this.renderNoMoreView();
        }
    }

    renderSectionHeader(sectionData, sectionID) {
        return (
            <View style={styles.section}>
                <Text style={styles.sectionText}>{this.sectionTitles[sectionID]}</Text>
            </View>
        )
    }

    renderSeparator(sectionID, rowID) {
        return (
            <View key={rowID} style={styles.separator}/>
        )
    }

    renderRow(rowData, sectionId, rowId) {
        return (
            <View>
                <PListRowView
                    style={styles.row}
                    renderLeftView={this.renderRowLeft(rowData, sectionId)}
                    title={rowData.name}
                    accessoryType={'indicator'}
                    onPress={()=>{this._onRowPress(rowData)}}
                    />
                <View style={styles.separator}/>
            </View>
        )
    }

    renderRowLeft(rowData, sectionId) {
        if (sectionId === 0) {
            return (
                <PButton
                    style={styles.button}
                    content={'删除'}
                    textColor={PColor.white}
                    textColorPressed={PColor.white}
                    backgroundColor={PColor.red}
                    backgroundColorPressed={PColor.red_press}
                    onPress={()=>{this._onDeletePress(rowData)}}
                    />
            )
        } else {
            return (
                <PButton
                    style={styles.button}
                    content={'收藏'}
                    textColor={PColor.white}
                    textColorPressed={PColor.white}
                    backgroundColor={PColor.blue}
                    backgroundColorPressed={PColor.blue_press}
                    onPress={()=>{this._onCollectPress(rowData)}}
                    />
            )
        }
    }

    renderFooter() {
        if (this.state.hasMore) {
            return (
                <TouchableOpacity onPress={this._loadMore}>
                    <Text style={styles.noMoreText}>点击加载更多</Text>
                </TouchableOpacity>
            );
        } else {
            return (
                <Text style={styles.noMoreText}>没有了</Text>
            );
        }
    }

    renderEmptyView() {
        return (
            <View/>
        );
    }

    renderNoMoreView() {
        if (!this.state.hasMore) {
            return (
                <View style={styles.noMore}>
                    <Text style={styles.noMoreText}>- 没有更多了 -</Text>
                </View>
            );
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

    _onRowPress(rowData) {
        Interface.jumpToLivePlay({
            name: rowData.name,
            address: rowData.address,
        })
    }

    _onDeletePress(rowData) {
        let favorites = this.dataBlob[0];
        let result = [];
        for (let item of favorites) {
            if (item.id !== rowData.id) {
                result.push(item);
            }
        }
        AsyncStorage.setItem(FavoritesKey, JSON.stringify(result), (err)=> {
            //TODO:错误处理
            if (err) {
                PToast.show('删除失败');
            } else {
                this.dataBlob[0] = result;
                this._buildDataBlob(this.state.hasMore);
            }
        });
    }

    _onCollectPress(rowData) {
        let favorites = this.dataBlob[0];
        for (let item of favorites) {
            if (item.id === rowData.id) {
                PToast.show('已经收藏');
                return;
            }
        }
        favorites.push(rowData);
        AsyncStorage.setItem(FavoritesKey, JSON.stringify(favorites), (err)=> {
            //TODO:错误处理
            if (err) {
                PToast.show('收藏失败');
            } else {
                this.dataBlob[0] = favorites;
                this._buildDataBlob(this.state.hasMore);
            }
        });
    }

    _reload() {
        if (this.state.refreshing) {
            return;
        }
        this.setState({
            refreshing: true,
        });

        this.pageNum = 0;
        this._loadData();
    }

    _loadMore() {
        Interface.showLoading();
        this._loadData();
    }

    _loadData() {
        PHttpUtils.requestLiveList(this.pageNum)
            .then((response) => {
                return response.json()
            })
            .then((responseData) => {
                if (this.pageNum == 0) {
                    this.dataBlob[1] = [];
                }
                this.pageNum = this.pageNum + 1;
                let datas = $op(responseData).getArray('result')
                let hasMore = datas.length !== 0;
                this.dataBlob[1] = this.dataBlob[1].concat(datas);
                Interface.hideLoading();
                this._buildDataBlob(hasMore);

            }).catch((error)=> {
                PToast.show('数据加载失败');
                Interface.hideLoading();
                InteractionManager.runAfterInteractions(() => {
                    this.setState({
                        refreshing: false,
                        hasMore: true,
                    })
                });
            });
    }

    _buildDataBlob(hasMore) {
        let rowIDs = [];
        let favLen = this.dataBlob[0].length;
        let liveLen = this.dataBlob[1].length;
        let favIDs = [];
        for (let i = 0; i < favLen; i++) {
            favIDs.push(i);
        }

        let liveIDs = [];
        for (let i = 0; i < liveLen; i++) {
            liveIDs.push(i);
        }
        rowIDs.push(favIDs);
        rowIDs.push(liveIDs);

        InteractionManager.runAfterInteractions(() => {
            this.setState({
                dataSource: this.ds.cloneWithRowsAndSections(this.dataBlob, this.sectionIDs, rowIDs),
                refreshing: false,
                hasMore: hasMore,
            })
        });
    }

    _onBackPress() {
        this.props.navigator.pop();
        return true;
    }
}

const styles = StyleSheet.create({
    root: {
        flexDirection: 'column',
        position: 'absolute',
        right: 0,
        left: 0,
        top: 0,
        bottom: 0,
        backgroundColor: PColor.white,
    },

    listView: {
        flex: 1,
    },

    row: {
        paddingLeft: 15,
        paddingTop: 15,
        paddingBottom: 15,
    },

    section: {
        paddingLeft: 15,
        paddingTop: 10,
        paddingBottom: 10,
        backgroundColor: PColor.light,
        justifyContent: "center",
    },

    sectionText: {
        color: PColor.black,
        fontSize: 18,
        textAlign: 'left',
    },

    separator: {
        backgroundColor: PColor.light,
        height: 1,
        marginLeft: 15,
    },

    refreshControl: {},

    noMoreText: {
        flex: 1,
        paddingTop: 15,
        paddingBottom: 15,
        color: PColor.black,
        fontSize: 16,
        textAlign: 'center',
        backgroundColor: PColor.light
    },

    button: {
        width: 60,
        height: 30,
        alignItems: 'center',
        justifyContent: "center",
        marginRight: 20,
    }

});