//
//  ImportPFP.swift
//  MyFitPlate
//
//  Created by Omar Sabeha on 21/08/2025.
//

import SwiftUI
import PhotosUI
import SwiftData

@Model
class ProfilePicture {
    @Attribute(.unique) var id: String
    var image: Data?

    init(id: String = "", image: Data? = nil) {
        self.id = id
        self.image = image
    }
}
