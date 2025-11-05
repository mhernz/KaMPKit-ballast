//
//  BreedListView.swift
//  KaMPKitiOS
//
//  Created by Russell Wolf on 7/26/21.
//  Copyright © 2021 Touchlab. All rights reserved.
//

import SwiftUI
import shared

private let log = koin.loggerWithTag(tag: "BreedListScreen")

struct BreedListScreen: View {

    @State
    var viewModel: BreedViewModel?

    @State
    var vmState: BreedContract.State = BreedContract.State()

    var body: some View {
        BreedListContent(
            vmState: vmState,
            postInput: { input in
                viewModel?.trySend(element: input)
            }
        )
        .task {
            let viewModel = KotlinDependencies.shared.getBreedViewModel()
            self.viewModel = viewModel
            viewModel.trySend(element: BreedContract.InputsRefreshBreeds(forceRefresh: false))
            
            for await state in viewModel.observeStates() {
                self.vmState = state
            }
        }
        .onDisappear {
            viewModel?.close()
            self.viewModel = nil
        }
    }
}

struct BreedListContent: View {
    var vmState: BreedContract.State
    var postInput: (BreedContract.Inputs) -> Void

    var body: some View {
        ZStack {
            VStack {
                let breeds = vmState.breedsList
                if !breeds.isEmpty {
                    List(breeds, id: \.id) { breed in
                        BreedRowView(breed: breed) {
                            postInput(BreedContract.InputsUpdateBreedFavorite(breed: breed))
                        }
                    }
                }
                if let error = vmState.error {
                    Text(error)
                        .foregroundColor(.red)
                    Spacer()
                }

                Button("Refresh") {
                    postInput(BreedContract.InputsRefreshBreeds(forceRefresh: true))
                }
            }
            if vmState.isLoading { Text("Loading...") }
        }
    }
}

struct BreedRowView: View {
    var breed: Breed
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(breed.name)
                    .padding(4.0)
                Spacer()
                Image(systemName: (!breed.favorite) ? "heart" : "heart.fill")
                    .padding(4.0)
            }
        }
    }
}

struct BreedListScreen_Previews: PreviewProvider {
    static var previews: some View {
        BreedListContent(
            vmState: BreedContract.State(),
            postInput: { input in }
        )
    }
}
