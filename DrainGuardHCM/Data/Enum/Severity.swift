//
//  Severity.swift
//  DrainGuardHCM
//
//  Created by Anh Phung on 1/19/26.
//

import Foundation
import CoreLocation

enum Severity: String, CaseIterable, Identifiable {
  case low = "Low"
  case medium = "Medium"
  case high = "High"
  var id: String { rawValue }
}
