//
//  ImagePicker.swift
//  Module8
//
//  Created by Cenk Bilgen on 2024-03-08.
//

import SwiftUI
import PhotosUI

class PhotosState: ObservableObject {
    @Published var photoItem: PhotosPickerItem? {
        didSet {
            print("Photo Selected \(photoItem.debugDescription)")
            photoItem?.loadTransferable(type: Image.self) { result in
                switch result {
                    case .failure(let error):
                        print(error.localizedDescription)
                    case .success(let image):
                        self.image = image
                }
            }
        }
    }

    @Published var fileURL: URL?

    @Published var image: Image?

}

struct ImagePicker: View {
    @StateObject var state = PhotosState()
    @State var presentPhotos = false
    @State var presentFiles = false

    var body: some View {
        VStack(spacing: 0) {
            Color.green
                .overlay(
            state.image?
                .resizable()
                .aspectRatio(1, contentMode: .fit)
            )

            HStack(spacing: 0) {
                Button {
                    presentPhotos = true
                } label: {
                    Color.red
                        .overlay(Text("Get Photo"))
                }

                Button {
                    presentFiles = true
                } label: {
                    Color.yellow
                        .overlay(Text("Get File"))
                }
            }
            .foregroundColor(.primary)
        }
        .photosPicker(isPresented: $presentPhotos, selection: $state.photoItem, matching: .images, preferredItemEncoding: .compatible)
        .fileImporter(isPresented: $presentFiles, allowedContentTypes: [.image]) { result in
            switch result {
                case .success(let url):
                    state.fileURL = url
                case .failure(let error):
                    print(error.localizedDescription)
            }
        }
    }
}

#Preview {
    ImagePicker()
}
