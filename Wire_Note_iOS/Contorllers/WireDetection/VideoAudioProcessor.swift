import AVFoundation

class VideoAudioProcessor {
    var progressHandler: progressHandler?

    func extractAndAddAudioToVideo(originVideoURL: URL, extractedAudioURL: URL, videoURL: URL, outputVideoURL: URL, handler: @escaping progressHandler) async throws {
        progressHandler = handler
        progressHandler?(0, nil)
        try await extractAudio(from: originVideoURL, to: extractedAudioURL)
        progressHandler?(0.5, nil) //*unfinished: need to be refine
        try await addAudioToVideo(videoURL: videoURL, audioURL: extractedAudioURL, outputURL: outputVideoURL)
        progressHandler?(1, nil)
    }

    func extractAudio(from inputURL: URL, to outputURL: URL) async throws {
        print("VideoAudioProcessor - extractAudio")
        let start = Date()

        removeExistingFile(at: outputURL)

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

//        let exportProgressChecker = Task {
//            while exportSession.status == .exporting {
//                self.progressHandler?(exportSession.progress, nil)
//                try await Task.sleep(nanoseconds: 100_000_000) // Sleep for 0.1 second
//            }
//        }
        await exportSession.export()
//        exportProgressChecker.cancel()

        if let error = exportSession.error {
            print("extractAudio - error: \(error)")
            progressHandler?(exportSession.progress, error)
            throw error
        }

        let end = Date()
        print("extractAudio time: \(end.timeIntervalSince1970 - start.timeIntervalSince1970)")
    }

    func addAudioToVideo(videoURL: URL, audioURL: URL, outputURL: URL) async throws {
        print("VideoAudioProcessor - combineVideoAndAudio - began. The Video will be created at outputURL: \(outputURL)")
        let start = Date()

        removeExistingFile(at: outputURL)

        let mixComposition = AVMutableComposition()

        let videoAsset = AVAsset(url: videoURL)
        let audioAsset = AVAsset(url: audioURL)

        let videoTrack = try await loadTrack(from: videoAsset, mediaType: .video)
        let audioTrack = try await loadTrack(from: audioAsset, mediaType: .audio)

        let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)

        let videoDuration = try await videoAsset.load(.duration)
        let audioDuration = try await audioAsset.load(.duration)
        let maxDuration = CMTimeMaximum(videoDuration, audioDuration)

        try insertTracks(videoTrack: videoTrack, audioTrack: audioTrack, videoDuration: videoDuration, audioDuration: audioDuration, videoCompositionTrack: videoCompositionTrack, audioCompositionTrack: audioCompositionTrack, maxDuration: maxDuration)

        let videoComposition = try await createVideoComposition(videoTrack: videoTrack, videoDuration: maxDuration, videoCompositionTrack: videoCompositionTrack)

        try await exportComposition(mixComposition: mixComposition, videoComposition: videoComposition, outputURL: outputURL, duration: maxDuration)

        print("VideoAudioProcessor - combineVideoAndAudio - finished")

        let end = Date()
        print("combineVideoAndAudio time: \(end.timeIntervalSince1970 - start.timeIntervalSince1970)")
    }

    private func loadTrack(from asset: AVAsset, mediaType: AVMediaType) async throws -> AVAssetTrack {
        let tracks = try await asset.loadTracks(withMediaType: mediaType)
        guard let track = tracks.first(where: { $0.mediaType == mediaType }) else {
            throw NSError(domain: "Video and audio combination", code: -1, userInfo: [NSLocalizedDescriptionKey: "No \(mediaType) track found"])
        }
        return track
    }

    private func insertTracks(videoTrack: AVAssetTrack, audioTrack: AVAssetTrack, videoDuration: CMTime, audioDuration: CMTime, videoCompositionTrack: AVMutableCompositionTrack?, audioCompositionTrack: AVMutableCompositionTrack?, maxDuration: CMTime) throws {
        let start = Date()

        var currentVideoTime = CMTime.zero
        var currentAudioTime = CMTime.zero
        while currentVideoTime < maxDuration {
            let remainingTime = CMTimeSubtract(maxDuration, currentVideoTime)
            let loopDuration = CMTimeMinimum(videoDuration, remainingTime)
            try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: loopDuration), of: videoTrack, at: currentVideoTime)
            currentVideoTime = CMTimeAdd(currentVideoTime, loopDuration)
        }
        while currentAudioTime < maxDuration {
            let remainingTime = CMTimeSubtract(maxDuration, currentAudioTime)
            let loopDuration = CMTimeMinimum(audioDuration, remainingTime)
            try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: .zero, duration: loopDuration), of: audioTrack, at: currentAudioTime)
            currentAudioTime = CMTimeAdd(currentAudioTime, loopDuration)
        }
        let end = Date()
        print("insertTracks time: \(end.timeIntervalSince1970 - start.timeIntervalSince1970)")
    }

    private func createVideoComposition(videoTrack: AVAssetTrack, videoDuration: CMTime, videoCompositionTrack: AVMutableCompositionTrack?) async throws -> AVMutableVideoComposition {
        let start = Date()

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
        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: videoDuration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack!)
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        let end = Date()
        print("insertTracks time: \(end.timeIntervalSince1970 - start.timeIntervalSince1970)")

        return videoComposition
    }

    private func exportComposition(mixComposition: AVMutableComposition, videoComposition: AVMutableVideoComposition, outputURL: URL, duration _: CMTime) async throws {
        let start = Date()

        guard let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "Video and audio combination", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create export session"])
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition

//        let exportProgressChecker = Task {
//            while exportSession.status == .exporting {
//                self.progressHandler?(exportSession.progress, nil)
//                try await Task.sleep(nanoseconds: 100_000_000) // Sleep for 0.1 second
//            }
//        }

        await exportSession.export()
//        exportProgressChecker.cancel()

        if let error = exportSession.error {
            print("combineVideoAndAudio - error: \(error)")
            throw error
        }

        let end = Date()
        print("insertTracks time: \(end.timeIntervalSince1970 - start.timeIntervalSince1970)")
    }
}
