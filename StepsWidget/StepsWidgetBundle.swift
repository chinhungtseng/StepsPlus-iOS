//
//  StepsWidgetBundle.swift
//  StepsWidget
//
//  Created by Chin-Hung Tseng on 2026/7/17.
//

import WidgetKit
import SwiftUI

@main
struct StepsWidgetBundle: WidgetBundle {
    var body: some Widget {
        StepsWidget()
        StepsWidgetControl()
        StepsWidgetLiveActivity()
    }
}
