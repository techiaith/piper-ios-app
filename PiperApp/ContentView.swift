//
//  ContentView.swift
//  piperapp
//
//  Created by Ihor Shevchuk on 22.11.2023.
//

import SwiftUI

struct ContentView: View {
    
    @State private var text: String = "Testun y gellir ei olygu..."
    var body: some View {
        VStack {
            HStack {
                Image(.logoCY)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 50)
                    .padding()
                Image(.bu)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.tint)
                    .padding()
            }
            Image(.ttss)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .padding()
            TextEditor(text: $text)
                .overlay(RoundedRectangle(cornerRadius: 8.0).strokeBorder(Color.gray, style: StrokeStyle(lineWidth: 1.0)))
                .padding()
            HStack {
                Button {
                    PiperDemo.shared.doJob(textInput: text)
                } label: {
                    Text("Llefaru")
                }
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .foregroundColor(Color.white)
                Button {
                    clearText()
                } label: {
                    Text("Clirio")
                }
                .padding()
                .background(Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .foregroundColor(Color.white)
            }
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
    }
        
    func clearText() {
        self.text = ""
    }
    
}

#Preview {
    ContentView()
}
