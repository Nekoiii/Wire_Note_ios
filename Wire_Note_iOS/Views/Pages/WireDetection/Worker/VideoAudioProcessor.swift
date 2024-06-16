import AVFoundation

class VideoAudioProcessor {
    static func extractAudio(from inputURL: URL, to outputURL: URL) async throws {
        print("VideoAudioProcessor - extractAudio")

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            do {
                try fileManager.removeItem(at: outputURL)
            } catch {
                print("VideoAudioProcessor - Failed to remove existing file: \(error)")
                throw error
            }
        }

        let asset = AVAsset(url: inputURL)
        guard let audioTrack = try await asset.loadTracks(withMediaType: .audio).first else {
            throw NSError(domain: "Audio extraction", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio track found in video"])
        }

        let composition = AVMutableComposition()
        guard let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "Audio extraction", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio track"])
        }

        let duration = try await asset.load(.duration)
        try compositionAudioTrack.insertTimeRange(CMTimeRangeMake(start: .zero, duration: duration), of: audioTrack, at: .zero)

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
            throw NSError(domain: "Audio extraction", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()
        if let error = exportSession.error {
            print("extractAudio - error: \(error)")
            throw error
        }
    }

    static func addAudioToVideo(videoURL: URL, audioURL: URL, outputURL: URL) async throws {
        print("VideoAudioProcessor - combineVideoAndAudio - began")
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }

        let mixComposition = AVMutableComposition()

        let videoAsset = AVAsset(url: videoURL)
        let audioAsset = AVAsset(url: audioURL)

        let videoTracks = try await videoAsset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first(where: { $0.mediaType == .video }) else {
            throw NSError(domain: "Video and audio combination", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }

        let audioTracks = try await audioAsset.loadTracks(withMediaType: .audio)
        guard let audioTrack = audioTracks.first(where: { $0.mediaType == .audio }) else {
            throw NSError(domain: "Video and audio combination", code: -1, userInfo: [NSLocalizedDescriptionKey: "No audio track found"])
        }

        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        let videoDuration = try await videoAsset.load(.duration)
        let audioDuration = try await audioAsset.load(.duration)
        let minDuration = CMTimeMinimum(videoDuration, audioDuration)
//        print("xxxxx   \(videoDuration)   xxx   \(audioDuration) ")

        let videoTimeRange = CMTimeRangeMake(start: .zero, duration: minDuration)
        let audioTimeRange = CMTimeRangeMake(start: .zero, duration: minDuration)

        try videoCompositionTrack?.insertTimeRange(videoTimeRange, of: videoTrack, at: .zero)
        try audioCompositionTrack?.insertTimeRange(audioTimeRange, of: audioTrack, at: .zero)

//
        let transform = try await videoTrack.load(.preferredTransform)
        let videoOrientation = transform.videoOrientation()

        let videoSize = try await videoTrack.load(.naturalSize)
        let videoComposition = AVMutableVideoComposition()
        if videoOrientation == .left || videoOrientation == .right {
            videoComposition.renderSize = CGSize(width: videoSize.height, height: videoSize.width)
        } else {
            videoComposition.renderSize = videoSize
        }

        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = videoTimeRange

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack!)
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        //
        guard let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "Video and audio combination", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition

        await exportSession.export()
        print("VideoAudioProcessor - combineVideoAndAudio - finished")
        if let error = exportSession.error {
            print("combineVideoAndAudio - error: \(error)")
            throw error
        }
    }
}
