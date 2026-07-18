import AVFoundation
import Foundation

class BackgroundAudioManager {
    static let shared = BackgroundAudioManager()
    var player: AVAudioPlayer?

    func start() {
        // A perfectly valid, uncompressed 16-bit silent .WAV file
        let silentWAVBase64 = "UklGRigAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQQAAAAAAA=="
        
        guard let data = Data(base64Encoded: silentWAVBase64) else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // THE FIX: Explicitly tell iOS to use the WAV parser
            player = try AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
            player?.numberOfLoops = -1
            player?.volume = 0.01
            player?.play()
        } catch {
            print("Failed to start background audio: \(error)")
        }
    }
    
    func stop() {
        player?.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
