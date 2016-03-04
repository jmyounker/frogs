//
//  main.swift
//  ribbit
//
//  Created by Jeff Younker on 11/1/15.
//  Copyright © 2015 The Blobshop. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class ServerConfig {
    let port: UInt16
    let interval: UInt32
    
    init(port:UInt16, interval: UInt32) {
        self.port = port
        self.interval = interval
    }
}


func timeval_after(x:timeval, y:timeval) -> Bool {
    if x.tv_sec > y.tv_sec {
        return true
    }
    if x.tv_sec == y.tv_sec && x.tv_usec > y.tv_usec {
        return true
    }
    return false;
}

class Application {
    var feeds: Optional<[String: FeedAggregator]>
    var channels: Optional<[String: Channel]>
    var effects: Optional<[String: Effect]>
    var bindings: Optional<[Binding]>
    var playback: Optional<AudioPlayback>
    var config: Optional<ServerConfig>
    
    init() {
        feeds = [String: FeedAggregator]()
    }
    
    func main() {
        configure()
        UDPEventSource(feeds: feeds!).startServing()
        initAudio()
        // run()
        simulate()
    }
    
    func configure() {
        //        var config = readConfig("/etc/ribbit.conf")
        //        var feeds: Array<Feed> = buildFeeds(buildFeedDesc(config["feeds"]))
        //        var channels: Array<Channel> = buildChannels(buildChannelDesc(config["channels"]), feeds)
        //        var effects: Array<Effect> = buildEffects(buildEffectDesc(config["effects"]), channels)
        //        var bindings: Array<Binding> = buildBindings(buildBindingDesc(config["bindings"]), channels, effects)
        //        var server: ServerConfig = buildConfig(config["server"])
        feeds = ["mail": FeedAggregator(aggregator: SumAggregator())]
        channels = ["frogs": UpperBoundedChannel(f: feeds!["mail"]!, m: 20)]
        let v0 = FixedSampleChirp(azmith: 20, elevation: 0, distance: 3, samples: ["/Users/jeff/repos/progperday/20150413/audemio/Rana_clamitans.mp3"])
        let v1 = FixedSampleChirp(azmith: 90, elevation: 0, distance: 10, samples: ["/Users/jeff/repos/progperday/20150413/audemio/Rana_clamitans.mp3"])
        
        effects = ["frogs":
            ChorusEffect(
                frequency: Range<Probability>(lower: Probability(value: 0.5), upper:Probability(value: 0.8)),
                volume: Range<Volume>(lower: Volume(value: 0.4), upper: Volume(value: 0.9)),
                numberMin: 1,
                population: [v0, v1])]
        bindings = [ Binding(c: channels!["frogs"]!, e: effects!["frogs"]!)]
        config = ServerConfig(port: 5556, interval: 1)
    }
    
    func initAudio() {
        var voices = Array<Voice>()
        for (_, effect) in effects! {
            for voice in effect.voices() {
                voices.append(voice)
            }
        }
        playback = AudioPlayback()
        var sounds = Array<Sound>()
        for (i, voice) in voices.enumerate() {
            sounds.append(voice.createSound(playback!, busIndex: UInt32(i)))
        }
        assert(sounds.count < 64) // only 64 channels on the mixer
        playback!.begin(sounds)
    }

    func simulate() {
        var now:timeval = timeval(tv_sec: 0, tv_usec: 0)
        var prev:timeval = timeval(tv_sec: 0, tv_usec: 0)
        let f = feeds!["mail"]!
        while true {
            gettimeofday(&prev, nil)
            f.push(Event(volume: UInt64(rand() % Int32(20)), time: prev))
            sleep(1)
            gettimeofday(&now, nil)
            runEffects(now)
        }
    }
    
    func run() {
        var time:timeval = timeval(tv_sec: 0, tv_usec: 0)
        while true {
            gettimeofday(&time, nil)
            runEffects(time)
            sleep(config!.interval)
        }
    }
    
    func runEffects(time:timeval) {
        // Aggregate queued values into counts
        for (_, f) in self.feeds! {
            f.aggregateSince(time)
        }
        // Convert counts into intensities
        for (_, c) in self.channels! {
            c.calculateIntensity();
        }
        // Run the effect based on new intensities
        for b in self.bindings! {
            b.effect.run(b.channel.getIntensity());
        }
    }
}

