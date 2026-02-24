//
//  ContentView.swift
//  MultiClips
//
//  Created by Nitish M on 22/02/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Query(sort: \Item.copiedDate, order: .reverse) var clips: [Item]
    
    @State private var selectedClip: Item?
    var body: some View {
        NavigationSplitView{
            List(selection: $selectedClip){
                Section("Texts"){
                    ForEach(clips.filter { $0.type == ClipType.Text }) { clip in
                        Text(clip.displayTitle).tag(clip)
                    }
                }
                Section("Images"){
                    ForEach(clips.filter {$0.type == ClipType.Image }){ clip in
                        Text(clip.displayTitle).tag(clip)
                    }
                }
                Section("Files and more"){
                    ForEach(clips.filter {$0.type == ClipType.Files }){ clip in
                        Text(clip.displayTitle).tag(clip)
                    }
                }
                .navigationTitle("MultiClips")
            }
        } detail: {
            
        }
    }
}
