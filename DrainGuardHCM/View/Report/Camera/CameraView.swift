//
//  CameraView.swift
//  DrainGuardHCM
//
//  Created by Thao Trinh Phuong on 14/1/26.
//

import SwiftUI

struct CameraView: View {
    @State private var capturedImage: UIImage? = nil
    @StateObject private var cameraModel = CameraModel()
    
    var body: some View {
        ZStack {
            Color("main").ignoresSafeArea()
            VStack{
                Text("Capture the sewer you want to report").font(.custom("BubblerOne-Regular", size: 30))
                Spacer()
                Camera(cameraModel: cameraModel)
                    .frame(width: 200, height: 200) // or frame as you like
                Spacer()
                
                Button("Capture") {
                    cameraModel.capturePhoto()
                }
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(Capsule())
                .padding()
                
                if let image = capturedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 150, height: 150)
                                }
            
                                }
       
        }
    }
}

//#Preview {
//    CameraView()
//}
