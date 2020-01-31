//
//  MessageMapper.swift
//  Chatkit Quickstart
//
//  Created by Mike Pye on 31/01/2020.
//  Copyright © 2020 Pusher. All rights reserved.
//

import Foundation
import PusherChatkit

let MIME_TYPE_INTERNAL_ID = "com-pusher-gettingstarted/internal-id"
let MIME_TYPE_TEXT = "text/plain"

struct MessageMapper {
    
    func textToMessage(_ text: String) -> LocalMessage {
        return LocalMessage(text: text, internalId: getInternalId())
    }
    
    func messageToText(_ message: PCMultipartMessage) -> String? {
        return findPartOfType(message: message, type: MIME_TYPE_TEXT)
    }
    
    func messageToText(_ message: LocalMessage) -> String? {
        return message.text
    }
    
    func messageToInternalId(_ message: PCMultipartMessage) -> String? {
        return findPartOfType(message: message, type: MIME_TYPE_INTERNAL_ID)
    }
    
    func messageToInternalId(_ message: LocalMessage) -> String? {
        return message.internalId
    }
    
    private func findPartOfType(message: PCMultipartMessage, type: String) -> String? {
        for part in message.parts {
            if case .inline(let payload) = part.payload { 
                if payload.type == type {
                    return payload.content
                }
            }
        }

        return nil
    }
    
    private func getInternalId() -> String {
        return UUID().uuidString
    }
}
