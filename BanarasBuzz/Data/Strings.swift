// Ported from the Android app's data/Strings.kt (bilingual UI copy).
import Foundation

struct Strings {
    let dateline: String
    let masthead: String
    let nextAarti: String
    let close: String
    let eventsTitle: String
    let eventsSub: String
    let noEvents: String
    let aartiTitle: String
    let aartiSub: String
    let darshan: String
    let ghatsTitle: String
    let ghatsSub: String
    let mapSlot: String
    let bazaarTitle: String
    let bazaarSub: String
    let postAd: String
    let alertsTitle: String
    let markRead: String
    let going: String
    let goingOn: String
    let save: String
    let saved: String
    let readFull: String
    let remindOn: String
    let tabs: [String]
    let feedFilters: [String]
    let eventFilters: [String]
    let eventFiltersLive: [String]
    let bazaarFilters: [String]
    let wd: [String]
    let liveEventsSub: String
    let openSource: String
    let panchangTitle: String
    let panchangSub: String
    let tithiLabel: String
    let nakshatraLabel: String
    let yogaLabel: String
    let karanaLabel: String
    let sunriseLabel: String
    let sunsetLabel: String
    let moonriseLabel: String
    let moonsetLabel: String
    let rahuKaalLabel: String
    let abhijitLabel: String
    let noPanchang: String
    let vratTyoharTitle: String
    let vratTyoharSub: String
    let vratLabel: String
    let tyoharLabel: String
    let bothLabel: String
    let noObservances: String
    let remindMe: String
}

let StringsEN = Strings(
    dateline: "Tue 25 Aug 2026", masthead: "Banaras Buzz", nextAarti: "Next Ganga Aarti", close: "Close",
    eventsTitle: "Events", eventsSub: "AUG 2026 · 34 LISTED THIS WEEK", noEvents: "Nothing listed yet for this day.",
    aartiTitle: "Aarti & Darshan", aartiSub: "TIMINGS UPDATED 06:10 TODAY", darshan: "Darshan status",
    ghatsTitle: "Ghats", ghatsSub: "84 GHATS · 6 KM RIVERFRONT", mapSlot: "map: riverfront strip",
    bazaarTitle: "Bazaar", bazaarSub: "212 LOCAL ADS · FREE TO POST", postAd: "Post an ad",
    alertsTitle: "Alerts", markRead: "Mark all read", going: "Going", goingOn: "You're going",
    save: "Save", saved: "Saved", readFull: "Read full story", remindOn: "Reminder set",
    tabs: ["Buzz", "Events", "Ghats", "Bazaar"],
    feedFilters: ["All", "City", "Temple", "Culture", "BHU"],
    eventFilters: ["All", "Music", "Temple", "Fair", "Talks"],
    eventFiltersLive: ["All", "Religious", "Cultural", "Tourism"],
    bazaarFilters: ["All", "Rooms", "Tutors", "Jobs", "Instruments", "Services"],
    wd: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
    liveEventsSub: "NEXT 7 DAYS · UPDATED DAILY", openSource: "View source",
    panchangTitle: "Today's Panchang", panchangSub: "VARANASI · UPDATED DAILY",
    tithiLabel: "Tithi", nakshatraLabel: "Nakshatra", yogaLabel: "Yoga", karanaLabel: "Karana",
    sunriseLabel: "Sunrise", sunsetLabel: "Sunset", moonriseLabel: "Moonrise", moonsetLabel: "Moonset",
    rahuKaalLabel: "Rahu Kaal", abhijitLabel: "Abhijit Muhurat", noPanchang: "Panchang not available right now.",
    vratTyoharTitle: "Vrat & Tyohar", vratTyoharSub: "NEXT 30 DAYS", vratLabel: "Vrat", tyoharLabel: "Tyohar",
    bothLabel: "Vrat & Tyohar", noObservances: "Nothing listed for the coming days.", remindMe: "Remind me"
)

let StringsHI = Strings(
    dateline: "मंगल २५ अगस्त २०२६", masthead: "बनारस बज़", nextAarti: "अगली गंगा आरती", close: "बंद करें",
    eventsTitle: "आयोजन", eventsSub: "अगस्त २०२६ · इस सप्ताह ३४ आयोजन", noEvents: "इस दिन के लिए अभी कुछ दर्ज नहीं है।",
    aartiTitle: "आरती व दर्शन", aartiSub: "समय आज ०६:१० पर अद्यतन", darshan: "दर्शन स्थिति",
    ghatsTitle: "घाट", ghatsSub: "८४ घाट · ६ किमी तट", mapSlot: "नक्शा: तट पट्टी",
    bazaarTitle: "बाज़ार", bazaarSub: "२१२ स्थानीय विज्ञापन · निःशुल्क", postAd: "विज्ञापन दें",
    alertsTitle: "सूचनाएँ", markRead: "सभी पढ़ा हुआ", going: "जाऊँगा", goingOn: "दर्ज हो गया",
    save: "सहेजें", saved: "सहेजा", readFull: "पूरी खबर पढ़ें", remindOn: "याद दिलाया जाएगा",
    tabs: ["बज़", "आयोजन", "घाट", "बाज़ार"],
    feedFilters: ["सभी", "शहर", "मंदिर", "संस्कृति", "बीएचयू"],
    eventFilters: ["सभी", "संगीत", "मंदिर", "मेला", "व्याख्यान"],
    eventFiltersLive: ["सभी", "Religious", "Cultural", "Tourism"],
    bazaarFilters: ["सभी", "कमरे", "शिक्षक", "नौकरी", "वाद्य", "सेवाएँ"],
    wd: ["सोम", "मंगल", "बुध", "गुरु", "शुक्र", "शनि", "रवि"],
    liveEventsSub: "अगले ७ दिन · प्रतिदिन अद्यतन", openSource: "स्रोत देखें",
    panchangTitle: "आज का पंचांग", panchangSub: "वाराणसी · प्रतिदिन अद्यतन",
    tithiLabel: "तिथि", nakshatraLabel: "नक्षत्र", yogaLabel: "योग", karanaLabel: "करण",
    sunriseLabel: "सूर्योदय", sunsetLabel: "सूर्यास्त", moonriseLabel: "चंद्रोदय", moonsetLabel: "चंद्रास्त",
    rahuKaalLabel: "राहु काल", abhijitLabel: "अभिजीत मुहूर्त", noPanchang: "अभी पंचांग उपलब्ध नहीं है।",
    vratTyoharTitle: "व्रत व त्योहार", vratTyoharSub: "अगले ३० दिन", vratLabel: "व्रत", tyoharLabel: "त्योहार",
    bothLabel: "व्रत व त्योहार", noObservances: "आने वाले दिनों के लिए कुछ दर्ज नहीं है।", remindMe: "याद दिलाएं"
)

func strings(for lang: Lang) -> Strings { lang == .hi ? StringsHI : StringsEN }
