import Foundation
import AVFoundation

@MainActor
final class AudioMetadataService {
    static let shared = AudioMetadataService()

    private init() {}

    func getDuration(for url: URL) async throws -> TimeInterval {
        let asset = AVURLAsset(url: url)
        try await asset.load(.duration)
        return CMTimeGetSeconds(asset.duration)
    }

    func getMetadata(for url: URL) async throws -> AudioMetadata {
        let asset = AVURLAsset(url: url)
        try await asset.load(.duration, .tracks, .commonMetadata)

        let duration = CMTimeGetSeconds(asset.duration)

        var title: String? = nil
        var artist: String? = nil

        for metadata in asset.commonMetadata {
            switch metadata.commonKey {
            case .commonKeyTitle:
                title = metadata.stringValue
            case .commonKeyArtist:
                artist = metadata.stringValue
            default:
                break
            }
        }

        return AudioMetadata(
            duration: duration,
            title: title,
            artist: artist
        )
    }
}

struct AudioMetadata {
    let duration: TimeInterval
    let title: String?
    let artist: String?
}
