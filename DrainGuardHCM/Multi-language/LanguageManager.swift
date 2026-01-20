//
//  LanguageManager.swift
//  DrainGuardHCM
//
//  Created by Ho Quang Huy on 20/1/26.
//
import SwiftUI

final class LanguageManager: ObservableObject {
  @Published var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
}
