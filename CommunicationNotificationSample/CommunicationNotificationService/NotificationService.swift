//
//  NotificationService.swift
//  CommunicationNotificationService
//
//  Created by QuyNM on 4/28/22.
//

import UserNotifications
import Intents
import UIKit
import SDWebImage

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        // Lấy thông tin nội dung của thông báo
        let body = bestAttemptContent?.body ?? ""
        
        let senderName = bestAttemptContent?.userInfo["sender_name"] as? String ?? ""
        let avatarURL = bestAttemptContent?.userInfo["avatar"] as? String ?? ""
        
        if #available(iOS 15.0, *) {
            var content = UNMutableNotificationContent()
            content.body = body
            
            var personNameComponents = PersonNameComponents()
            
            // Thay đổi tiêu đề thông báo thành tên của người gửi
            personNameComponents.nickname = senderName
            
            downloadImage(url: URL(string: avatarURL), onComplete: { image in
                // Avatar sẽ hiện lên thay vì icon của app
                let avatar = INImage(imageData: image!.pngData()!)
                
                let senderPerson = INPerson(
                    personHandle: INPersonHandle(value: "sampleValue", type: .unknown),
                    nameComponents: personNameComponents,
                    displayName: personNameComponents.nickname,
                    image: avatar,
                    contactIdentifier: nil,
                    customIdentifier: nil,
                    isMe: false,
                    suggestionType: .none
                )
                
                let intent = INSendMessageIntent(
                    recipients: nil,
                    outgoingMessageType: .outgoingMessageText,
                    content: nil,
                    speakableGroupName: INSpeakableString(spokenPhrase: personNameComponents.nickname ?? ""),
                    conversationIdentifier: "sampleConversationIdentifier",
                    serviceName: nil,
                    sender: senderPerson,
                    attachments: nil
                )
                
                let interaction = INInteraction(intent: intent, response: nil)
                interaction.direction = .incoming
                
                interaction.donate(completion: { error in
                    do {
                        content = try content.updating(from: intent) as! UNMutableNotificationContent
                        contentHandler(content)
                    } catch {
                        print("Error update content")
                    }
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request)
                })
            })
        } else {
            if let bestAttemptContent = bestAttemptContent {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private func downloadImage(url: URL?, onComplete: ((_ image: UIImage?) -> Void)? = nil) {
        SDWebImageDownloader.shared.downloadImage(with: url) { image, data, error, _ in
            onComplete?(image)
        }
    }
}
