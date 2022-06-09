//
//  ImageFile.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-06-08.
//

import Foundation
import RawKit
import UniformTypeIdentifiers

struct ImageFile: Identifiable {

  let id: URL
  let data: Data

  var mimeType: String? {
    guard let url = url else { return nil }
    let type = UTType(filenameExtension: url.pathExtension)
    return type?.identifier
  }

  var url: URL? {
    var isStale = false
    let _url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &isStale)
    guard !isStale else { return nil }
    return _url
  }

  init(url: URL) throws {
    self.id = url
    self.data = try url.bookmarkData(options: .minimalBookmark)
  }

  func thumbnail() throws -> PlatformImage? {
    guard let url = url else { return nil }
    let processor = try RawFile(path: url.path(percentEncoded: false))
    return try processor.unpackThumbnail()
  }

  func image() throws -> PlatformImage? {
    guard let url = url else { return nil }
    let processor = try RawFile(path: url.path(percentEncoded: false))
    return try processor.unpack()
  }

}
