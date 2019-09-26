//

import Foundation
import CoreData
import Combine

class AppStore: ObservableObject {
    let database: Database

    private var disposeBag: Set<AnyCancellable> = []
    @Published var userName: String = ""
    @Published var users: [User] = []

    init(_ db: Database) {
        database = db
    }

    func createNewUser() {
        let username = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        if username != "" {
            disposeBag.removeAll()

            database
                .createUser(name: username)
                .flatMap({ _ in self.database.loadUsers() })
                .assign(to: \AppStore.users, on: self)
                .store(in: &disposeBag)
        }
    }

    func loadUsers() {
        disposeBag.removeAll()

        database.loadUsers()
            .assign(to: \AppStore.users, on: self)
            .store(in: &disposeBag)
    }

    func dropAll() {
        disposeBag.removeAll()
        database.dropAll()
            .map({ _ -> [User] in [] })
            .assign(to: \AppStore.users, on: self)
            .store(in: &disposeBag)
    }
}

class Database {
    private let persistentContainer: NSPersistentContainer

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    init(dbName: String) {
        self.persistentContainer = NSPersistentContainer(name: dbName)
        self.persistentContainer.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
    }

    func createUser(name: String) -> AnyPublisher<User?, Never> {
        return Result {
            let user = User(context: context)
            user.syncId = UUID()
            user.userName = name
            try context.save()
            return user
        }
        .publisher
        .catch({ _ in Just(.none) }) // ignoring errors...
        .eraseToAnyPublisher()
    }

    func loadUsers() -> AnyPublisher<[User], Never> {
        return Result {
            let request: NSFetchRequest<User> = User.fetchRequest()
            return try context.fetch(request)
        }
        .publisher
        .catch({ _ in Just([]) }) // Ignoring errors...
        .eraseToAnyPublisher()
    }

    func dropAll() -> AnyPublisher<Void, Never> {
        return loadUsers()
            .flatMap(self.dropUsers)
            .eraseToAnyPublisher()
    }

    private func dropUsers(_ users: [User]) -> AnyPublisher<Void, Never> {
        return Result {
            users.forEach({ self.context.delete($0) })
            try self.context.save()
            return ()
        }
        .publisher
        .catch({ _ in Just(()) }) // ignoring for now the errors...
        .eraseToAnyPublisher()
    }
}

extension User: Identifiable {
}
