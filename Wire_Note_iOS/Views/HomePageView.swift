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
                HStack{
                    ForEach(musicalNotes, id: \.symbol) { note in
                        Text(note.symbol)
                            .font(.largeTitle)
                        
                    }
                }.padding(.vertical ,30)
                Group{
                    NavigationLink(destination: TextToMusicView()) {
                        Text("Text To Music")
                    }
                    NavigationLink(destination: ImageToMusicView()) {
                        Text("Image To Music")
                    }
                    NavigationLink(destination: CameraView()) {
                        Text("Open Camera")
                    }
                    .padding(.top, 50)
                }
                .buttonStyle(BorderedButtonStyle(borderColor: Color("AccentColor"),isDisable:false))
                .padding(.vertical, 10)
            }
        }
    }
    
    
}
#Preview{
    HomePageView()
}
