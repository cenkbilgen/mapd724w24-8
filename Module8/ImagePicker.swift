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
                Task { @MainActor in
                    switch result {
                        case .failure(let error):
                            self.error = error
                        case .success(let image):  // could be nil
                            if let image {
                                self.images.append(image)
                                self.error = nil   // reset the error state
                            } else {
                                self.error = PHPhotosError(.internalError)
                            }
                    }
                }
            }
        }
    }

    @Published var images: [Image] = []

    @Published var error: Error?
}

struct ImagePicker: View {
    @StateObject var state = PhotosState()
    @State var presentPhotos = false
    @State var presentFiles = false

    @State var presentHistory = false

    static let detents: [PresentationDetent] = [.fraction(0.3), .large]
    @State var currentDetent: PresentationDetent = ImagePicker.detents[0]

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .overlay(state.images.last?
                    .resizable()
                    .aspectRatio(1, contentMode: .fill))
                    .ignoresSafeArea(.all) // want to extend
                .overlay(alignment: .topTrailing) {
                    Button {
                        presentHistory.toggle()
                    } label: {
                        Text("History (\(state.images.count))")
                            .padding()
                    }
                    .background(.bar)
                    .padding()
                    .opacity(state.images.count >= 1 ? 1 : 0)
                    .ignoresSafeArea([]) // do not want to extend
                }

            HStack(spacing: 0) {
                Button {
                    presentPhotos = true
                } label: {
                    Color.red
                        .overlay(Text("Get Photo"))
                }

                Button {
                    print("Not Implemented")
                } label: {
                    Color.yellow
                        .overlay(Text("Get File"))
                }
            }
            .foregroundColor(.primary)
        }
        .photosPicker(isPresented: $presentPhotos, 
                      selection: $state.photoItem,
                      matching: .images,
                      preferredItemEncoding: .compatible)
        .sheet(isPresented: $presentHistory) {
            HistorySheet(isLarge: currentDetent == .large)
                .presentationDetents(Set(ImagePicker.detents),
                                     selection: $currentDetent)
                .environmentObject(state) // "state" now available to all Views under HistorySheet in the heirarchy
                // NOTE: modals like sheets create their own hierarchy, not part of the one established in App Scene
        }
    }
}

struct HistorySheet: View {
    let isLarge: Bool

    var body: some View {

        // ScrollView was not expected for assignment, but everybody did

        // NOTE: Alternative to this is:
        // ScrollView(isLarge ? .vertical : .horizontal) { if ... }
        // but it did not behave as expected without additional modifiers

        if isLarge {
            ScrollView(.vertical) {
                VStack {
                    ImagesView(isDeleteAllowed: true)
                }
            }
            .padding()
        } else {
            ScrollView(.horizontal) {
                HStack {
                    ImagesView(isDeleteAllowed: false)
                }
            }
            .padding()
        }
    }

    struct ImagesView: View {
        @EnvironmentObject var state: PhotosState

        @Environment(\.dismiss) var dismiss

        let isDeleteAllowed: Bool

        var body: some View {
            ForEach(state.images.indices, id: \.self) { index in
                state.images[index]
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Button {
                            state.images.remove(at: index)
                        } label: {
                            Color.clear // we want the hit area to be whole image
                                .overlay(Image(systemName: "trash.circle")
                                    .resizable()
                                    .background(Circle().fill(.white).opacity(0.2)) // make button standout a bit, could also add .shadow
                                    .frame(width: 60, height: 60)) // fix size to sensible button size
                        }
                            .opacity(isDeleteAllowed ? 1 : 0)
                    )
            }
            .onChange(of: state.images) { _, newValue in
                if newValue.isEmpty {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    ImagePicker()
}
