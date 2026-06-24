import Foundation
import AVFoundation
import Combine

enum AudioFileStatus: String, Codable {
    case waiting = "Waiting"
    case converting = "Converting"
    case done = "Done"
    case error = "Error"
}

struct AudioFile: Identifiable, Codable {
    let id = UUID()
    let url: URL
    let name: String
    let size: Int64
    var duration: TimeInterval = 0
    var status: AudioFileStatus = .waiting
    var progress: Double = 0.0
    var errorMessage: String?

    var sizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowsNonnumericFormatting = false
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var outputURL: URL {
        url.deletingPathExtension().appendingPathExtension("mp3")
    }
}
