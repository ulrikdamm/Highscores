import Vapor
import FluentSQL

/// Register your application's routes here.
public func routes(_ router: Router) throws {
	router.get("highscore") { request -> Future<Top10> in
		let all = try ScoreEntry.query(on: request).sort(\.score, .descending).all()
		
		let top10 = all.map(to: [Placement].self, { entries -> [Placement] in
			entries.enumerated().map { i, score in
				Placement(placement: i + 1, score: score.score, name: score.name, uniqueId: score.uniqueId)
			}
		})
		
		return top10.map(to: Top10.self) { placements in Top10(top10: placements, personal: []) }
	}
	
	struct Placement : Content {
		var placement : Int
		var score : Int
		var name : String
		var uniqueId : Int
	}
	
	struct Top10 : Content {
		var top10 : [Placement]
		var personal : [Placement]
	}
	
	router.post("highscore") { request -> Future<Top10> in
		let todo = try request.content.decode(ScoreEntry.self)
		
		let newEntry = todo.flatMap { todo -> EventLoopFuture<ScoreEntry> in
			let entry = try ScoreEntry.query(on: request).filter(\ScoreEntry.uniqueId == todo.uniqueId).first()
			return entry.flatMap { foundEntry -> EventLoopFuture<ScoreEntry> in
				if let entry = foundEntry {
					entry.score = max(entry.score, todo.score)
					return entry.update(on: request)
				} else {
					return todo.save(on: request)
				}
			}
		}
		
		let top10 = newEntry.flatMap { entry -> (EventLoopFuture<[Placement]>) in
			let all = try ScoreEntry.query(on: request).sort(\.score, .descending).range(0 ..< 10).all()
			
			return all.map(to: [Placement].self, { entries -> [Placement] in
				entries.enumerated().map { i, score in
					Placement(placement: i + 1, score: score.score, name: score.name, uniqueId: score.uniqueId)
				}
			})
		}
		
		let personal = newEntry.flatMap { entry -> EventLoopFuture<[Placement]> in
			let all = try ScoreEntry.query(on: request).sort(\.score, .descending).all()
			
			return all.map { all -> [Placement] in
				guard let index = all.index(where: { e in e.uniqueId == entry.uniqueId }) else { fatalError() }
				let list = [index - 1, index, index + 1]
				return list.compactMap { index -> Placement? in
					guard let e = all.get(at: index) else { return nil }
					return Placement(placement: index + 1, score: e.score, name: e.name, uniqueId: e.uniqueId)
				}
			}
		}
		
		return top10.and(personal).map(to: Top10.self) { top10, personal in
			Top10(top10: top10, personal: personal)
		}
	}
}

extension Array {
	func get(at index : Int) -> Element? {
		if index < 0 || index >= count { return nil }
		return self[index]
	}
}
