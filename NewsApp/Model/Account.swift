//
//  Account.swift
//  NewsApp
//
//  Created by Nurmat Junusov on 6/12/21.
//  Copyright © 2025 NewsApp Media. All rights reserved.
//

import Foundation

protocol PrimaryAccount {
    var id: Int { get }
    var email: String { get }
    var token: String { get }
}

struct Account: PrimaryAccount, Identifiable {
    var id: Int
    var email: String
    var token: String
    /*let id: Int
    let email: String
    let token: String*/
    var subscribed: Bool
    var name: String
    var firstName: String?
    var lastName: String?
    //var avatarUrl: URL?
    var avatar: ImageItem?
    var balance: String
    func getFullName() -> String? {
        if let firstName = self.firstName {
            if let lastName = self.lastName {
                return firstName + " " + lastName
            }
            return firstName
        }
        return self.lastName
    }
}
extension Account: Codable {
    enum CodingKeys: String, CodingKey {
        case id, email, token, subscribed, name="login", firstName="firstname", lastName="lastname", avatar, balance
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        email = try values.decode(String.self, forKey: .email)
        token = try values.decode(String.self, forKey: .token)
        do {
            subscribed = try values.decode(Bool.self, forKey: .subscribed)
        } catch DecodingError.keyNotFound {
            subscribed = false
        }
        name = try values.decode(String.self, forKey: .name)
        firstName = try values.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try values.decodeIfPresent(String.self, forKey: .lastName)
        //avatarUrl = try values.decodeIfPresent(URL.self, forKey: .avatarUrl)
        avatar = try values.decodeIfPresent(ImageItem.self, forKey: .avatar)
        balance = try values.decode(String.self, forKey: .balance)
    }
}
struct AccountUpdateRequest: PrimaryAccount {
    var id: Int
    var email: String
    var token: String
    
    let newUsername: String
    let newFirstname: String
    let newLastname: String
}
extension AccountUpdateRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case id="account_id", email="account_email", token="account_token", newUsername="new_username", newFirstname="new_firstname", newLastname="new_lastname"
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(token, forKey: .token)
        try container.encode(newUsername, forKey: .newUsername)
        try container.encode(newFirstname, forKey: .newFirstname)
        try container.encode(newLastname, forKey: .newLastname)
    }
}

struct ContactItem {
    let email: String?
    let phone: String?
    let address: String?
    let label: String?
}
extension ContactItem: Codable {
    enum CodingKeys: String, CodingKey {
        case email, phone, address, label
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        email = try values.decodeIfPresent(String.self, forKey: .email)
        phone = try values.decodeIfPresent(String.self, forKey: .phone)
        address = try values.decodeIfPresent(String.self, forKey: .address)
        label = try values.decodeIfPresent(String.self, forKey: .label)
    }
    func getContactInfo() -> String {
        if let email = self.email {
            return email
        } else if let phone = self.phone {
            return phone
        }
        return self.address ?? ""
    }
}
extension ContactItem: Hashable {
    static func == (lhs: ContactItem, rhs: ContactItem) -> Bool {
        return lhs.email == rhs.email &&
            lhs.phone == rhs.phone &&
            lhs.address == rhs.address &&
            lhs.label == rhs.label
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(email)
        hasher.combine(phone)
        hasher.combine(address)
        hasher.combine(label)
    }
}
