//
//  piperttsAudioUnit.swift
//  pipertts
//
//  Created by Ihor Shevchuk on 27.12.2023.
//

// NOTE:- An Audio Unit Speech Extension (ausp) is rendered offline, so it is safe to use
// Swift in this case. It is not recommended to use Swift in other AU types.

import AVFoundation

import piper_objc
import PiperappUtils

public class PiperttsAudioUnit: AVSpeechSynthesisProviderAudioUnit {
    private var outputBus: AUAudioUnitBus
    private var _outputBusses: AUAudioUnitBusArray!
    
    private var request: AVSpeechSynthesisProviderRequest?

    private var format: AVAudioFormat

    var piper: Piper?

    @objc override init(componentDescription: AudioComponentDescription, options: AudioComponentInstantiationOptions) throws {

        self.format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000.0, channels: 1, interleaved: true)!

        outputBus = try AUAudioUnitBus(format: self.format)
        try super.init(componentDescription: componentDescription, options: options)
        _outputBusses = AUAudioUnitBusArray(audioUnit: self, busType: AUAudioUnitBusType.output, busses: [outputBus])
    }
    
    public override var outputBusses: AUAudioUnitBusArray {
        return _outputBusses
    }
    
    enum MyError: Error {
        case runtimeError(String)
    }
    
    public override func allocateRenderResources() throws {
        try super.allocateRenderResources()
        print("allocateRenderResources")
        if piper == nil {
            let model = Bundle.main.path(forResource: "gwryw_gogledd_x_low_fp16", ofType: "onnx")!
            let config = Bundle.main.path(forResource: "gwryw_gogledd_x_low.onnx", ofType: "json")!
            piper = Piper(modelPath: model, andConfigPath: config)
        }
    }

    public override func deallocateRenderResources() {
        super.deallocateRenderResources()
        piper = nil
    }

	// MARK: - Rendering
	/*
	 NOTE:- It is only safe to use Swift for audio rendering in this case, as Audio Unit Speech Extensions process offline.
	 (Swift is not usually recommended for processing on the realtime audio thread)
	 */
    public override var internalRenderBlock: AUInternalRenderBlock {
        return { [weak self] actionFlags, _, frameCount, _, outputAudioBufferList, _, _ in

            guard let self = self,
            let piper = self.piper else {
                actionFlags.pointee = .unitRenderAction_PostRenderError
                Log.error("Utterance Client is nil while request for rendering came.")
                return kAudioComponentErr_InstanceInvalidated
            }

            if piper.completed() && !piper.hasSamplesLeft() {
                print("Completed rendering")
                actionFlags.pointee = .offlineUnitRenderAction_Complete
                self.cleanUp()
                return noErr
            }

            if !piper.readyToRead() {
                actionFlags.pointee = .offlineUnitRenderAction_Preflight
                print("No bytes yet.")
                return noErr
            }

            let levelsData = piper.popSamples(withMaxLength: UInt(frameCount))

            guard let levelsData else {
                actionFlags.pointee = .offlineUnitRenderAction_Preflight
                print("Rendering in progress. No bytes.")
                return noErr
            }

            outputAudioBufferList.pointee.mNumberBuffers = 1
            var unsafeBuffer = UnsafeMutableAudioBufferListPointer(outputAudioBufferList)[0]
            let frames = unsafeBuffer.mData!.assumingMemoryBound(to: Float.self)
            unsafeBuffer.mDataByteSize = UInt32(levelsData.count)
            unsafeBuffer.mNumberChannels = 1

            for frame in 0..<levelsData.count {
                frames[Int(frame)] = levelsData[Int(frame)].int16Value.toFloat()
            }

            actionFlags.pointee = .offlineUnitRenderAction_Render

            print("Rendering \(levelsData.count) bytes")

            return noErr

        }
    }

    public override func synthesizeSpeechRequest(_ speechRequest: AVSpeechSynthesisProviderRequest) {
        print("synthesizeSpeechRequest \(speechRequest.ssmlRepresentation)")
        self.request = speechRequest
        let text = AVSpeechUtterance(ssmlRepresentation: speechRequest.ssmlRepresentation)?.speechString
        print(text!)
        piper?.synthesize(text ?? "")
        piper?.completed()
    }
    
    public override func cancelSpeechRequest() {
        print("\(#file) cancelSpeechRequest")
        cleanUp()
        piper?.cancel()
    }

    func cleanUp() {
        request = nil
    }

    public override var speechVoices: [AVSpeechSynthesisProviderVoice] {
        get {
            return [
                AVSpeechSynthesisProviderVoice(name: "gwryw_gogleddol", identifier: "bu-tts-cy", primaryLanguages: ["cy-GB"], supportedLanguages: ["cy-GB", "en-GB"])
            ]
        }
        set { }
    }

    public override var canProcessInPlace: Bool {
        return true
    }

}
