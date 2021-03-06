//
//  DefectDetail.swift
//  CityPower
//
//  Created by Natcha Watcharawittayakul on 10/2/2564 BE.
//  Copyright © 2564 BE City Power. All rights reserved.
//

import Foundation
import RxDataSources
import Firebase

struct CommentStruct: Codable {
    var title: String
    var timeStamp: String
    var value: String
    
    init(title: String, timeStamp: String, value: String = "") {
        self.title = title
        self.timeStamp = timeStamp
        self.value = value
    }
    
    var dictionary: [String: Any] {
      return [
        "title": title,
        "timeStamp": timeStamp,
        "value": value,
      ]
    }
    
    init?(dictionary: [String : Any]) {
        guard let title = dictionary["title"] as? String,
            let timeStamp = dictionary["timeStamp"] as? String,
            let value = dictionary["value"] as? String else { return nil }
        
        self.init(title: title,timeStamp: timeStamp, value: value)
    }
}

extension CommentStruct: IdentifiableType {
    var identity: String {
        return self.title + self.timeStamp + self.value
    }
    typealias Identity = String
}

extension CommentStruct: Hashable {
    static func == (lhs: CommentStruct, rhs: CommentStruct) -> Bool {
        return lhs.title == rhs.title &&
            lhs.timeStamp == rhs.timeStamp &&
            lhs.value == rhs.value
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(timeStamp)
        hasher.combine(value)
    }
}


struct ImageStruct: Codable {
    var image: String
    var timeStamp: String
    var fileName: String
    
    init(image: String, timeStamp: String, fileName: String) {
        self.image = image
        self.timeStamp = timeStamp
        self.fileName = fileName
    }
    
    var dictionary: [String: Any] {
      return [
        "image": image,
        "timeStamp": timeStamp,
        "fileName": fileName,
      ]
    }
    
    init?(dictionary: [String : Any]) {
        guard let image = dictionary["image"] as? String,
            let timeStamp = dictionary["timeStamp"] as? String,
            let fileName = dictionary["fileName"] as? String else { return nil }
        
        self.init(image: image,timeStamp: timeStamp, fileName: fileName)
    }
}

extension ImageStruct: IdentifiableType {
    var identity: String {
        return self.image + self.timeStamp
    }
    typealias Identity = String
}

extension ImageStruct: Hashable {
    static func == (lhs: ImageStruct, rhs: ImageStruct) -> Bool {
        return lhs.image == rhs.image &&
            lhs.timeStamp == rhs.timeStamp
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(image)
        hasher.combine(timeStamp)
    }
}


struct DefectDetail: Codable {
    
    let defectNumber : String
    let defectTitle: String
    let timeStamp: String
    let dueDate: String
    let status: String
    let system: String
    
    var defectComment: [CommentStruct]
    var defectImage: [ImageStruct]
    var positionX: Double
    var positionY: Double
    
    var dictionary: [String: Any] {
      return [
        "defectNumber": defectNumber,
        "defectTitle": defectTitle,
        "defectImage": defectImage,
        "defectComment": defectComment,
        "status": status,
        "system": system,
        "timeStamp": timeStamp,
        "dueDate": dueDate,
        "positionX": positionX,
        "positionY": positionY,
      ]
    }
    
    init(defectNumber: String, defectTitle: String, defectImage: [ImageStruct], defectComment: [CommentStruct], status: String, system: String, timeStamp: String, dueDate: String, positionX: Double, positionY: Double) {
        self.defectNumber = defectNumber
        self.defectTitle = defectTitle
        self.defectImage = defectImage
        self.defectComment = defectComment
        self.status = status
        self.system = system
        self.timeStamp = timeStamp
        self.dueDate = dueDate
        self.positionX = positionX
        self.positionY = positionY
    }
    
