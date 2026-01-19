//
//  DrainNearby.swift
//  DrainGuardHCM
//
//  Created by Anh Phung on 1/19/26.
//

import CoreLocation

enum DrainNearby: String, CaseIterable, Identifiable {
  case yes = "Yes"
  case no = "No"
  case unsure = "Not sure"
  var id: String { rawValue }
}
