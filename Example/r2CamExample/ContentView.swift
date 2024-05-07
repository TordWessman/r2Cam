//
//  ContentView.swift
//  r2CamExample
//
//  Created by Tord Wessman on 2024-05-02.
//

import SwiftUI
import r2Cam

struct ContentView: View {

    // For ESP-32 streaming
    @ObservedObject var videoViewModelJPEG = VideoViewModel(.jpeg(host: "<ESP32-CAM Address>", port: 1234))

    // For Raspberry Pi streaming
    @ObservedObject var videoViewModelH264 = VideoViewModel(.h264(host: "<Raspberry Pi Address>", port: 4444))

    var body: some View {
        VStack {
            Text("ESP-32 Camera")
                .bold()
            ZStack {
                VideoView(viewModel: videoViewModelJPEG)
                    .frame(width: 320, height: 240)
                if videoViewModelJPEG.isLoading {
                    ProgressView()
                }
                Text(videoViewModelJPEG.errorMessage)
            }
            .padding(10)
            Text("Raspberry Pi Camera")
                .bold()
            ZStack {
                VideoView(viewModel: videoViewModelH264)
                    .frame(width: 320, height: 240)
                if videoViewModelH264.isLoading {
                    ProgressView()
                }
                Text(videoViewModelH264.errorMessage)
            }
            Spacer()
            Button("Start Stream") {
                videoViewModel.start()
            }
        }
        .padding()
    }
}
