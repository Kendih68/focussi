import SwiftUI
import FocusCore

/// Original 16×16 sprites shared by the world, inventory, and navigation.
/// The same palette and pixel grid keep every object in one visual language.
enum PixelArt {
    static let palette: [Character: Color] = [
        "l": Color(hex: 0x293B43), "g": Color(hex: 0x72A96D), "h": Color(hex: 0xB9D78A),
        "d": Color(hex: 0x427D64), "y": Color(hex: 0xE9BA67), "s": Color(hex: 0xE4C793),
        "b": Color(hex: 0x78B9C4), "u": Color(hex: 0x427E96), "r": Color(hex: 0xBE7053),
        "c": Color(hex: 0xFFF2CE), "w": Color(hex: 0xFFFDF4), "t": Color(hex: 0x92785D),
        "p": Color(hex: 0xD59891), "a": Color(hex: 0x9CAAA3)
    ]
    static let sprites: [String: [String]] = [
        "fern": ["................", "....ll....ll....", "...lggl..lggl...", "..lghhllllhhgl..", "..lgwlgggglwgl..", "..lglglggggllgl.", ".lggggggggggggl.", ".lghhgggggghhgl.", ".lgglllgglllggl.", "..lgggllllgggl..", "...lggggggggl...", "..lggghhhhgggl..", ".lggglhhhhlgggl.", ".llll.llll.llll.", "................", "................"],
        "clover": ["....ll....ll....", "...lwwl..lwwl...", "...lwpl..lpwl...", "...lwpl..lpwl...", "...lwwllllwwl...", "...lwwwwwwwwl...", "..lwwlwwwwlwwl..", "..lwwlwwwwlwwl..", "..lwwwwppwwwwl..", "...lwwllllwwl...", "....lwwwwwwl....", "...lwwwwwwwwl...", "...lwwccwwcwl...", "..lwwwccwwwcwl..", "..llll..llllll..", "................"],
        "pebble": ["................", "................", "......llll......", "....llhgggll....", "...lhggdggdgl...", "..lggddggddggl..", "..lgdgghhggdgl..", "..lgdggddggdgl..", "..lggddggddgglll", "..lgggddddggglhl", "...llggggggllhll", "..lddllgggllddl.", "..llll.llll.llll", "................", "................", "................"],
        "maple": ["..ll........ll..", "..lrl......lrl..", "..lrrl....lrrl..", "..lrcrlllllcrl..", "..lrrrrrrrrrrl..", "..lrrlrrrrlrrl..", "..lrrlrrrrlrrl..", "...lccccccccl...", "....lcccllccl...", ".....llccll.....", "....lrrrrrl.....", "...lrrccrrl..lll", "...lrrccrrlllrrl", "...lrrccrrlrrccl", "...lllllll.llll.", "................"],
        "mochi": ["................", "...ll......ll...", "...lal....lal...", "...lapllllpal...", "...laaaaaaaal...", "..laahlaahlaal..", "..laalallalaal..", "..laaaaappaaal..", "...laallllaaal..", "....laaaaaal....", "....laaccaaal...", "...laaccaaal.ll.", "...laaccaaallal.", "...laaccaaalaal.", "...lllllllllll..", "................"],
        "pippin": ["................", ".......ll.......", "......lyyl......", "....lllyylll....", "...lyyyyyyyyl...", "..lyhyyyyyyhyl..", "..lyylyyylyyyl..", "..lyylyyylyyyl..", "...lyyrrryyyl...", "....lyyyyyyl....", "..llyhhhhhhyll..", "..lyyhhhhhhyyyl.", "...llyyyyyyll...", ".....lrl.lrl....", ".....lll.lll....", "................"],
        "egg": ["................", "................", "......llll......", ".....lcccccl....", "....lccsscccl...", "....lccsscccl...", "...lcccccccccl..", "...lcccsccsccl..", "...lccsssccccl..", "...lcccscccccl..", "...lcccccssccl..", "....lcccccccl...", ".....lllllll....", "................", "................", "................"],
        "pine": [".......ll.......", "......lhhl......", ".....lhhhhl.....", "....lhhhhhdl....", ".....lhhhdl.....", "....lghhhhdl....", "...lghhhhdddl...", "..lghhhhdddddl..", "....lghhdddl....", "...lghhhddddl...", "..lghhhddddddl..", ".lggggddddddddl.", "......lttl......", "......lttl......", ".....llttll.....", "................"],
        "flowers": ["................", "................", "...pp...........", "..pwwp....yy....", "..pwwp...yccy...", "...pp....yccy...", "...dl.....yy....", "...dl.....dl....", "..gdl....gdl....", "...dl.....dl....", "...dl.....dl....", "..gglgggggdlgg..", ".gghggghggghggg.", "..dddddddddddd..", "................", "................"],
        "stones": ["................", "................", ".......llll.....", "......laaaal....", "......laaaal....", ".......llll.....", "................", "...llll.........", "..laaaal........", "..laaaal........", "...llll..llll...", "........laaaal..", "........laaaal..", ".........llll...", "................", "................"],
        "mushrooms": ["................", "................", ".....llll.......", "....lrrwrl......", "...lrwrrrrl.....", "..lrrrrrwrrl....", "..llllllllll....", ".....lccl.......", ".....lccl.......", ".....lccl..lll..", ".....lccl.lrwrl.", "....llccll.llll.", "...lddddddl.lcl.", "....llllll..lll.", "................", "................"],
        "cottage": ["................", ".......ll.......", "......lrrl......", ".....lrrrrl.....", "....lrrrrrrl....", "...lrrryrrrrl...", "..lrrrrrrrrrrl..", ".llllllllllllll.", "..lcccccccccl...", "..lcbblccccll...", "..lcbblcctttl...", "..lcccclcctttl..", "..lcccccctttl...", "..lllllllllll...", "................", "................"],
        "fountain": ["................", ".......bb.......", "......bwwb......", ".....bwwwwb.....", "......buub......", ".......uu.......", "....llluulll....", "...labbbbbbal...", "...labbwwbbal...", "....laaaaaal....", "......laal......", "...llllaaallll..", "..labbbbbbbbal..", "..laaaaaaaaal...", "...lllllllll....", "................"],
        "lantern": ["................", ".......ll.......", "......lttl......", "....llllllll....", "....lrrrrrrl....", "...lrrryyrrrl...", "...lrryyyyrrl...", "...lrryyyyrrl...", "...lrryyyyrrl...", "....lrrrrrrl....", "....llllllll....", ".......tt.......", ".......yy.......", "......yyyy......", "................", "................"],
        "gateway": ["................", "................", ".llllllllllllll.", "..rrrrrrrrrrrr..", "...rr......rr...", "...rr......rr...", "..lrrllllllrrl..", "...rr......rr...", "...rr......rr...", "...rr......rr...", "...rr......rr...", "...rr......rr...", "..lrrl....lrrl..", "..llll....llll..", "................", "................"],
        "rainbow": ["................", "................", ".....rrrrrr.....", "...rryyyyyyrr...", "..ryyggggggyyr..", ".ryggbbbbbbggyr.", ".rygbb....bbgyr.", "rygb........bgyr", "rygb........bgyr", "rygb........bgyr", "wwww........wwww", "wwww........wwww", "................", "................", "................", "................"],
        "clock": ["................", ".....llllll.....", "...llccccccll...", "..lcccccccccl...", "..lccclcccccl...", ".lcccclccccccl..", ".lcccclccccccl..", ".lccccllllcccl..", ".lcccccccccccl..", ".lcccccccccccl..", "..lcccccccccl...", "..lcccccccccl...", "...llccccccll...", ".....llllll.....", "................", "................"],
        "chart": ["................", "................", "...........lll..", "...........lyl..", ".......lll.lyl..", ".......lgl.lyl..", "...lll.lgl.lyl..", "...lbl.lgl.lyl..", "...lbl.lgl.lyl..", "...lbl.lgl.lyl..", "...lbl.lgl.lyl..", "...lbl.lgl.lyl..", "...lll.lll.lll..", "..lllllllllllll.", "................", "................"],
        "gear": ["................", "......llll......", "......laal......", "..lllllaalllll..", "..laaaaaaaaaaal.", "...laallllaaal..", ".lllaal..laalll.", ".laaaal..laaaal.", ".laaaal..laaaal.", ".lllaal..laalll.", "...laallllaaal..", "..laaaaaaaaaaal.", "..lllllaalllll..", "......laal......", "......llll......", "................"]
    ]

