//
//  WireDetectionPage.swift
//  Wire_Note_iOS
//
//  Created by John Smith on 2024/06/09.
//

import SwiftUI
import AVKit


struct NewWireDetectionPage: View {
    @State private var videoUrl: URL?
    @State private var isPickerPresented = false
    @State private var player = AVPlayer()
    @State private var isProcessing = false
    @State private var progress: Float = 0
    @State private var isShowingAlert = false
    @State private var errorMsg = ""
    @State private var alertTitle = "Error"
    @State private var worker: WireDetectionWorker?
    var percentage: String {
        return String(format: "%.0f%%", progress * 100)
    }
    
    var isProcessButtonDisabled: Bool {
        return videoUrl == nil || isProcessing
    }
    
    var outputURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("output.mp4")
    }
    
    var body: some View {
        ScrollView {
            VStack {
                VideoPlayer(player: player)
                    .frame(height: 300)
                HStack {
                    Button {
                        isPickerPresented.toggle()
                    } label: {
                        Label("Select Video", systemImage: "video")
                    }
                    .buttonStyle(BorderedButtonStyle(borderColor: .accent, isDisable: isProcessing))
                    Button {
                        processVideo()
                    } label: {
                        Label("Process Video", systemImage: "play.fill")
                    }
                    .buttonStyle(BorderedButtonStyle(borderColor: .green, isDisable: isProcessButtonDisabled))
                }
                .padding(.vertical, 10)
                if progress == 1 {
                    Button {
                        player = AVPlayer(url: outputURL)
                        player.play()
                    } label: {
                        Label("Play Video", systemImage: "play.fill")
                    }
                    .buttonStyle(BorderedButtonStyle(borderColor: .green, isDisable: isProcessButtonDisabled))
                }
                if isProcessing {
                    VStack {
                        HStack {
                            Text("Video is processing...(\(percentage))")
                            Spacer()
                            Button {
                                worker?.cancelProcessing()
                                isProcessing = false
                            } label: {
                                Text("Cancel")
                                    .foregroundColor(.red)
                            }
                        }
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Wire Detection")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPickerPresented) {
            VideoPicker(videoURL: $videoUrl)
        }
        .onChange(of: videoUrl) { _, url in
            if let url = url {
                player = AVPlayer(url: url)
            }
        }
        .alert(alertTitle, isPresented: $isShowingAlert) {
            Button(role: .cancel) {
                isShowingAlert = false
            } label: {
                Text("OK")
            }
        } message: {
            Text(errorMsg)
        }
    }
    
    func processVideo() {
        isProcessing = true
        Task {
            do {
                guard let url = videoUrl
                else {
                    throw WireDetectionError.invalidURL
                }
                self.worker = try await WireDetectionWorker(inputURL: url, outputURL: outputURL)
                try await worker?.processVideo(url: url) { progress, error  in
                    DispatchQueue.main.async {
                        self.progress = progress
                        if let error = error {
                            alertTitle = "Error"
                            isShowingAlert = true
                            errorMsg = error.localizedDescription
                            isProcessing = false
                        } else {
                            if progress == 1 {
                                alertTitle = "Success"
                                isShowingAlert = true
                                errorMsg = "Video processing completed successfully"
                                isProcessing = false
                            }
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isShowingAlert = true
                    errorMsg = error.localizedDescription
                }
            }
        }
    }
}




#Preview {
    NavigationStack {
        WireDetectionPage()
    }
}
