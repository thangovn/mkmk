import React, {Component} from 'react';
import {Text, View, requireNativeComponent} from 'react-native';
import RtcEngine, {
  VideoRenderMode,
  RtcLocalView,
  ConnectionStateType,
  ChannelProfile,
  ClientRole,
} from './src/index';

const RCTTiButtonView = requireNativeComponent(
  'RCTTiButtonView',
  MyCustomView,
  {},
);
class MyCustomView extends React.PureComponent<any> {
  // _onClick = (event) => {
  //   if (!this.props.onClick) {
  //     return;
  //   }

  //   // process raw event...
  //   this.props.onClick(event.nativeEvent);
  // }

  render() {
    return <RCTTiButtonView />;
  }
}
export default class App extends Component {
  _engine?: RtcEngine;
  backHandler: any;

  state: any = {
    token: null,
    joinSucceed: false,
    peerIds: [],
    isHost: true,
    switchCamera: true,
    connectionState: ConnectionStateType.Connecting,
    errInit: null,
  };
  _startCall = async (channelName: string, uid: number) => {
    await this._engine?.joinChannel(this.state.token, channelName, null, uid);
  };
  componentDidMount() {
    this.init('3098260ca7614087844230aec70a64eb');
    setTimeout(() => {
      this._startCall('bnLDGXAlm9lGYyu', 9999);
    }, 1000);
  }

  init = async (appId: string) => {
    this._engine = await RtcEngine.create(appId).catch(err =>
      this.setState({errInit: 'Invalid Key'}),
    );

    // Enable the video module.
    await this._engine.enableVideo();

    // Enable the local video preview.
    await this._engine.startPreview();

    await this._engine.setVideoEncoderConfiguration({
      bitrate: 2000,
      frameRate: 60,
      dimensions: {width: 640, height: 360},
    });

    await this._engine.setBeautyEffectOptions(true, {});

    // await this._engine.enableVirtualBackground(true, {});
    // Set the channel profile as live streaming.
    await this._engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    // Set the usr role as host.
    await this._engine.setClientRole(ClientRole.Broadcaster);
    await this._engine.initTiSDK();

    // Listen for the UserJoined callback.
    // This callback occurs when the remote user successfully joins the channel.
    this._engine.addListener('UserJoined', (uid, elapsed) => {
      // console.log('UserJoined', uid, elapsed);
      const {peerIds} = this.state;
      if (peerIds.indexOf(uid) === -1) {
        this.setState({
          peerIds: [...peerIds, uid],
        });
      }
    });

    // Listen for the UserOffline callback.
    // This callback occurs when the remote user leaves the channel or drops offline.
    this._engine.addListener('UserOffline', (uid, reason) => {
      // console.log('UserOffline', uid, reason);
      const {peerIds} = this.state;
      this.setState({
        // Remove peer ID from state array
        peerIds: peerIds.filter(id => id !== uid),
      });
    });

    // Listen for the JoinChannelSuccess callback.
    // This callback occurs when the local user successfully joins the channel.
    this._engine.addListener(
      'JoinChannelSuccess',
      async (channel, uid, elapsed) => {
        // console.log('JoinChannelSuccess', channel, uid, elapsed);
        this.setState({
          joinSucceed: true,
        });
        // await this._engine?.setTiSDK();

        await this._engine.muteAllRemoteAudioStreams(true);
        await this._engine.muteAllRemoteVideoStreams(true);
      },
    );

    // this._engine.addListener('Warning', warn => console.log('Warn', warn));
    this._engine.addListener('Error', error => console.log('Error', error));

    this._engine.addListener(
      'ConnectionStateChanged',
      (state: ConnectionStateType, reason: any) => {
        // console.log('ConnectionStateChanged', state, reason);
        this.setState({connectionState: state});
      },
    );
  };

  render() {
    return (
      <View style={{flex: 1}}>
        <RtcLocalView.SurfaceView
          style={{flex: 1}}
          channelId={'bnLDGXAlm9lGYyu'}
          renderMode={VideoRenderMode.Hidden}
        />
      </View>
    );
  }
}