// configurtion file
// {
//   "feeds": [
//      {
//          "name": "qps",
//          "aggregation": "sum()"
//      }
//   ],
//   "channels": [
//      {
//          "name": "frogs",
//          "feed": "qps",
//          "normalize": "max(2000)"
//      }
//   ],
//   "effects": [
//      {
//          "name": "frogs",
//          "type": "chorus",
//          "volume": [0.1, 0.9],  # [0, 1]
//          "frequency": ["1/10s", "1/2s"],  # voices/sec
//          "population": [
//             {
//                "type": "annular",
//                "count": 40,
//                "distance": [2, 60], # meters
//                "height": 0,
//             }
//          ]
//      }
//   ],
//   "bindings": [
//      {
//          "channel": "frogs",
//          "effect": "frogs",
//      }
//   ]
// }

class UDPEventSource: NSObject, GCDAsyncUdpSocketDelegate {
    let IP = "127.0.0.1"
    let PORT:UInt16 = 5556
    var socket:GCDAsyncUdpSocket!
    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
    var feeds: [String: FeedAggregator]
    
    init(feeds: Dictionary<String, FeedAggregator>){
        self.feeds = feeds
        super.init()
    }
    
    func startServing() {
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_global_queue(priority, 0))
        do {
            try socket.bindToPort(PORT)
            try socket.beginReceiving()
        } catch _ {
            print("encountered error")
            return
        }
    }
    
    func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!,
        withFilterContext filterContext: AnyObject!) {
            guard let events = parseEvents(data) else {
                return
            }
            for e in events {
                guard let f = feeds[e.name] else {
                    continue
                }
                f.push(e.event)
            }
    }

    func parseEvents(packet: NSData) -> Optional<Array<FeedEvent>> {
        // TODO(jeff): Implement parsing
        return Array<FeedEvent>();
    }

    func writeSomething() {
        let text = "some text" //just a text
        let path = "/tmp/foo.txt"
        do {
            try text.writeToFile(path, atomically: false, encoding: NSUTF8StringEncoding)
        } catch {
            /* error handling here */
        }
    }
}

class EffectsEngine {
    let feeds: Array<FeedAggregator>;
    let channels: Array<Channel>;
    let bindings: Array<Binding>;
    
    init(feeds: Array<FeedAggregator>, channels: Array<Channel>, bindings: Array<Binding>) {
        self.feeds = feeds;
        self.channels = channels
        self.bindings = bindings
    }
    
}

struct FeedEvent {
    let name: String
    let event: Event
    
    init(name: String, event: Event) {
        self.name = name
        self.event = event
    }
}

struct Event {
    let volume: UInt64
    let time: timeval
    
    init(volume: UInt64, time: timeval) {
        self.volume = volume
        self.time = time
    }
}

class ChannelSet {
    var channels = [String: FeedAggregator]()
    
    func push(channel: String, e: Event) {
        self.channels[channel]!.push(e)
    }
}

// how to look up time
// var time:timeval = timeval(tv_sec: 0, tv_usec: 0)
// gettimeofday(&time, nil)
/// Use an NSLocking object as a mutex for a critical section of code

protocol Feed {
    func getCounter() -> UInt64
    func aggregateSince(t: timeval)
}

class FeedAggregator : Feed {
    let lock = NSRecursiveLock()
    var queue: Queue<Event> = Queue<Event>()
    var aggregator: Aggregator
    var counter: UInt64 = 0
    
    init(aggregator: Aggregator) {
        self.aggregator = aggregator
    }

    func aggregateSince(t: timeval) {
        setCounter(aggregator.sum(eventsSince(t)))
    }

    func push(e: Event) {
        lock.lock()
        defer { self.lock.unlock() }
        queue.push(e)
    }

    func getCounter() -> UInt64 {
        lock.lock()
        defer { self.lock.unlock() }
        return counter;
    }

    func setCounter(i: UInt64) {
        lock.lock()
        defer { self.lock.unlock() }
        counter = i
    }

    func eventsSince(t: timeval) -> Array<Event> {
        var events = Array<Event>()
        if queue.isEmpty() {
            return events
        }
        lock.lock()
        defer { self.lock.unlock() }
        while !queue.isEmpty() && timeval_after(t, y:queue.peek().time) {
            events.append(self.queue.pop())
        }
        return events;
    }
}

protocol Aggregator {
    func sum(events: Array<Event>) -> UInt64
}

class SumAggregator: Aggregator {
    var previous = 0
    
    func sum(events: Array<Event>) -> UInt64 {
        var s: UInt64 = 0;
        for e in events {
            s += e.volume
        }
        return s;
    }
}

protocol Channel {
    func setCounter(counter: UInt64);
    func getIntensity() -> Intensity;
    func calculateIntensity();
}

class UpperBoundedChannel : Channel {
    let feed: Feed
    let upper: UInt64
    var intensity: Intensity = Intensity(value: 0.0)
    
    init(f: Feed, m: UInt64) {
        self.feed = f
        self.upper = m
    }

    func calculateIntensity() {
        setCounter(feed.getCounter())
    }

