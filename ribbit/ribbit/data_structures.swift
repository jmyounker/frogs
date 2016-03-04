//
//  data_structures.swift
//  ribbit
//
//  Created by Jeff Younker on 2/14/16.
//  Copyright © 2016 The Blobshop. All rights reserved.
//

import Foundation

class Queue<X> {
    var items : Array<X> = Array<X>()
    
    init() {
    }
    
    func isEmpty() -> Bool {
        return items.count == 0;
    }
    
    func push(x : X) {
        items.append(x)
    }
    
    func pop() -> X {
        return items.removeFirst()
    }
    
    func peek() -> X {
        return items[items.count - 1]
    }
}

class Range<X> {
    let lower: X
    let upper: X
    
    init(lower: X, upper: X) {
        self.lower = lower
        self.upper = upper
    }
}

class Unit {
    let value: Float64;
    
    init(value: Float64) {
        assert(value >= 0)
        assert(value <= 1)
        self.value = value
    }
    
    func float64() -> Float64 {
        return value
    }
}

class Intensity : Unit {
}

class Volume : Unit {
}

class Probability : Unit {
}


func randProb() -> Probability {
    return Probability(value: Float64(rand())/Float64(RAND_MAX))
}

func choose<X>(choices: Array<X>, n: UInt32) -> Array<X> {
    var chosen = Array<X>();
    var chosenIndexes = Set<Int>()
    for var i : Int = 0; i < max(Int(n), choices.count); i++ {
        var j = random() % choices.count
        while chosenIndexes.contains(j) {
            j = random() % choices.count
        }
        chosenIndexes.insert(j)
        chosen.append(choices[j])
    }
    return chosen;
}

