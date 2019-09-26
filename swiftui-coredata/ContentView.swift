//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        VStack {
            TextField("Enter new user name", text: $store.userName)
            List(store.users) { (user: User) in
                Text(user.userName ?? "John Doe")
            }

            HStack {
                Button(action: store.createNewUser) { Text("Add new") }
                Button(action: store.loadUsers) { Text("Load all") }
                Button(action: store.dropAll) { Text("Fuck'em all!") }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
