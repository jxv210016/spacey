import Foundation

/// Watches a file for changes, surviving atomic rewrites.
///
/// macOS rewrites `com.apple.spaces.plist` by replacing the file (delete + create or
/// rename-over), so a plain `DispatchSource` on the original file descriptor stops
/// firing after the first change — the descriptor now points at a dead inode. This
/// watcher re-arms on the new inode after every event and debounces bursts.
///
/// `NSWorkspace.activeSpaceDidChangeNotification` catches *switching* spaces but
/// misses *structural* changes (adding/removing spaces, some fullscreen
/// transitions); the plist write is the reliable signal for those.
final class SpacesPlistWatcher {
    /// `~/Library/Preferences/com.apple.spaces.plist`.
    static var defaultURL: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Preferences/com.apple.spaces.plist")
    }

    private let url: URL
    private let debounce: DispatchTimeInterval
    private let queue: DispatchQueue
    private let onChange: () -> Void

    private var source: DispatchSourceFileSystemObject?
    private var pendingWork: DispatchWorkItem?
    private var retryWork: DispatchWorkItem?

    init(
        url: URL = SpacesPlistWatcher.defaultURL,
        debounce: DispatchTimeInterval = .milliseconds(150),
        queue: DispatchQueue = .main,
        onChange: @escaping () -> Void
    ) {
        self.url = url
        self.debounce = debounce
        self.queue = queue
        self.onChange = onChange
    }

    func start() {
        stop()
        arm()
    }

    func stop() {
        retryWork?.cancel()
        retryWork = nil
        pendingWork?.cancel()
        pendingWork = nil
        source?.cancel()
        source = nil
    }

    deinit {
        source?.cancel()
    }

    private func arm() {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else {
            // File may be momentarily absent during an atomic rewrite — retry.
            scheduleRetry()
            return
        }

        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.delete, .rename, .write, .extend],
            queue: queue
        )
        // Capture this source's own descriptor so re-arming can never close the new one.
        newSource.setEventHandler { [weak self] in self?.handleEvent() }
        newSource.setCancelHandler { close(descriptor) }
        source = newSource
        newSource.resume()
    }

    private func scheduleRetry() {
        retryWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, source == nil else { return }
            arm()
        }
        retryWork = work
        queue.asyncAfter(deadline: .now() + .milliseconds(300), execute: work)
    }

    private func handleEvent() {
        pendingWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            onChange()
            // Re-arm on the (possibly new) inode.
            source?.cancel()
            source = nil
            arm()
        }
        pendingWork = work
        queue.asyncAfter(deadline: .now() + debounce, execute: work)
    }
}
