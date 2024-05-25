//
//  HomePageView.swift
//  Wire_Note_iOS
//
//  Created by 猫草 on 2024/05/26.
//

import SwiftUI

struct HomePageView: View {
    
    var body:some View{
        NavigationView{
            VStack{
                Text("♪ ♩ ♫ ♬ ♭ ♮ ♯ 𝄪 𝄫 𝄞 🎶")
                    .font(.system(size: 26))
                    .padding()
                
                NavigationLink(destination: CameraView()) {
                    Text("Open Camera")
                        .foregroundColor(.black)
                        .background(.white)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.black, lineWidth: 2)
                        )
                }
            }
        }
    }
    
    
}
#Preview{
    HomePageView()
}
