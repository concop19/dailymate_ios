//
//  GhibliTexture.swift
//  dailymate
//
//  Created by ManhLe on 11/16/26.
//

import SwiftUI
import UIKit

/// Các texture vẽ tay trong `Assets.xcassets` — tên imageset phải trùng `rawValue` (vd: `wood_light.imageset`).
enum GhibliTexture: String {
  case wood = "wood_light"
  case paper = "paper_cream"
  case notebook = "notebook_lines"
  case sky = "sky_watercolor"

  /// `UIImage(named:)` tìm được cả file .png rời trong main bundle và tự cache.
  var image: Image {
    Image(uiImage: UIImage(named: rawValue) ?? UIImage())
  }
}
