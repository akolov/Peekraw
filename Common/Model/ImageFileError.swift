//
//  ImageFileError.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-06-08.
//

import Foundation

enum ImageFileError: Error {
  case unableToGenerateImage(url: URL)
  case unableToGenerateThumbnail(url: URL)
}
