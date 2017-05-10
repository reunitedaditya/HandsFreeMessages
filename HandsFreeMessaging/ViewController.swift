//
//  ViewController.swift
//  HandsFreeMessaging
//
//  Created by Sonu  on 10/05/17.
//  Copyright © 2017 Aditya Yadav. All rights reserved.
//

import UIKit
import Speech
import MessageUI


class ViewController: UIViewController  , SFSpeechRecognizerDelegate , MFMessageComposeViewControllerDelegate{
    
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var speakButton: UIButton!

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var sendMessage: UIButton!
    
    var message : String?
    
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.text = "Say something , I'm listening!"
        speakButton.backgroundColor = UIColor(red:0.95, green:0.84, blue:0.33, alpha:1.0)

        speakButton.isEnabled = false
        
        speechRecognizer?.delegate = self
        
        sendMessage.isHidden = true
        
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
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
                self.speakButton.isEnabled = isButtonEnabled
            }
        }
   
    }

    @IBAction func performSpeechToText(_ sender: Any) {
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speakButton.isEnabled = false
            speakButton.tintColor = UIColor.black
            speakButton.titleLabel?.textColor = UIColor.black
            speakButton.backgroundColor = UIColor(red:0.95, green:0.84, blue:0.33, alpha:1.0)
            self.statusLabel.text = "Start Recording"
            self.sendMessage.isHidden = true
            
            
        } else {
            startRecording()
            speakButton.tintColor = UIColor.red
            speakButton.titleLabel?.textColor = UIColor.red
            speakButton.backgroundColor = UIColor(red:0.84, green:0.16, blue:0.16, alpha:1.0)
            self.statusLabel.text = "Stop Recording"
            self.sendMessage.isHidden = false
            
        }
        
        
    }
    
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.textView.text = result?.bestTranscription.formattedString
                self.message = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.speakButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        textView.text = "Say something, I'm listening!"
        
    }

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            speakButton.isEnabled = true
        } else {
            speakButton.isEnabled = false
        }
    }
    
    @IBAction func sendMessageAction(_ sender: Any) {
        
        let messageVC = MFMessageComposeViewController()
        
        if let realMessage = message {
            
            messageVC.body = realMessage
            
        }
        
        
        messageVC.recipients = ["+919677427453"]
        messageVC.messageComposeDelegate = self;
        
        self.present(messageVC, animated: false, completion: nil)
        
    }
  
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResult.cancelled.rawValue:
            print("Message was cancelled")
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.failed.rawValue:
            print("Message failed")
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.sent.rawValue:
            print("Message was sent")
         
            DispatchQueue.main.async {
                
                let alert = UIAlertController(title: "Message Sent", message: "Your Message Has Been Sent!", preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
                
                alert.addAction(alertAction)
                
                self.present(alert, animated: true, completion: nil)
            }
          
            
            self.dismiss(animated: true, completion: nil)
        default:
            break;
        }
    }
    
    @IBAction func hideKeyboard(_ sender: Any) {
        
        self.textView.resignFirstResponder()
    }
    
  

}

