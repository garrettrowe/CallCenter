//
//  utils.swift
//  CustomerConcierge
//
//  Created by Garrett Rowe on 6/25/18.
//  Copyright © 2018 Twilio, Inc. All rights reserved.
//

import Foundation

let baseURLString = "https://conciergevoiceserver.mybluemix.net"
let accessTokenEndpoint = "/accessToken"
var identity = ""
var agent = ""
var defaults = UserDefaults.standard
var yourPhone = ""
var agentPhone = ""
var industry = ""
let uuid = UUID().uuidString

extension String
{
    func trim() -> String
    {
        return self.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
}

