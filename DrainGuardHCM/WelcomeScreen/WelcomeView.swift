//
//  WelcomeScreen.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var showWelcomeView: Bool
    var body: some View {
        NavigationStack {
            ZStack{
                Color("main").ignoresSafeArea()
                VStack {
                    Spacer()
                    Text("Drain Guard")
                        //.font(.headline)
                        .font(.custom("BubblerOne-Regular", size: 80))
                        .padding()
                    Spacer()
                    Image("mascot")
                        .resizable()
                        .frame(width: 250, height: 250)
                        .padding()
                    
                    Spacer()
                    
                }
            }.onTapGesture {
                showWelcomeView = false
            }
        }
    }
}


#Preview {
    WelcomeView(showWelcomeView: .constant(true))
}
