import FluentSQLite
import Vapor

final class ScoreEntry: SQLiteModel {
    var id: Int?

	var score : Int
	var name : String
	var uniqueId : Int
	
	init(id: Int? = nil, score : Int, name : String, uniqueId : Int) {
        self.id = id
        self.score = score
		self.name = name
		self.uniqueId = uniqueId
    }
}

extension ScoreEntry: Migration { }
extension ScoreEntry: Content { }
extension ScoreEntry: Parameter { }