    func setCounter(counter: UInt64) {
        self.intensity = Intensity(value: Float64(min(counter, self.upper)) / Float64(self.upper));
    }

    func getIntensity() -> Intensity {
        return self.intensity;
    }
}

protocol Effect {
    func run(intensity: Intensity)
    func voices() -> Array<Voice>
}

class ChorusEffect : Effect {
    let frequency: Range<Probability>
    let volume: Range<Volume>
    let numberMin: UInt32
    let population: Array<Voice>

    init(frequency: Range<Probability>,
        volume: Range<Volume>,
        numberMin: UInt32,
        population: Array<Voice>) {
            self.frequency = frequency
            self.volume = volume
            self.numberMin = numberMin
            self.population = population
    }

    func run(intensity: Intensity) {
        // Can I replaces this with an existing partition() operation?
        var playing = Array<Voice>()
        var not_playing = Array<Voice>()
        for v in population {
            if v.isPlaying() {
                playing.append(v);
            } else {
                not_playing.append(v)
            }
        }
        let nd : UInt32 = numberMin + UInt32(ceil(intensity.float64() * Float64(UInt32(population.count) - self.numberMin)));
        if nd <= UInt32(playing.count) {
            return
        }
        let px = Probability(value: frequency.lower.float64() + intensity.float64() * (frequency.upper.float64() - frequency.lower.float64()))
        let ic = Intensity(value: volume.lower.float64() + intensity.float64() * (volume.upper.float64() - volume.lower.float64()))
        for v: Voice in choose(not_playing, n: nd - UInt32(playing.count)) {
            if randProb().float64() <= px.float64() {
                v.play(ic)
            }
        }
    }
    
    func voices() -> Array<Voice> {
        return self.population
    }
}

class WooshEffect : Effect {
    let volume: Range<Volume>
    let population: Array<Voice>
    
    init(volume: Range<Volume>,
        population: Array<Voice>) {
            self.volume = volume
            self.population = population
    }
    
    func run(intensity: Intensity) {
        let ic = Intensity(value: volume.lower.float64() + intensity.float64() * (volume.upper.float64() - volume.lower.float64()))
        for v: Voice in population {
            v.play(ic)
        }
    }

    func voices() -> Array<Voice> {
        return self.population
    }
}

protocol Population {
    func getVoices() -> Array<Voice>
}

protocol Voice {
    func isPlaying() -> Bool
    func play(intensity: Intensity)
    func createSound(playback: AudioPlayback, busIndex: UInt32) -> Sound
}

class FixedSampleChirp : Voice {
    let azmith: Float64
    let elevation: Float64
    let distance: Float64
    let samples: Array<String>
    var sound: Optional<Sound>
    var playback: Optional<AudioPlayback>
    
    init(azmith: Float64,
        elevation: Float64,
        distance: Float64,
        samples: Array<String>) {
            assert(samples.count > 0)
            self.azmith = azmith
            self.elevation = elevation
            self.distance = distance
            self.samples = samples
    }
    
    func isPlaying() -> Bool {
        return false;
    }
    
    func play(intensity: Intensity) {
        if isPlaying() {
            return;
        }
        setVolume(playback!.mixerAu, busIndex: sound!.busIndex, v: Volume(value: intensity.float64()))  
        self.sound!.play();
    }

    func createSound(playback: AudioPlayback, busIndex: UInt32) -> Sound {
        self.playback = playback
        self.sound = Sound(fileName: self.samples[0], busIndex: busIndex)
        return self.sound!
    }
}

class RandomSampleWoosh : Voice {
    let azmith: Float64
    let elevation: Float64
    let distance: Float64
    let samples: Array<String>
    var sound: Optional<Sound>
    var playback: Optional<AudioPlayback>
    
    init(azmith: Float64,
        elevation: Float64,
        distance: Float64,
        samples: Array<String>) {
            assert(samples.count > 0)
            self.azmith = azmith
            self.elevation = elevation
            self.distance = distance
            self.samples = samples
    }
    
    func isPlaying() -> Bool {
        return false;
    }
    
    func play(intensity: Intensity) {
        setVolume(playback!.mixerAu, busIndex: sound!.busIndex, v: Volume(value: intensity.float64()))
        if !isPlaying() {
            self.sound!.play();
        }
    }

    func createSound(playback: AudioPlayback, busIndex: UInt32) -> Sound {
        self.playback = playback
        self.sound = Sound(fileName: self.samples[0], busIndex: busIndex)
        return self.sound!
    }
}


class Binding {
    let channel: Channel;
    let effect: Effect;
    
    init(c: Channel, e: Effect) {
        self.channel = c
        self.effect = e;
    }
}

let app = Application()
print("starting...")
app.main()
print("ending...")
