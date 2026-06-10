import SwiftUI
import SwiftData

struct RoomsView: View {
    @StateObject private var vm = RoomsViewModel()
    @Environment(\.modelContext) private var context
    @Query private var homes: [Home]
    @Query private var allRooms: [Room]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var home: Home? { homes.first }
    private var filteredRooms: [Room] { vm.filteredRooms(allRooms) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBarView(text: $vm.searchText, placeholder: "Search rooms")
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                if filteredRooms.isEmpty && !vm.searchText.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "No rooms found",
                        subtitle: "Try a different search term."
                    )
                    Spacer()
                } else if allRooms.isEmpty {
                    EmptyStateView(
                        icon: "house",
                        title: "No rooms yet",
                        subtitle: "Add your first room to start tracking your home's cleanliness.",
                        ctaTitle: "Add Room",
                        ctaAction: { vm.isAddingRoom = true }
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredRooms) { room in
                                NavigationLink(destination: RoomDetailView(room: room)) {
                                    RoomCardView(room: room)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .animation(.spring(duration: 0.3), value: filteredRooms.map(\.id))
                    }
                    .refreshable {}
                }
            }
            .navigationTitle("Rooms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        vm.isAddingRoom = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add new room")
                }
            }
            .sheet(isPresented: $vm.isAddingRoom) {
                AddRoomView { name, icon in
                    if let home = home {
                        vm.addRoom(name: name, icon: icon, to: home, context: context)
                    }
                }
            }
        }
    }
}
