//
//  URL.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-06-09.
//

import Foundation

extension URL {

  var isDirectory: Bool {
    (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
  }

}
