//
//  LABAWidgetBundle.swift
//  LABAWidget
//
//  Created by Simone Azzinelli on 13/08/25.
//

import WidgetKit
import SwiftUI

@main
struct LABAWidgetBundle: WidgetBundle {
    var body: some Widget {
        LABAWidget()
        LABAWidgetControl()
        LABAWidgetLiveActivity()
    }
}
