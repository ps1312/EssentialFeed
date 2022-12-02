import Foundation
import UIKit
import Combine

typealias AnyDispatchQueueScheduler = AnyScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>

extension AnyDispatchQueueScheduler {
    var immediateOnMainQueue: Self {
        DispatchQueue.mainQueueScheduler.eraseToAnyScheduler()
    }
}

extension Scheduler {
    func eraseToAnyScheduler() -> AnyScheduler<SchedulerTimeType, SchedulerOptions> {
        AnyScheduler(self)
    }
}

struct AnyScheduler<SchedulerTimeType : Strideable, SchedulerOptions> : Scheduler where SchedulerTimeType.Stride : SchedulerTimeIntervalConvertible {
    private let _now: () -> SchedulerTimeType
    private let _minimumTolerance: () -> SchedulerTimeType.Stride
    private let _afterIntervalTolerance: (SchedulerTimeType, SchedulerTimeType.Stride, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void) -> Cancellable
    private let _afterTolerance: (SchedulerTimeType, SchedulerTimeType.Stride, SchedulerOptions?, @escaping () -> Void) -> Void
    private let _schedule: (SchedulerOptions?, @escaping () -> Void) -> Void

    var now: SchedulerTimeType { _now() }
    var minimumTolerance: SchedulerTimeType.Stride { _minimumTolerance() }

    public init<S>(_ scheduler: S) where SchedulerTimeType == S.SchedulerTimeType, SchedulerOptions == S.SchedulerOptions, S : Scheduler {
        _now = { scheduler.now }
        _minimumTolerance = { scheduler.minimumTolerance }
        _afterIntervalTolerance = scheduler.schedule(after:interval:tolerance:options:_:)
        _afterTolerance = scheduler.schedule(after:tolerance:options:_:)
        _schedule = scheduler.schedule(options:_:)
    }

    func schedule(after date: SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> Cancellable {
        _afterIntervalTolerance(date, interval, tolerance, options, action)
    }

    func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _afterTolerance(date, tolerance, options, action)
    }

    func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
        _schedule(options, action)
    }
}
