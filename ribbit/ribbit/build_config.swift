//
//  build_config.swift
//  ribbit
//
//  Created by Jeff Younker on 2/14/16.
//  Copyright © 2016 The Blobshop. All rights reserved.
//

import Foundation
/**
func buildFeedAggregators(cfg: JSON) -> [String: FeedAggregator] {
    var cs = [String: FeedAggregator]()
    for ch in cfg {
        cs[ch["name"]] = FeedAggregator(buildAggregator(ch["aggregation"]))
    }
    return cs
}

func buildAggregator(expr: String) -> Aggregator {
    if aggregator == "sum(x)" {
        return SumAggregator();
    }
}

func buildChannel(cfg: JSON, feeds: [String: FeedAggregator]) -> [String: Channel] {
    var cs = [String: Channel]()
    for ch in cfg {
        let name = ch["name"]!
        let feed = feeds[ch["feed"]!]!
        let normExpr = ch["normalize"]!
        if let match = normExpr.rangeOfString("max\\((\\d+)\\)", options: .RegularExpressionSearch) {
    }
}
*/
