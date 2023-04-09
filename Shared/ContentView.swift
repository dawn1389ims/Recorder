//
//  ContentView.swift
//  Shared
//
//  Created by 朱志强 on 2022/3/20.
//

import SwiftUI

struct ContentView: View {
    @State private var isPresented = false
    @State private var font: UIFontDescriptor?
    
    var body: some View {
        VStack(spacing: 30) {
            Text(font?.postscriptName ?? "")
            Button("喂奶") {
                self.isPresented = true
            }
            Button(action: {
                CommonCode.shared().clearAllRecord()
            }) {
                Text("Clear Record")
            }
        }.sheet(isPresented: $isPresented) {
            SiriPicker()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct SiriPicker: UIViewControllerRepresentable {

    // 2.
    func makeUIViewController(context: Context) -> UIViewController {
        let aVc = OrderDetailViewController.init()
        aVc.awakeFromNib()
        return aVc
    }
    
    // 3.
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }
}
