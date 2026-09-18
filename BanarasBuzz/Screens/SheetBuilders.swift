// Ported from the Android app's ui/screens/SheetBuilders.kt.
import Foundation

func templeSheetFor(_ t: TempleItem, state: AppState) -> SheetContent {
    let lang = state.lang
    return SheetContent(
        image: t.image.of(lang), kicker: t.hours.of(lang), meta: t.wait.of(lang),
        title: t.name.of(lang), body1: t.body1.of(lang), body2: t.body2.of(lang),
        actionLabel: lang == .hi ? "रास्ता देखें" : "Get directions"
    ) {
        state.mapQuery = "\(t.name.en), Varanasi"
        state.sheet = nil
    }
}

func ghatSheetFor(_ g: GhatItem, state: AppState) -> SheetContent {
    let lang = state.lang
    return SheetContent(
        image: g.image.of(lang), kicker: g.crowd.of(lang), meta: g.walk.of(lang),
        title: g.name.of(lang), body1: g.body1.of(lang), body2: g.body2.of(lang),
        actionLabel: lang == .hi ? "रास्ता देखें" : "Get directions"
    ) {
        state.mapQuery = "\(g.name.en), Varanasi"
        state.sheet = nil
    }
}
