//
//  Favorite.swift
//  MyFitPlate
//
//  Created by Omar Sabeha on 18/08/2025.
//

import Foundation
import SwiftData


@Model
class Favorite {
    var name: String
    var type: String
    
    
    
    init(name: String, type: String ) {
        self.name = name
        self.type = type
        
  
    }
    
//    
    static let sampleFavs = [
        Favorite(name: "push up", type: "strength"),
        Favorite(name: "pull up", type: "strength"),
        Favorite(name: "sit up", type: "strength"),

    ]
    
}
