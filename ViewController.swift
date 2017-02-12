//
//  ViewController.swift
//  Siri
//
//  Created by Sahand Edrisian on 7/14/16.
//  Copyright © 2016 Sahand Edrisian. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
	
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    private var backgroundColor: UIColor = .blue
    private var colors: Dictionary<String, UIColor> = ["Зелёный": .green,
                                                       "Красный": .red,
                                                       "Серый": .gray,
                                                       "Синий": .blue,
                                                       "Чёрный": .black,
                                                       "Белый": .white]
    
    private let speechRecognizer = SFSpeechRecognizer()
    
    private var count = 0
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
	override func viewDidLoad() {
        super.viewDidLoad()
        
        label.text = ""
        microphoneButton.clipsToBounds = true
        microphoneButton.layer.cornerRadius = 0
        
        //self.performSegue(withIdentifier: "openView", sender: nil)
        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(buttonPressed(gesture:)))
        microphoneButton.addGestureRecognizer(longTap)
        
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.microphoneButton.isEnabled = isButtonEnabled
            }
        }
	}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        count = 0
    }
    
    func buttonPressed(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            startRecording()
            microphoneButton.setTitle("Stop", for: .normal)
            microphoneButton.backgroundColor = .gray
            textView.text = "Говорите"
        } else if gesture.state == .ended {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.setTitle("Start", for: .normal)
            microphoneButton.isEnabled = false
            microphoneButton.backgroundColor = .red
        }
    }
    
    @IBAction func microphoneTapped(_ sender: AnyObject) {
        print(#function)
        /*if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            microphoneButton.isEnabled = false
            microphoneButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            microphoneButton.setTitle("Stop Recording", for: .normal)
        }*/
	}

    func startRecording() {
        
        if recognitionTask != nil {  //1
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()  //2
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()  //3
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }  //4
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        } //5
        
        recognitionRequest.shouldReportPartialResults = true  //6
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in  //7
            
            var isFinal = false  //8
            
            if result != nil {
                //print(result?.bestTranscription.formattedString)
                guard let r = result else {
                    fatalError("fdjid")
                }
                let text = r.bestTranscription.formattedString//.lowercased()
                self.label.text = text
                print(text)
                print(text.characters.count)
                if let c = self.colors[text] {
                    self.backgroundColor = c
                    if self.count == 0 {
                        self.count += 1
                        let vc =  SecondViewController()
                        vc.backgroundColor = self.backgroundColor
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                    //self.performSegue(withIdentifier: "openView", sender: nil)
                } else {
                    self.textView.text = "Неправильно назван цвет"
                }
                
                //if r.bestTranscription.formattedString == "зеленый" { self.performSegue(withIdentifier: "openView", sender: nil) }
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {  //10
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.microphoneButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)  //11
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()  //12
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination.presentingViewController as! SecondViewController
        vc.backgroundColor = backgroundColor
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            microphoneButton.isEnabled = true
        } else {
            microphoneButton.isEnabled = false
        }
    }
}