    init?(dictionary: [String : Any]) {
        guard let defectNumber = dictionary["defectNumber"] as? String,
            let defectTitle = dictionary["defectTitle"] as? String,
            let defectImage = dictionary["defectImage"] as? [[String: Any]],
            let defectComment = dictionary["defectComment"] as? [[String: Any]],
            let status = dictionary["status"] as? String,
            let system = dictionary["system"] as? String,
            let timeStamp = dictionary["timeStamp"] as? String,
            let dueDate = dictionary["dueDate"] as? String,
            let positionX = dictionary["positionX"] as? Double,
            let positionY = dictionary["positionY"] as? Double else { return nil }
        
        self.defectNumber = defectNumber
        self.defectTitle = defectTitle
        self.defectImage = defectImage.map( {ImageStruct(image: $0["image"] as! String, timeStamp: $0["timeStamp"] as! String, fileName: $0["fileName"] as! String) } )
        self.defectComment = defectComment.map( {CommentStruct(title: $0["title"] as! String, timeStamp: $0["timeStamp"] as! String, value: $0["value"] as! String) } )
        self.status = status
        self.timeStamp = timeStamp
        self.system = system
        self.dueDate = dueDate
        self.positionX = positionX
        self.positionY = positionY
    }
    
    var position: CGPoint {
        get { return CGPoint(x: positionX, y: positionY) }
        set {
            positionX = Double(newValue.x)
            positionY = Double(newValue.y)
        }
    }
}

extension DefectDetail: Hashable {
    static func == (lhs: DefectDetail, rhs: DefectDetail) -> Bool {
        return lhs.defectNumber == rhs.defectNumber &&
            lhs.timeStamp == rhs.timeStamp &&
            lhs.defectTitle == rhs.defectTitle &&
            lhs.defectComment == rhs.defectComment &&
            lhs.defectImage == rhs.defectImage &&
            lhs.status == rhs.status
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(defectNumber)
        hasher.combine(timeStamp)
        hasher.combine(defectTitle)
        hasher.combine(defectComment)
        hasher.combine(defectImage)
        hasher.combine(status)
    }
}

extension DefectDetail: IdentifiableType {
    var identity: String {
        return self.defectNumber + self.timeStamp + self.defectTitle
    }
    typealias Identity = String
}


class DefectDetails {
    
    static let shared = DefectDetails()
    static let fileManager = FileManager.default
    
    var currentGroup: String?
    var currentIndex: Int?
    var documentID: [String : String]?
    var groupDocumentID: [String : String]?
    var ref: CollectionReference?
    var siteLoaded: Bool?
    
    var selectedSite: String?
        
    var savedPosition: [ImagePosition?] = [] {
        didSet {
            if let layoutPoint = layoutPoint {
                layoutPoint()
            }
        }
    }
    
    var savedGroup: [String: DefectGroup?] = [:] {
        didSet {
            if let updateGroup = updateGroup {
                updateGroup()
            }
            
            if let updateStatus = updateStatus {
                updateStatus()
            }
        }
    }
    
    var savedDefect: [String: DefectDetail?] = [:] {
        didSet {
            if let updateCell = updateCell {
                updateCell()
            }
        }
    }
    
    var savedComment: [CommentStruct?] = [] {
        didSet {
            if let updateComment = updateComment {
                updateComment()
            }
        }
    }
    
    var savedPicture: [ImageStruct?] = [] {
        didSet {
            if let updatePicture = updatePicture {
                updatePicture()
            }
        }
    }
    
    var savedSite: [SiteGroup?] = [] {
        didSet {
            if let updateSite = updateSite {
                updateSite()
            }
        }
    }
    
    var updateStatus: (() -> Void)?
    var updateSite: (() -> Void)?
    var layoutPoint: (() -> Void)?
    var updateCell: (() -> Void)?
    var updatePicture: (() -> Void)?
    var updateComment: (() -> Void)?
    var updateGroup: (() -> Void)?
    
    private var defectReference: [DocumentSnapshot] = []
    private var groupReference: [DocumentSnapshot] = []
    private var myUID: String?
    
    private var listener: ListenerRegistration? {
        didSet {
            oldValue?.remove()
        }
    }
    
