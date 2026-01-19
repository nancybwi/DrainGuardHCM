//
//  TrafficImpact.swift
//  DrainGuardHCM
//
//  Created by Anh Phung on 1/19/26.
//

import CoreLocation

enum TrafficImpact: String, CaseIterable, Identifiable {
  case normal = "Normal"
  case slowing = "Slowing"
  case blocked = "Blocked"
  var id: String { rawValue }
}
