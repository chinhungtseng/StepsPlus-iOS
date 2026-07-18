import AVFoundation
import Foundation

class BackgroundAudioManager {
    static let shared = BackgroundAudioManager()
    var player: AVAudioPlayer?

    func start() {
        // A perfectly silent, fraction-of-a-second MP3 file encoded as text
        let silentMP3Base64 = "SUQzBAAAAAAAI1RTU0UAAAAPAAADTGF2ZjYwLjE2LjEwMAAAAAAAAAAAAAAA//OEAAAAAAAAAAAAAAAAAAAAAAAASW5mbwAAAA8AAAAEAAABIwB1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1dXV1//OEAAAAAABUYAAAABxAAADwAAAAcQAAAPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=="
        
        guard let data = Data(base64Encoded: silentMP3Base64) else { return }
        
        do {
            // .mixWithOthers is CRUCIAL: It allows you to still listen to Spotify/Apple Music while walking!
            try AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
            
            player = try AVAudioPlayer(data: data)
            player?.numberOfLoops = -1 // -1 means loop infinitely
            player?.volume = 0.0       // Absolute silence
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
