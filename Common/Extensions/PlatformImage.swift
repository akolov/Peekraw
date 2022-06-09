//
//  PlatformImage.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-06-08.
//

#if canImport(Cocoa)
import Cocoa
public typealias PlatformImage = NSImage
#elseif canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#endif
