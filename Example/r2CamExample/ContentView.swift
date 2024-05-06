//
//  ContentView.swift
//  r2CamExample
//
//  Created by Tord Wessman on 2024-05-02.
//

import SwiftUI
import r2Cam

struct ContentView: View {

//    // For ESP-32 streaming
//    //@ObservedObject var videoViewModel = VideoViewModel(.jpeg(host: "<ESP32-CAM Address>", port: 1234))
//
//    // For Raspberry Pi streaming
    @ObservedObject var videoViewModel = VideoViewModel(.h264(host: "<Raspberry Pi Address>", port: 4444))

    var body: some View {
        VStack {
            if videoViewModel.isLoading {
                ProgressView()
            }
            ZStack {
                VideoView(viewModel: videoViewModel)
                    .aspectRatio(contentMode: .fit)
                Text(videoViewModel.errorMessage)
                    .foregroundColor(.red)
            }
            Spacer()
            Button("Start Stream") {
                videoViewModel.start()
            }
        }
        .padding()
    }
}