    static func draw(_ id: String, context: GraphicsContext, at origin: CGPoint, pixel: CGFloat) {
        let rows = sprites[id] ?? sprites["egg"]!
        for (y, row) in rows.enumerated() {
            for (x, character) in row.enumerated() {
                guard let color = palette[character] else { continue }
                let rect = CGRect(x: origin.x + CGFloat(x) * pixel, y: origin.y + CGFloat(y) * pixel, width: pixel, height: pixel)
                context.fill(Path(rect), with: .color(color), style: FillStyle(antialiased: false))
            }
        }
    }
}

struct PixelSprite: View {
    var id: String
    var body: some View {
        Canvas { context, size in
            let pixel = min(size.width, size.height) / 16
            PixelArt.draw(id, context: context, at: CGPoint(x: (size.width - pixel * 16) / 2, y: (size.height - pixel * 16) / 2), pixel: pixel)
        }.accessibilityHidden(true)
    }
}

struct IslandScene: View {
    var decorations: [String] = []
    var creatures = 0
    var compact = false
    var milestones: [Int] = []
    var body: some View {
        Canvas { context, size in
            var c = context
            let scale = min(size.width / 192, size.height / 112)
            c.translateBy(x: (size.width - 192 * scale) / 2, y: (size.height - 112 * scale) / 2)
            c.scaleBy(x: scale, y: scale)
            func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: UInt32) {
                c.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(Color(hex: color)), style: FillStyle(antialiased: false))
            }
            func polygon(_ points: [CGPoint], _ color: UInt32, offset: CGFloat = 0) {
                var path = Path()
                path.addLines(points.map { CGPoint(x: $0.x, y: $0.y + offset) }); path.closeSubpath()
                c.fill(path, with: .color(Color(hex: color)), style: FillStyle(antialiased: false))
            }
            rect(0, 0, 192, 112, 0xA9D3D1)
            for i in 0..<28 {
                let x = CGFloat((i * 43 + 7) % 183)
                let y = CGFloat((i * 19 + 11) % 105)
                rect(x, y, i % 3 == 0 ? 7 : 3, 1, i % 2 == 0 ? 0xC2E0D8 : 0x94C4C5)
            }
            // Small stepped clouds, distant gulls, and an off-centre sun.
            rect(146, 13, 10, 10, 0xF7E4AA)
            rect(14, 21, 25, 4, 0xD9EAE0); rect(20, 17, 13, 4, 0xD9EAE0)
            rect(163, 37, 16, 3, 0xD9EAE0); rect(167, 34, 8, 3, 0xD9EAE0)
            rect(99, 18, 3, 1, 0x6E9EA0); rect(102, 19, 2, 1, 0x6E9EA0); rect(104, 18, 3, 1, 0x6E9EA0)
            let shore: [CGPoint] = [(66,36),(106,36),(106,39),(126,39),(126,43),(143,43),(143,48),(153,48),(153,55),(162,55),(162,72),(156,72),(156,80),(143,80),(143,85),(125,85),(125,89),(74,89),(74,86),(53,86),(53,82),(38,82),(38,76),(29,76),(29,58),(36,58),(36,50),(48,50),(48,43),(66,43)].map { CGPoint(x: $0.0, y: $0.1) }
            polygon(shore, 0x87BAB7, offset: 11)
            polygon(shore, 0xB18C5E, offset: 6)
            polygon(shore, 0xDBC18B, offset: 3)
            polygon(shore, 0xF0D9A1)
            let grass: [CGPoint] = [(67,40),(106,40),(106,43),(125,43),(125,47),(141,47),(141,53),(151,53),(151,60),(155,60),(155,69),(149,69),(149,76),(139,76),(139,80),(123,80),(123,83),(74,83),(74,80),(55,80),(55,76),(43,76),(43,70),(37,70),(37,59),(43,59),(43,54),(54,54),(54,48),(67,48)].map { CGPoint(x: $0.0, y: $0.1) }
            polygon(grass, 0x80AA74)
            // Deliberate patches, grass tufts and a sandy track.
            rect(74, 43, 30, 5, 0x92B87C); rect(48, 61, 23, 8, 0x92B87C)
            rect(113, 69, 27, 5, 0x729E6C)
            rect(90, 75, 10, 10, 0xD7C896); rect(96, 69, 12, 9, 0xD7C896); rect(104, 61, 13, 10, 0xD7C896)
            for (x, y) in [(53,69),(78,72),(131,59),(119,77),(87,51),(147,65)] {
                rect(CGFloat(x), CGFloat(y), 1, 2, 0x4F825C); rect(CGFloat(x + 2), CGFloat(y - 1), 1, 3, 0x4F825C)
            }
            // The starting camp is a tent, distinct from the purchasable cottage.
            PixelArt.draw("pine", context: c, at: CGPoint(x: 57, y: 29), pixel: 1.7)
            PixelArt.draw("pine", context: c, at: CGPoint(x: 77, y: 25), pixel: 1.9)
            polygon([(113,45),(125,61),(102,61)].map { CGPoint(x: $0.0, y: $0.1) }, 0xE8BA72)
            polygon([(113,45),(113,61),(102,61)].map { CGPoint(x: $0.0, y: $0.1) }, 0xFFF0BE)
            rect(111, 54, 4, 7, 0x7A6655); rect(100, 62, 27, 2, 0x6B8C61)
            let positions: [CGPoint] = [CGPoint(x: 40, y: 53), CGPoint(x: 120, y: 53), CGPoint(x: 82, y: 65), CGPoint(x: 65, y: 57), CGPoint(x: 126, y: 38), CGPoint(x: 105, y: 64)]
            for (index, id) in decorations.prefix(6).enumerated() {
                PixelArt.draw(id, context: c, at: positions[index], pixel: 1.1)
            }
            for (index, creature) in Catalog.creatures.prefix(min(creatures, 6)).enumerated() {
                PixelArt.draw(creature.id, context: c, at: CGPoint(x: 51 + index * 14, y: 72 + (index % 2) * 3), pixel: 0.8)
            }
            for (index, milestone) in milestones.enumerated() {
                let x = CGFloat(42 + index * 23)
                if milestone == 30 {
                    for (j, color) in [UInt32(0xBE7053),0xE9BA67,0xB9D78A,0x78B9C4].enumerated() {
                        rect(128, CGFloat(14 + j * 2), 27, 2, color)
                    }
                } else if milestone == 14 {
                    rect(x, 48, 2, 14, 0xBE7053); rect(x + 12, 48, 2, 14, 0xBE7053); rect(x - 2, 47, 18, 3, 0xBE7053)
                } else {
                    PixelArt.draw(milestone == 3 ? "flowers" : "lantern", context: c, at: CGPoint(x: x, y: 48), pixel: 0.8)
                }
            }
        }
        .background(IsleTheme.water)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your island campsite with \(decorations.count) decorations and \(min(creatures, 6)) creatures")
    }
}
