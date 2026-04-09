/**
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/// reference https://www.raywenderlich.com/567-urlsession-tutorial-getting-started

import Foundation

// Downloads song snippets, and stores in local file.
// Allows cancel, pause, resume download.
class DownloadService {

    // SearchViewController creates downloadsSession
    var downloadsSession: URLSession!

    // Backing storage for active downloads. All access MUST go through
    // the helper methods below (download(for:), setDownload(_:for:),
    // removeDownload(for:), activeDownloadsSnapshot) which serialize via
    // `activeDownloadsLock`.
    //
    // This dictionary is touched from at least three different threads:
    //   - com.apple.NSURLSession-delegate (didWriteData, didFinishDownloadingTo)
    //   - DispatchQueue.global(qos: .background) (NetworkManager.download → startDownload)
    //   - DispatchQueue.main (NetworkManager.onProgressDownload closure iterating entries)
    // Unsynchronized mutation corrupts the Swift Dictionary storage and
    // crashes inside `_swift_release_dealloc` when a Download reference
    // is released with a broken refcount.
    private var activeDownloads: [URL: Download] = [:]
    private let activeDownloadsLock = NSLock()

    func download(for url: URL) -> Download? {
        activeDownloadsLock.lock()
        defer { activeDownloadsLock.unlock() }
        return activeDownloads[url]
    }

    func setDownload(_ download: Download?, for url: URL) {
        activeDownloadsLock.lock()
        defer { activeDownloadsLock.unlock() }
        activeDownloads[url] = download
    }

    @discardableResult
    func removeDownload(for url: URL) -> Download? {
        activeDownloadsLock.lock()
        defer { activeDownloadsLock.unlock() }
        let d = activeDownloads[url]
        activeDownloads[url] = nil
        return d
    }

    /// Returns a snapshot copy of the active downloads so callers can
    /// iterate without holding the lock or racing with mutations.
    func activeDownloadsSnapshot() -> [URL: Download] {
        activeDownloadsLock.lock()
        defer { activeDownloadsLock.unlock() }
        return activeDownloads
    }

    // MARK: - Download methods called by TrackCell delegate methods

    func startDownload(_ file: FileModel) {
        // 1
        let download = Download(file: file)
        // 2
        download.task = downloadsSession.downloadTask(with: file.url)
        // 3
        download.task!.resume()
        // 4
        download.isDownloading = true
        // 5
        setDownload(download, for: download.file.url)
    }

    func pauseDownload(_ file: FileModel) {
        guard let download = self.download(for: file.url) else { return }
        if download.isDownloading {
            download.task?.cancel(byProducingResumeData: { data in
                download.resumeData = data
            })
            download.isDownloading = false
        }
    }

    func cancelDownload(_ file: FileModel) {
        if let download = self.download(for: file.url) {
            download.task?.cancel()
            removeDownload(for: file.url)
        }
    }

    func resumeDownload(_ file: FileModel) {
        guard let download = self.download(for: file.url) else { return }
        if let resumeData = download.resumeData {
            download.task = downloadsSession.downloadTask(withResumeData: resumeData)
        } else {
            download.task = downloadsSession.downloadTask(with: download.file.url)
        }
        download.task!.resume()
        download.isDownloading = true
    }

}
