# r2Cam

r2Cam is a real-time video streaming framework in Swift for Raspberry Pi, ESP32 and and others.

The purpose of this library is to provide a simple client interface displaying a real-time H.264 video (e.g. Raspberry Pi Camera) and JPEG buffers (e.g. ESP32-CAM or any equivalent).

It currently expects TCP server endpoints to provide the video stream.

## 1. Conceptual Usage
The snippet below demonstrates how the streaming client can be created and how an `AVSampleBufferDisplayLayer` is attached. For a full example, see the [Example Project](Example).
```swift
import AVFoundation

// ...

// The video stream can be enqued directly to an `AVSampleBufferDisplayLayer`.
let displayLayerRPi = AVSampleBufferDisplayLayer()
let displayLayerESP = AVSampleBufferDisplayLayer()

// ...

// For Raspberry Pi Camera
let videoConnectionRPi = VideoConnectionFactory.shared.create(.h264(host: "192.168.0.42", port: 4444))
// `displayLayerRPi` will receive the video stream from your Raspberry Pi Camera.
videoConnectionRPi.displayLayer = displayLayerRPi

// For ESP32-CAM
let videoConnectionESP = VideoConnectionFactory.shared.create(.jpeg(host: "192.168.0.43", port: 4444))
// `displayLayerESP` will receive the video stream from your ESP32-CAM.
videoConnectionESP.displayLayer = displayLayerESP

// Start receiving images from your Raspberry Pi Camera.
try? videoConnectionRPi.start()

// Start receiving images from your ESP32-CAM.
try? videoConnectionESP.start()

```

## 2. Server Side
The framework currently only supports TCP connections.

### 2.1 Raspberry Pi Camera
There are plenty of ways how to provide a TCP server endpoint exposing your Raspberry Pi Camera stream, and here's one using (the now obsolete `raspivid`).

`$ raspivid -n -ih -t 0 -rot 0 -w 640 -h 480 -fps 15 -b 1000000 -o - | nc -lkv4 4444`

### 2.2 ESP32-CAM (or similar)
To stream video over TCP from your ESP device, the `esp_camera.h` library, and a `WiFiClient` from the `WiFi.h` library can be used. A tested example can be found here: [Arduino / ESP32-CAM TCP Server](https://github.com/TordWessman/ESP32-CAM-TCP-server).

## 3. Configuration
At the time of writing, the number of configuration options is very limited...

### 3.1 Declarations
* `VideoConnection` is the protocol for the video stream router.
* A `VideoConnectionDelegate` can be assigned to a `VideoConnection`s `delegate` property to receive image buffers and error information.

## 4. Disclaimer
This project is currently in a POC state, but I dare _everyone_ to try it. Or even better - help me.

## 5. License
r2Cam is released under the MIT license. See [LICENCE](LICENCE)