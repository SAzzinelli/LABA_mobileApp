import WidgetKit
import SwiftUI

@main
struct LABAWidgetBundle: WidgetBundle {
    var body: some Widget {
        // 3 piccoli (uno per metrica)
        LABAExamsWidgetSmall()
        LABACFAWidgetSmall()
        LABAMediaWidgetSmall()
        // 1 medio combinato
        LABAWidget()
    }
}
