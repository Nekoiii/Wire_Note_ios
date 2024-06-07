struct MusicalNote {
    let symbol: String
    let weight: Int
}

let musicalNotes: [MusicalNote] = [
    MusicalNote(symbol: "♪", weight: 10),
    MusicalNote(symbol: "♩", weight: 10),
    MusicalNote(symbol: "♫", weight: 10),
    MusicalNote(symbol: "♬", weight: 10),
    MusicalNote(symbol: "♭", weight: 1),
    MusicalNote(symbol: "♮", weight: 1),
    MusicalNote(symbol: "♯", weight: 1),
    MusicalNote(symbol: "𝄪", weight: 1),
    MusicalNote(symbol: "𝄫", weight: 1),
    MusicalNote(symbol: "𝄞", weight: 1),
]

func weightedRandomNote() -> String {
    let totalWeight = musicalNotes.reduce(0) { $0 + $1.weight }
    let randomValue = Int.random(in: 0 ..< totalWeight)
    var cumulativeWeight = 0

    for note in musicalNotes {
        cumulativeWeight += note.weight
        if randomValue < cumulativeWeight {
            return note.symbol
        }
    }

    return musicalNotes.first?.symbol ?? "♪"
}
