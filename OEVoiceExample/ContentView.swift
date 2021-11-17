//
//  ContentView.swift
//  OEVoiceExample
//
//  Created by Ryan Lintott on 2020-07-29.
//

import SwiftUI
import AVFoundation
import OEVoice

struct ContentView: View {
    @State private var ipaString = ""
    @State private var filter = ""
    @State private var isEditingFilter = false
    @State private var voiceIdentifier = ""
    @State private var showingAllVoices = false
    @State private var isShowingError = false
    @State private var error = ""
    
    let synthesizer = AVSpeechSynthesizerIPA.oeVoiceSupported
    let allVoices = AVSpeechSynthesisVoice.speechVoices()
    var ipaVoices: [AVSpeechSynthesisVoice] {
        OEVoice.allCases.compactMap { $0.voice }
    }
    var voices: [AVSpeechSynthesisVoice] {
        showingAllVoices ? allVoices : ipaVoices
    }
    var voice: AVSpeechSynthesisVoice? {
        voices.first(where: { $0.identifier == voiceIdentifier })
    }
    
    var filteredIPAStrings: Set<String> {
        if filter.isEmpty {
            return TestWords.all
        } else {
            return TestWords.all.filter({ $0.contains(filter) })
        }
    }
    
    var adjustedIPAString: String? {
        guard let voice = voice else {
            return nil
        }
        return OEVoice(from: voice)?.adjustIPAString(ipaString)
    }
    
    var newAdjustment: String? {
        adjustedIPAString
        // Add testing adjustments here
    }

    func shortIdentifier(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: OEVoice.idPrefix, with: "")
    }
    
    var body: some View {
        Form {
            Section(header: Text("Voice")) {
                Toggle("All Voices", isOn: $showingAllVoices)
                
                Picker(shortIdentifier(voiceIdentifier), selection: $voiceIdentifier) {
                    ForEach(voices, id: \.identifier) { voice in
                        Text(shortIdentifier(voice.identifier))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            TextField("Filter", text: $filter) { isEditing in
                isEditingFilter = isEditing
            }
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
            if isEditingFilter {
                IPACharacters { character in
                    filter += String(character)
                }
            }
            
            Picker("IPA Word", selection: $ipaString) {
                ForEach(filteredIPAStrings.sorted(), id: \.self) { ipaString in
                    Text(ipaString)
                }
            }
            .pickerStyle(WheelPickerStyle())
            
            Section(header: Text("IPA Word")) {
                if voice != nil {
                    Group {
                        HStack {
                            Text(ipaString)
                            
                            Button("Play Raw") {
                                speak(ipaString, applyAdjustements: false)
                            }
                        }
                        
                        HStack {
                            Text("\(adjustedIPAString ?? "N/A")")
                            
                            Button("Play Adjusted") {
                                speak(adjustedIPAString, applyAdjustements: false)
                            }
                            .disabled(adjustedIPAString == nil)
                        }
                        
                        HStack {
                            Text("\(newAdjustment ?? "N/A")")
                            
                            Button("Play New Adjusted") {
                                speak(newAdjustment, applyAdjustements: false)
                            }
                            .disabled(newAdjustment == nil)
                        }
                    }
                    .padding()
                } else {
                    Text("No voices available")
                }
            }
            
            Button("Test Voice") {
                synthesizer.simplifiedTestSpeakOE()
            }
        }
        .onAppear {
            voiceIdentifier = OEVoice.default.voice?.identifier ?? ""
            AVAudioSession.sharedInstance().setSpeechSession()
        }
        .alert(isPresented: $isShowingError) {
            Alert(
                title: Text("Error"),
                message: Text(error),
                dismissButton: .default(Text("OK")) {
                    error = ""
                }
            )
        }
    }
    
    func speak(_ string: String?, applyAdjustements: Bool) {
        guard let string = string else {
            print("Error: String is nil")
            return
        }
        guard !string.isEmpty else {
            print("Error: String is empty")
            return
        }
        guard let voice = voice else {
            print("Error: Voice is nil. Default voice used.")
            return
        }
        
        if let oeVoice = OEVoice(from: voice) {
            do {
                try OEVoice.speak(string, oeVoice: oeVoice, applyAdjustments: applyAdjustements, synthesizer: synthesizer, force: true)
            } catch let error {
                self.error = error.localizedDescription
                print(error.localizedDescription)
            }
        } else {
            synthesizer.speakIPA(string, voice: voice)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
