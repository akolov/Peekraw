//
//  ImageFile.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-06-08.
//

import Foundation
import RawKit

struct ImageFile {

  let url: URL

  func thumbnail() throws -> PlatformImage? {
    let processor = try RawFile(path: url.path)
    return try processor.unpackThumbnail()
  }

  func image() throws -> PlatformImage? {
    let processor = try RawFile(path: url.path)
    return try processor.unpack()
  }

}

extension ImageFile: Identifiable {

  var id: URL {
    return url
  }

}
