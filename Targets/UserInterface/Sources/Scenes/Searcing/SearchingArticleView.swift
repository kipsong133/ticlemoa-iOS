//
//  SearchingArticleView.swift
//  UserInterface
//
//  Created by Joseph Cha on 2022/12/15.
//  Copyright © 2022 nyongnyong. All rights reserved.
//

import SwiftUI

struct SearchingArticleView: View {
    @ObservedObject var viewModel: SearchingArticleViewModel
    @State var recentQueries: [String] = (UserDefaults.standard
        .array(forKey: "searchQueries") as? [String] ?? []
    ) {
        willSet {
            UserDefaults.standard.set(newValue, forKey: "searchQueries")
        }
    }
    @Environment(\.presentationMode) private var presentationMode
    
    init(viewModel: SearchingArticleViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 32) {
                searchBar
                if case let .searched(items) = viewModel.state {
                    VStack(spacing: 0) {
                        HStack {
                            Text("총 \(items.count)개의 검색결과")
                                .font(.system(size: 14))
                            Spacer()
                        }
                        .padding(.leading, 20)
                        List {
                            ForEach(items, id: \.id) { item in
                                ArticleRow(title: item.title, imageURLString: "")
                            }
                        }
                        .listStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            UIApplication.shared.sendAction(
                                #selector(UIResponder.resignFirstResponder),
                                to: nil,
                                from: nil,
                                for: nil
                            )
                        }
                    }
                } else {
                    recentQueryList
                }
                Spacer()
            }
            if case let .searched(items) = viewModel.state,
               items.isEmpty {
                VStack {
                    Image("Nothing")
                    Text("검색 결과가 없습니다")
                        .font(.system(size: 14))
                        .foregroundColor(.grey4)
                }
            } else if recentQueries.isEmpty {
                VStack {
                    Image("Nothing")
                    Text("최근 검색어가 없습니다")
                        .font(.system(size: 14))
                        .foregroundColor(.grey4)
                }
            }
        }
        .setupBackground()
        .hideKeyboard()
        .onChange(of: viewModel.searchQuery) { searchQuery in
            if searchQuery.isEmpty {
                viewModel.state = .idle
            }
        }
        .onReceive(viewModel.$searchQuery.debounce(for: 3, scheduler: RunLoop.main)) { query in
            Task {
                guard let searchedQuery = await self.viewModel.submit(by: query) else { return }
                self.recentQueries.insert(searchedQuery, at: 0)
            }
        }
        .onAppear {
            self.recentQueries = (UserDefaults.standard.array(forKey: "searchQueries") as? [String] ?? [])
        }
    }
}

extension SearchingArticleView {
    
    var searchBar: some View {
        HStack(spacing: 16.19) {
            Button {
                self.presentationMode.wrappedValue.dismiss()
            } label: {
                Image("arrow")
            }
            HStack(spacing: 0) {
                Image("search")
                    .padding(.leading, 11.5)
                TextField("", text: $viewModel.searchQuery)
                    .placeholder(
                        "검색어를 입력해주세요",
                        when: viewModel.searchQuery.isEmpty,
                        color: .grey3
                    )
                    .font(.system(size: 14))
                    .padding(.leading, 6.11)
                    .submitLabel(.done)
                    .onSubmit {
                        Task {
                            guard let searchedQuery = await self.viewModel.submit() else { return }
                            self.recentQueries.insert(searchedQuery, at: 0)
                        }
                    }
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                    } label: {
                        Image("ClearButtonGreyLine2")
                            .frame(width: 16.5, height: 16.5)
                            .padding(.leading, 8.75)
                            .padding(.trailing, 12.75)
                    }
                }
            }
            .frame(height: 42)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.grey2Line, lineWidth: 1)
            )
        }
        .padding(.leading, 24.52)
        .padding(.trailing, 20)
    }
    
    var recentQueryList: some View {
        VStack(spacing: 0) {
            HStack{
                Text("최근 검색어")
                    .font(.system(size: 14))
                Spacer()
                Button {
                    self.recentQueries = []
                } label: {
                    Text("전체삭제")
                        .foregroundColor(.grey3)
                        .font(.system(size: 12))
                }
            }
            .padding([.horizontal, .bottom], 20)
            ScrollView {
                LazyVStack {
                    ForEach(Array(zip(recentQueries.indices, recentQueries)), id: \.0) { index, recentQuery in
                        RecentQueryRow(
                            recentQuery: recentQuery,
                            searchAction: { self.viewModel.searchQuery = $0 },
                            removeAction: { self.recentQueries.remove(at: index) }
                        )
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
    
}

struct SearchingArticleView_Previews: PreviewProvider {
    static var previews: some View {
        SearchingArticleView(viewModel: .init(modelContainer: .dummy))
    }
}
