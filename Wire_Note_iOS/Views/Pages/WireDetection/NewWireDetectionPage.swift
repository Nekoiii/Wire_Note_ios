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
                    Divider()
                    VStack {
                        Text("🎉 Video processed successfully 🎉")
                            .font(.title3)
                        HStack {
                            Button {
                                player = AVPlayer(url: outputURL)
                                player.play()
                            } label: {
                                Label("Play Video", systemImage: "play.fill")
                            }
                            .buttonStyle(BorderedButtonStyle(borderColor: .green, isDisable: isProcessButtonDisabled))
                            ShareLink(item: outputURL)
                            .buttonStyle(BorderedButtonStyle(borderColor: .blue, isDisable: isProcessButtonDisabled))
                        }
                    }
                    .padding(.top, 10)
                    // add scale animation
                    .transition(.scale)
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
                        if progress == 1 {
                            withAnimation {
                                self.progress = progress
                                self.isProcessing = false
                            }
                        } else {
                            self.progress = progress
                        }
                        if let error = error {
                            alertTitle = "Error"
                            isShowingAlert = true
                            errorMsg = error.localizedDescription
                            isProcessing = false
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
        NewWireDetectionPage()
    }
}
