//
//  WelcomeScreen.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack {
            Text("Drain Guard")
                .font(.headline)
                .font(.custom("BubblerOne-Regular", size: 80))
                .padding()
            
            Image("mascot")
                .resizable()
                .frame(width: 200, height: 200)
                .padding()
            
            
                
        }
    }
}


#Preview {
    WelcomeView()
}
