//
//  https://mczachurski.dev
//  Copyright © 2022 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import UIKit
import CoreData
import MastodonKit

struct MainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var applicationState: ApplicationState

    @State private var showSettings = false
    @State private var navBarTitle: String = "Home"
    @State private var viewMode: ViewMode = .home {
        didSet {
            self.navBarTitle = self.getViewTitle(viewMode: viewMode)
        }
    }
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.acct, order: .forward)]) var dbAccounts: FetchedResults<AccountData>
    
    private enum ViewMode {
        case home, local, federated, profile, notifications
    }
    
    var body: some View {
        self.getMainView()
        .navigationBarTitle(navBarTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings, content: {
            SettingsView()
        })
        .toolbar {
            self.getLeadingToolbar()
            self.getPrincipalToolbar()
        }
    }
    
    @ViewBuilder
    private func getMainView() -> some View {
        switch self.viewMode {
        case .home:
            HomeFeedView(accountId: applicationState.accountData?.id ?? "")
                .id(applicationState.accountData?.id ?? "")
        case .local:
            LocalFeedView()
                .id(applicationState.accountData?.id ?? "")
        case .federated:
            FederatedFeedView()
                .id(applicationState.accountData?.id ?? "")
        case .profile:
            if let accountData = self.applicationState.accountData {
                UserProfileView(accountId: accountData.id,
                                accountDisplayName: accountData.displayName,
                                accountUserName: accountData.acct)
                    .id(applicationState.accountData?.id ?? "")
            }
        case .notifications:
            NotificationsView()
                .id(applicationState.accountData?.id ?? "")
        }
    }
    
    @ToolbarContentBuilder
    private func getPrincipalToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Menu {
                Button {
                    viewMode = .home
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .home))
                        Image(systemName: "house")
                    }
                }
                
                Button {
                    viewMode = .local
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .local))
                        Image(systemName: "text.redaction")
                    }
                }

                Button {
                    viewMode = .federated
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .federated))
                        Image(systemName: "globe.europe.africa")
                    }
                }
                
                Divider()

                Button {
                    viewMode = .profile
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .profile))
                        Image(systemName: "person")
                    }
                }
                
                Button {
                    viewMode = .notifications
                } label: {
                    HStack {
                        Text(self.getViewTitle(viewMode: .notifications))
                        Image(systemName: "bell.badge")
                    }
                }
            } label: {
                HStack {
                    Text(navBarTitle)
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                }
                .frame(width: 150)
                .foregroundColor(.mainTextColor)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func getLeadingToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                ForEach(self.dbAccounts) { account in
                    Button {
                        self.applicationState.accountData = account
                        ApplicationSettingsHandler.shared.setAccountAsDefault(accountData: account)
                    } label: {
                        if self.applicationState.accountData?.id == account.id {
                            Label(account.displayName ?? account.acct, systemImage: "checkmark")
                        } else {
                            Text(account.displayName ?? account.acct)
                        }
                    }
                }

                Divider()
                
                Button {
                    self.showSettings.toggle()
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            } label: {
                if let avatarData = self.applicationState.accountData?.avatarData, let uiImage = UIImage(data: avatarData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .clipShape(Circle())
                        .frame(width: 32.0, height: 32.0)
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width: 32.0, height: 32.0)
                        .foregroundColor(.mainTextColor)
                }
            }
        }
    }
    
    private func getViewTitle(viewMode: ViewMode) -> String {
        switch viewMode {
        case .home:
            return "Home"
        case .local:
            return "Local"
        case .federated:
            return "Federated"
        case .profile:
            return "Profile"
        case .notifications:
            return "Notifications"
        }
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environment(\.managedObjectContext, CoreDataHandler.preview.container.viewContext)
    }
}
