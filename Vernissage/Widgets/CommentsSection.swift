//
//  https://mczachurski.dev
//  Copyright © 2023 Marcin Czachurski and the repository contributors.
//  Licensed under the MIT License.
//

import SwiftUI
import MastodonSwift

struct CommentsSection: View {
    @EnvironmentObject var applicationState: ApplicationState

    @State public var statusId: String
    @State public var withDivider = true
    @State private var context: Context?
    
    var onNewStatus: (_ context: Status) -> Void?

    private let contentWidth = Int(UIScreen.main.bounds.width) - 50
    
    var body: some View {
        VStack {
            if let context = context {
                ForEach(context.descendants, id: \.id) { status in
                    
                    if withDivider {
                        Rectangle()
                            .size(width: UIScreen.main.bounds.width, height: 4)
                            .fill(Color.mainTextColor)
                            .opacity(0.2)
                    }
                    
                    HStack (alignment: .top) {
                        
                        if let account = status.account {
                            NavigationLink(destination: UserProfileView(
                                accountId: account.id,
                                accountDisplayName: account.displayName,
                                accountUserName: account.acct)
                                .environmentObject(applicationState)) {
                                    AsyncImage(url: account.avatar) { image in
                                        image
                                            .resizable()
                                            .clipShape(Circle())
                                            .aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        Image(systemName: "person.circle")
                                            .resizable()
                                            .foregroundColor(.mainTextColor)
                                    }
                                    .frame(width: 32.0, height: 32.0)
                                }
                        }
                        
                        VStack (alignment: .leading) {
                            HStack (alignment: .top) {
                                Text(status.account?.displayName ?? status.account?.acct ?? status.account?.username ?? "")
                                    .foregroundColor(.mainTextColor)
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                
                                Spacer()
                                
                                Text(status.createdAt.toRelative(.isoDateTimeMilliSec))
                                    .foregroundColor(.lightGrayColor)
                                    .font(.footnote)
                            }
                            
                            HTMLFormattedText(status.content, withFontSize: 14, andWidth: contentWidth)
                                .padding(.top, -10)
                                .padding(.leading, -4)
                            
                            if status.mediaAttachments.count > 0 {
                                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: status.mediaAttachments.count == 1 ? 1 : 2), alignment: .center, spacing: 4) {
                                    ForEach(status.mediaAttachments, id: \.id) { attachment in
                                        AsyncImage(url: status.mediaAttachments[0].url) { image in
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .frame(height: status.mediaAttachments.count == 1 ? 200 : 100)
                                                .cornerRadius(10)
                                                .shadow(color: .mainTextColor.opacity(0.3), radius: 2)
                                        } placeholder: {
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .frame(height: status.mediaAttachments.count == 1 ? 200 : 100)
                                                .foregroundColor(.mainTextColor)
                                                .opacity(0.05)
                                        }
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                        }
                        .onTapGesture {
                            withAnimation(.linear(duration: 0.3)) {
                                if status.id == self.applicationState.showInteractionStatusId {
                                    self.applicationState.showInteractionStatusId = ""
                                } else {
                                    self.applicationState.showInteractionStatusId = status.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                    
                    if self.applicationState.showInteractionStatusId == status.id {
                        VStack (alignment: .leading) {
                            InteractionRow(statusId: status.id,
                                           repliesCount: status.repliesCount,
                                           reblogged: status.reblogged,
                                           reblogsCount: status.reblogsCount,
                                           favourited: status.favourited,
                                           favouritesCount: status.favouritesCount,
                                           bookmarked: status.bookmarked) {
                                onNewStatus(status)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .background(Color.mainTextColor.opacity(0.08))
                        .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                    }

                    CommentsSection(statusId: status.id, withDivider: false)  { context in
                        onNewStatus(context)
                    }
                }
            }
        }
        .task {
            do {
                if let accountData = applicationState.accountData {
                    self.context = try await TimelineService.shared.getComments(
                        for: statusId,
                        and: accountData)
                }
            } catch {
                print("Error \(error.localizedDescription)")
            }
        }
    }
}

struct CommentsSection_Previews: PreviewProvider {
    static var previews: some View {
        CommentsSection(statusId: "", withDivider: true) { context in }
    }
}