    private var listListener: ListenerRegistration? {
        didSet {
            oldValue?.remove()
        }
    }
    
    private let db = Firestore.firestore()
    
    fileprivate init() {
        
//        Auth.auth().addStateDidChangeListener { (auth, listenerUser) in
//            if let user = listenerUser {
//                print("SIGN IN: \(user.email ?? user.uid)")
//                self.myUID = user.uid
//                self.userExists(user, completionHandler: { (exists) in
//                    if(!exists){
//                        self.newUser(user, completionHandler: nil)
//                    }
//                })
//            } else {
//                self.myUID = nil
//                Auth.auth().signInAnonymously(completion: { (authResult, error) in
//                    if let error = error {
//                        print(error.localizedDescription)
//                    } else {
//                        print("Anonymously Signed In")
//                    }
//                })
//            }
//        }
    }
    
    func signIn() {
        
        Auth.auth().signInAnonymously(completion: { (authResult, error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Anonymously Signed In")
            }
        })
    }
    
    func userExists(_ user: User, completionHandler: @escaping (Bool) -> ()) {

        db.collection("users").document("user.uid").getDocument  { (document, error) in
            
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data: \(dataDescription)")
                completionHandler(true)

            } else {
                print("Document does not exist")
                completionHandler(false)
            }
        }
    }

    func newUser(_ user: User, completionHandler: ((_ success:Bool) -> ())? ) {

        var newUser: [String: Any] = ["createdAt": Date.init().timeIntervalSince1970]

        if let nameString = user.displayName { newUser["name"] = nameString }
        if let imageURL = user.photoURL { newUser["image"] = imageURL }
        if let emailString = user.email { newUser["email"] = emailString }

        db.collection("users").document("user.uid").updateData(newUser) { error in
            if let e = error {
                print(e.localizedDescription)
                if let completion = completionHandler{
                    completion(false)
                }
            } else {
                if let completion = completionHandler{
                    completion(true)
                }
            }
        }
    }
    
    func loadSite() {
        
        guard siteLoaded == nil else { return }
        
         db.collection("site").getDocuments { [unowned self] querySnapshot, error in
            
            guard let snapshot = querySnapshot else {
              print("Error fetching snapshot results: \(error!)")
              return
            }
                        
            var models: [SiteGroup] = []
            
            for document in snapshot.documents {
                if let model = SiteGroup(dictionary: document.data()) {
                    models.append(model)
                }
            }
            self.savedSite = models
        }
        siteLoaded = true
    }

    func loadDefect() {

        guard listener == nil, let currentSite = selectedSite else { return }
        
        listener = db.collection("plan").document("site").collection(currentSite).addSnapshotListener(includeMetadataChanges: true) { [unowned self] querySnapshot, error in
            
            guard let snapshot = querySnapshot else {
              print("Error fetching snapshot results: \(error!)")
              return
            }
                        
            var models: [String: DefectGroup] = [:]
            var ids: [String: String] = [:]
            
            for document in snapshot.documents {
                if let model = DefectGroup(dictionary: document.data()) {
                    models[model.planTitle] = model
                    ids[model.planTitle] = document.documentID
                }
            }
            
            if !snapshot.metadata.hasPendingWrites {
                self.savedGroup = models
                self.groupDocumentID = ids
                self.groupReference = snapshot.documents
                
                if let currentIndex = currentGroup, let pos = savedGroup[currentIndex] as? DefectGroup {
                    self.savedPosition = pos.defectPosition
                }
            }
        }
    }
    
    func loadList(_ planName: String) {
        
        guard listListener == nil, let currentSite = selectedSite else { return }
                
        if let currentIndex = currentGroup, let pos = savedGroup[currentIndex] as? DefectGroup {
            self.savedPosition = pos.defectPosition
        }

        listListener = db.collection(currentSite).document(planName).collection("defect")
            .addSnapshotListener(includeMetadataChanges: true) { [unowned self] querySnapshot, error in
            
            guard let snapshot = querySnapshot else {
              print("Error fetching snapshot results: \(error!)")
              return
            }
                        
            var models: [String: DefectDetail] = [:]
            var ids: [String: String] = [:]
            
            for document in snapshot.documents {
                if let model = DefectDetail(dictionary: document.data()) {
                    models[model.defectNumber] = model
                    ids[model.defectNumber] = document.documentID
                }
            }
            
            if !snapshot.metadata.hasPendingWrites {
                self.savedDefect = models
                self.documentID = ids
                self.defectReference = snapshot.documents
                
                if let currentIndex = currentIndex, let filterModel = models["\(currentIndex)"] {
                    self.savedComment = filterModel.defectComment
                    self.savedPicture = filterModel.defectImage
                }
            }
        }
        ref = db.collection(currentSite).document(planName).collection("defect")
    }
    
    func index(of document: DocumentSnapshot) -> Int? {
      return defectReference.firstIndex(where: { $0.documentID == document.documentID })
    }
    
    func add<T: Hashable>(_ data: T) {

        guard let index = currentIndex,
              let currentData = DefectDetails.shared.savedDefect["\(index)"],
              let id = documentID?["\(index)"],
              let ref = ref else { return }
        
        if let data = data as? CommentStruct, let currentData = currentData, !currentData.defectComment.contains(data) {
            let field = "defectComment"
            let newValue = FieldValue.arrayUnion([["title": data.title,
                                                   "timeStamp": data.timeStamp, "value": data.value]])
            
            ref.document(id).updateData([field: newValue]) { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
            
        } else if let data = data as? ImageStruct, let currentData = currentData, !currentData.defectImage.contains(data) {
            let field = "defectImage"
            let newValue = FieldValue.arrayUnion([["image": data.image,
                                                   "timeStamp": data.timeStamp,
                                                   "fileName": data.fileName]])
            
            ref.document(id).updateData([field: newValue]) { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
    
    func stopListening() {
        listener = nil
    }
    
    func stopListListening() {
        listListener = nil
    }
    
    func editData<T: Hashable, Q: Hashable>(_ data: T, _ model: Q) {

        guard let index = currentIndex,
              let indexGroup = currentGroup,
              let idGroup = groupDocumentID?[indexGroup],
              let id = documentID?["\(index)"],
              let ref = ref,
              let currentSite = selectedSite else { return }
        
        if let data = data as? String, let model = model as? DefectDetail {
            
            let batch = db.batch()
            let groupRef = db.collection("plan").document("site").collection(currentSite).document(idGroup)
            let keyDate = "defectDate." + "\(index)"
            let field = "defectPosition"
            let newValue = FieldValue.arrayUnion([["x": model.positionX,
                                                   "y": model.positionY,
                                                   "pointNum": model.defectNumber,
                                                   "system": model.system,
                                                   "status": data,
                                                   "selected": true]])
            
            let deleteValue = FieldValue.arrayRemove([["x": model.positionX,
                                                   "y": model.positionY,
                                                   "pointNum": model.defectNumber,
                                                   "system": model.system,
                                                   "status": model.status,
                                                   "selected": true]])
            
            
            if data == statusDefect.Ongoing.rawValue {
                batch.updateData(["numberOfStart": FieldValue.increment(Int64(-1))], forDocument: groupRef)
                batch.updateData(["numberOfOnGoing": FieldValue.increment(Int64(1))], forDocument: groupRef)
                batch.updateData([keyDate: model.dueDate], forDocument: groupRef)
            } else if data == statusDefect.Finish.rawValue {
                batch.updateData(["numberOfOnGoing": FieldValue.increment(Int64(-1))], forDocument: groupRef)
                batch.updateData(["numberOfFinish": FieldValue.increment(Int64(1))], forDocument: groupRef)
                batch.updateData([keyDate: FieldValue.delete()], forDocument: groupRef)
            } else {
                return
            }
            
            let docuRef = ref.document(id)
            
            batch.updateData([field: deleteValue], forDocument: groupRef)
            batch.updateData([field: newValue], forDocument: groupRef)
            batch.updateData(["status": data], forDocument: docuRef)
            
            batch.commit() { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
    
    func addPoint<T: Hashable>(_ data: T) {

        guard let index = currentGroup,
              let currentData = DefectDetails.shared.savedGroup[index] as? DefectGroup,
              let id = groupDocumentID?[index],
              let currentSite = selectedSite else { return }
        
        if let data = data as? ImagePosition, !currentData.defectPosition.contains(data) {
            let field = "defectPosition"
            let newValue = FieldValue.arrayUnion([["x": data.x,
                                                   "y": data.y,
                                                   "pointNum": data.pointNum,
                                                   "system": data.system,
                                                   "status": data.status,
                                                   "selected": data.selected]])
            
            db.collection("plan").document("site").collection(currentSite).document(id).updateData([field: newValue]) { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
    
    func removePoint<T: Hashable>(_ data: [T]) {

        guard let index = currentGroup,
              let currentData = DefectDetails.shared.savedGroup[index] as? DefectGroup,
              let id = groupDocumentID?[index],
              let currentSite = selectedSite  else { return }
        
        if let data = data as? [ImagePosition], currentData.defectPosition.contains(where: data.contains) {
            let field = "defectPosition"
            let batch = db.batch()
            let docuRef = db.collection("plan").document("site").collection(currentSite).document(id)
            
            for subData in data {
                let removeValue = FieldValue.arrayRemove([["x": subData.x,
                                                           "y": subData.y,
                                                           "pointNum": subData.pointNum,
                                                           "system": subData.system,
                                                           "status": subData.status,
                                                           "selected": subData.selected]])
                batch.updateData([field: removeValue], forDocument: docuRef)
            }
            batch.commit() { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
        
    func movePoint<T: Hashable>(_ data: T, _ newData: T) {

        guard let index = currentGroup,
              let currentData = DefectDetails.shared.savedGroup[index] as? DefectGroup,
              let id = groupDocumentID?[index],
              let currentSite = selectedSite  else { return }
        
        if let data = data as? ImagePosition, let newData = newData as? ImagePosition, currentData.defectPosition.contains(data) {
            
            let field = "defectPosition"
            let newValue = FieldValue.arrayUnion([["x": newData.x,
                                                   "y": newData.y,
                                                   "pointNum": newData.pointNum,
                                                   "system": newData.system,
                                                   "status": newData.status,
                                                   "selected": newData.selected]])
            
            let batch = db.batch()
            let docuRef = db.collection("plan").document("site").collection(currentSite).document(id)
            let removeValue = FieldValue.arrayRemove([["x": data.x,
                                                       "y": data.y,
                                                       "pointNum": data.pointNum,
                                                       "system": data.system,
                                                       "status": data.status,
                                                       "selected": data.selected]])
                
            batch.updateData([field: removeValue], forDocument: docuRef)
            batch.updateData([field: newValue], forDocument: docuRef)
            batch.commit() { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
    
    func selectPoint<T: Hashable>(_ data: T, _ newData: T) {

        guard let index = currentGroup,
              let currentData = DefectDetails.shared.savedGroup[index] as? DefectGroup,
              let id = groupDocumentID?[index],
              let currentSite = selectedSite  else { return }
        
        if let data = data as? ImagePosition, let newData = newData as? ImagePosition, currentData.defectPosition.contains(data) {
            
            let field = "defectPosition"
            let newValue = FieldValue.arrayUnion([["x": newData.x,
                                                   "y": newData.y,
                                                   "pointNum": newData.pointNum,
                                                   "system": newData.system,
                                                   "status": newData.status,
                                                   "selected": newData.selected]])
            
            let batch = db.batch()
            let docuRef = db.collection("plan").document("site").collection(currentSite).document(id)
            let removeValue = FieldValue.arrayRemove([["x": data.x,
                                                       "y": data.y,
                                                       "pointNum": data.pointNum,
                                                       "system": data.system,
                                                       "status": data.status,
                                                       "selected": data.selected]])
            
            batch.updateData(["numberOfStart": FieldValue.increment(Int64(1))], forDocument: docuRef)
            batch.updateData([field: removeValue], forDocument: docuRef)
            batch.updateData([field: newValue], forDocument: docuRef)
            batch.commit() { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
    
    func remove<T: Hashable>(_ data: T) {

        guard let index = currentIndex,
              let currentData = DefectDetails.shared.savedDefect["\(index)"],
              let id = documentID?["\(index)"],
              let ref = ref else { return }
        
        if let data = data as? CommentStruct, let currentData = currentData, currentData.defectComment.contains(data) {
            let field = "defectComment"
            let newValue = FieldValue.arrayRemove([["title": data.title,
                                                   "timeStamp": data.timeStamp, "value": data.value]])
            
            ref.document(id).updateData([field: newValue]) { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
            
        } else if let data = data as? ImageStruct, let currentData = currentData, currentData.defectImage.contains(data) {
            let field = "defectImage"
            
            let imagePath = "DefectPicture" + "/\(data.fileName).jpg"
            let storage = Storage.storage()
            let storageRef = storage.reference()
            let storageChild = storageRef.child(imagePath)
            
            let newValue = FieldValue.arrayRemove([["image": data.image,
                                                   "timeStamp": data.timeStamp,
                                                   "fileName": data.fileName]])
            
            ref.document(id).updateData([field: newValue]) { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
            
            storageChild.delete { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("File Deleted")
                }
            }
        }
    }
    
    func update<T: Hashable>(_ data: T, _ newData: T) {
        
        guard let index = currentIndex,
              let id = documentID?["\(index)"],
              let ref = ref else { return }
        
        if let data = data as? CommentStruct, let newData = newData as? CommentStruct {
            
            let field = "defectComment"
            let newValue = FieldValue.arrayUnion([["title": newData.title,
                                                   "timeStamp": newData.timeStamp, "value": newData.value]])
            
            let batch = db.batch()
            let docuRef = ref.document(id)
            let removeValue = FieldValue.arrayRemove([["title": data.title,
                                                           "timeStamp": data.timeStamp, "value": data.value]])
                
            batch.updateData([field: removeValue], forDocument: docuRef)
            batch.updateData([field: newValue], forDocument: docuRef)
            batch.commit() { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
            
        } else if let data = data as? ImageStruct, let newData = newData as? ImageStruct {
            
            let field = "defectImage"
            let newValue = FieldValue.arrayUnion([["image": newData.image,
                                                   "timeStamp": newData.timeStamp,
                                                   "fileName": newData.fileName]])
            
            let batch = db.batch()
            let docuRef = ref.document(id)
            let removeValue = FieldValue.arrayRemove([["image": data.image,
                                                       "timeStamp": data.timeStamp,
                                                       "fileName": data.fileName]])
                
            batch.updateData([field: removeValue], forDocument: docuRef)
            batch.updateData([field: newValue], forDocument: docuRef)
            batch.commit() { err in
                if let err = err {
                    print(err.localizedDescription)
                } else {
                    print("Document successfully updated")
                }
            }
        }
    }
    
    private func loadFromJSONFilesOfDirectory(url contentURL: URL?) -> Any {
        
        if let validURL = contentURL,
           let contentOfFilesPath = (try? DefectDetails.fileManager.contentsOfDirectory(at: validURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])) {
            
            for url in contentOfFilesPath where url.lastPathComponent == "defectdetails.json" {
                do {
                    let data = try Data(contentsOf: url)
                    let task = try JSONDecoder().decode([DefectDetail].self, from: data)
                    return task
                    
                } catch {
                    print("Failed to write JSON data: \(error.localizedDescription)")
                }
            }
        }
        return []
    }
}


extension Encodable {

    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}
