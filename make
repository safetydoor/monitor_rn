使用前需要搭建开发环境：http://reactnative.cn/docs/0.39/getting-started.html

Android Debug 方式：
1，cd到项目的rn目录下
2，如果是Android5.0以上系统，执行命令adb reverse tcp:8081 tcp:8081
3，执行命令： nam start
4，按照正常的方式debug运行代码。
5，运行后，如果是5.0以上的手机，可以正常运行；如果是5.0以下的手机，需要摇一摇手机，然后点击Dev Settings 然后点击Debug server host &… 然后输入你电脑的ip和rn端口（8081）。例如192.168.1.103：8081
6，尽量还是用Android5.0以上的机型进行调试

Android 打包:
1，cd到项目rn目录下，执行命令：
react-native bundle --platform android --dev false --entry-file index.android.js --bundle-output ../android/app/src/main/assets/index.android.bundle --assets-dest ../android/app/src/main/res/
2，按照正常程序签名打包
laps.jks:
laps abc123456

iOS Debug方式
1，cd到项目的rn目录下
2，执行命令： nam start
3，按照正常的方式debug运行代码。
4，如果是模拟器的话则可正常运行
5，如果是真机的话，需要按照android debug步骤5进行设置。

iOS 打包:
TODO