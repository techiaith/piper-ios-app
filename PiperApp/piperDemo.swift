//
//  piperDemo.swift
//  piperapp
//
//  Created by Ihor Shevchuk on 22.11.2023.
//

import Foundation
import AVFoundation

class PiperDemo: NSObject {
    static let shared = PiperDemo()
    let synt = AVSpeechSynthesizer()
    
    override init() {
        super.init()
    }

    func doJob(textInput: String) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch let error {
            print(error.localizedDescription)
        }
        let voice = AVSpeechSynthesisVoice.speechVoices().first { voiceInArray in
            return voiceInArray.identifier == "cymru.techiaith.piperapp.pipertts.bu-tts-cy"
        }
        print(voice)
        if !textInput.isEmpty {
            let utterance = AVSpeechUtterance(string: textInput)
            utterance.voice = voice
            synt.speak(utterance)
        }
    }
}
