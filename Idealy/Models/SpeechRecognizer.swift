//
//  SpeechRecognizer.swift
//  Idealy
//
//  Created by Claude Code on 15/8/2025.
//

import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognizer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Initialization
    init() {
        requestAuthorization()
    }
    
    // MARK: - Authorization
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                self?.isAuthorized = status == .authorized
                print("Speech authorization status: \(status.rawValue)")
            }
        }
    }
    
    // MARK: - Recording Control
    func startRecording() {
        guard isAuthorized else {
            print("Speech recognition not authorized")
            return
        }
        
        guard !audioEngine.isRunning else {
            print("Audio engine already running")
            return
        }
        
        print("🎤 Starting speech recognition...")
        
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Failed to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Add a small buffer to catch the beginning of speech
        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = true
        }
        
        // Configure audio input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("❌ Audio engine start failed: \(error)")
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                    print("🗣️ Transcript: \(result.bestTranscription.formattedString)")
                }
                
                if let error = error {
                    print("❌ Recognition error: \(error)")
                    self?.stopRecording()
                }
            }
        }
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func stopRecording() {
        print("🛑 Stopping speech recognition...")
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        // Reset audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session deactivation failed: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    func clearTranscript() {
        transcript = ""
    }
    
    func appendToText(_ existingText: inout String) {
        if !transcript.isEmpty {
            if existingText.isEmpty {
                existingText = transcript
            } else {
                existingText += " " + transcript
            }
            clearTranscript()
        }
    }
    
    // Store the original text when recording starts
    private var originalText: String = ""
    
    // Real-time text binding for live transcription
    func updateTextRealTime(_ existingText: inout String) {
        if !transcript.isEmpty {
            // Simply append the current transcript to the original text
            // The transcript already contains the full phrase being spoken
            if originalText.isEmpty {
                existingText = transcript
            } else {
                existingText = originalText + " " + transcript
            }
        }
    }
    
    // Call this when starting recording to preserve existing text
    func setOriginalText(_ text: String) {
        originalText = text
    }
    
    // Call this when stopping recording to finalize the text
    func finalizeText() {
        originalText = ""
        clearTranscript()
    }
}

// MARK: - Authorization Status Extension
extension SFSpeechRecognizerAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}