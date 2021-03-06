//
//  ViewController.swift
//  Notify Me
//
//  Created by Vishal Dubey on 13/01/17.
//  Copyright © 2017 Vishal Dubey. All rights reserved.
//

import Cocoa
import CocoaMQTT
import SwiftyJSON

class ViewController: NSViewController, CocoaMQTTDelegate, NSUserNotificationCenterDelegate {
    
    var mqttClient: CocoaMQTT?
    var center: NSUserNotificationCenter?
    var notifText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        center = NSUserNotificationCenter.default
        center?.delegate = self
        // Do any additional setup after loading the view.
        setupMqtt()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setupMqtt() {
        mqttClient = CocoaMQTT(clientID: "desktop_client", host: "test.org", port: 1883)
        mqttClient?.username = "vishal"
        mqttClient?.password = "vishal123"
        mqttClient?.keepAlive = 60
        mqttClient?.delegate = self
        mqttClient?.connect()
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        if ack == .accept {
            print("mqtt connected")
            mqttClient?.subscribe("hihi", qos: CocoaMQTTQOS.qos1)
            mqttClient?.subscribe("notification", qos:CocoaMQTTQOS.qos1)
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        if (message.topic == "notification") {
            for noti in (center?.deliveredNotifications)! {
                if noti.identifier == message.string! {
                    center?.removeDeliveredNotification(noti)
                    break
                }
            }
        } else {
        var json = JSON.init(parseJSON: message.string!)
        var senderName = json["name"].stringValue
        var senderMessage = json["message"].stringValue
        var id = json["id"].stringValue
        var appName = json["app_name"].stringValue
        var icon = json["icon"].stringValue
        
        showNotification(title: appName == "com.whatsapp" ? "WhatsApp":"Messenger", subTitle: senderName, message: senderMessage, id: id, appName: appName, icon: icon)
            
        }
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
    
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        setupMqtt()
    }
    
    func showNotification(title: String, subTitle: String, message: String, id: String, appName: String, icon:String) {
        
        var notification = NSUserNotification()
        
        notification.title = title
        notification.subtitle = subTitle
        notification.identifier = id
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        notification.userInfo = ["app_name": appName]
        notification.hasReplyButton = true
        notification.otherButtonTitle = "Dismiss"
        notification.setValue(NSImage(named: appName == "com.whatsapp" ? "WhatsApp":"Messenger"), forKey: "_identityImage")
        center?.deliver(notification)
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        print(notification.subtitle)
        print(notification.response)
        print(notification.identifier)
        if notification.activationType == NSUserNotification.ActivationType.replied {
            var dict = notification.userInfo as? [String:String]
            var response = [String:String]()
            response["name"] = notification.subtitle
            response["message"] = notification.response?.string
            response["app_name"] = dict?["app_name"]
            response["id"] = notification.identifier
            
            var replyObject = JSON(response)
            
            mqttClient?.publish("test1", withString: replyObject.rawString()!, qos: CocoaMQTTQOS.qos1, retained: false, dup: false)
        }
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
        print("delivered")
    }

}

