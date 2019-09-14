# CMake-based project template without Android Studio

Android Studio is a terrible overloaded mess of unneeded things. Let's stop wasting our time and start using precise and clean command line tools. This template is largely inspired by this [tutorial](https://medium.com/@authmane512/how-to-build-an-apk-from-command-line-without-ide-7260e1e22676).

<img width="200px" src="screenshot.png"/>

## Prerequisites

Install JDK and ADB packages:

```
sudo apt-get install openjdk-8-jdk-headless adb aapt
```

Download and install Android tools, build-tools and platform SDK to /opt/android-sdk:

```
wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip
sudo mkdir -p /opt/android-sdk
unzip sdk-tools-linux-3859397.zip
sudo mv tools /opt/android-sdk/
sudo PATH=/usr/lib/jvm/java-8-openjdk-amd64/bin:$PATH /opt/android-sdk/tools/bin/sdkmanager "platform-tools" "platforms;android-28"
sudo PATH=/usr/lib/jvm/java-8-openjdk-amd64/bin:$PATH /opt/android-sdk/tools/bin/sdkmanager "build-tools;28.0.0"
```

## Generate Signing Key

```
keytool -genkeypair -validity 365 -keystore mykey.keystore -keyalg RSA -keysize 2048
```

## Building

```
make
```

## Testing

Switch your cell phone to Developer mode with USB debugging and USB package installation enabled as shown e.g. [here](https://www.syncios.com/android/how-to-debug-xiaomi-mi-max-mix.html). Connect with a USB cable and roll the application onto it:

```
make test
```

