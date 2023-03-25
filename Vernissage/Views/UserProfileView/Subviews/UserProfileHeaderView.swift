//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import PixelfedKit

struct UserProfileHeaderView: View {
    @EnvironmentObject private var applicationState: ApplicationState
    @EnvironmentObject private var client: Client
    @EnvironmentObject private var routerPath: RouterPath
    
    @State var account: Account
    @State var relationship: Relationship? = nil
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                UserAvatar(accountAvatar: account.avatar, size: .profile)
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("\(account.statusesCount)")
                        .font(.title3)
                    Text("userProfile.title.posts", comment: "Posts")
                        .font(.subheadline)
                        .opacity(0.6)
                }
                
                Spacer()
                
                NavigationLink(value: RouteurDestinations.accounts(listType: .followers(entityId: account.id))) {
                    VStack(alignment: .center) {
                        Text("\(account.followersCount)")
                            .font(.title3)
                        Text("userProfile.title.followers", comment: "Followers")
                            .font(.subheadline)
                            .opacity(0.6)
                    }
                }.foregroundColor(.mainTextColor)
                                
                Spacer()
                
                NavigationLink(value: RouteurDestinations.accounts(listType: .following(entityId: account.id))) {
                    VStack(alignment: .center) {
                        Text("\(account.followingCount)")
                            .font(.title3)
                        Text("userProfile.title.following", comment: "Following")
                            .font(.subheadline)
                            .opacity(0.6)
                    }
                }.foregroundColor(.mainTextColor)
            }
            
            HStack (alignment: .center) {
                VStack(alignment: .leading) {
                    Text(account.displayNameWithoutEmojis)
                        .foregroundColor(.mainTextColor)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("@\(account.acct)")
                        .foregroundColor(.lightGrayColor)
                        .font(.subheadline)
                }
                
                Spacer()
                
                if self.applicationState.account?.id != self.account.id {
                    self.otherAccountActionButtons()
                }
            }
            
            if let note = account.note, !note.asMarkdown.isEmpty {
                MarkdownFormattedText(note.asMarkdown, withFontSize: 14, andWidth: Int(UIScreen.main.bounds.width) - 16)
                    .environment(\.openURL, OpenURLAction { url in
                        routerPath.handle(url: url)
                    })
                    .padding(.vertical, 4)
            }
            
            if let website = account.website, let url = URL(string: website) {
                HStack {
                    Image(systemName: "link")
                    Link(website, destination: url)
                    Spacer()
                }
                .padding(.bottom, 2)
                .font(.footnote)
            }
            
            Text(String(format: NSLocalizedString("userProfile.title.joined", comment: "Joined"), account.createdAt.toRelative(.isoDateTimeMilliSec)))
                .foregroundColor(.lightGrayColor.opacity(0.5))
                .font(.footnote)
        }
        .padding()
    }
    
    @ViewBuilder
    private func otherAccountActionButtons() -> some View {
        ActionButton {
            await onRelationshipButtonTap()
        } label: {
            HStack {
                Image(systemName: relationship?.following == true ? "person.badge.minus" : "person.badge.plus")
                Text(relationship?.following == true ? "userProfile.title.unfollow" : (relationship?.followedBy == true ? "userProfile.title.followBack" : "userProfile.title.follow"), comment: "Follow/unfollow actions")
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(relationship?.following == true ? .dangerColor : .accentColor)
    }
    
    private func onRelationshipButtonTap() async {
        do {
            if self.relationship?.following == true {
                if let relationship = try await self.client.accounts?.unfollow(account: self.account.id) {
                    self.relationship = relationship
                }
            } else {
                if let relationship = try await self.client.accounts?.follow(account: self.account.id) {
                    self.relationship = relationship
                }
            }
        } catch {
            ErrorService.shared.handle(error, message: "userProfile.error.relationship", showToastr: true)
        }
    }
}

