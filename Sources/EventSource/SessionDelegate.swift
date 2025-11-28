//
//  SessionDelegate.swift
//  EventSource
//
//  Copyright © 2023 Firdavs Khaydarov (Recouse). All rights reserved.
//  Licensed under the MIT License.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

final class SessionDelegate: NSObject, URLSessionDataDelegate {
    enum Event: Sendable {
        case didCompleteWithError(Error?)
        case didReceiveResponse(URLResponse, @Sendable (URLSession.ResponseDisposition) -> Void)
        case didReceiveData(Data)
    }

    private let internalStream = AsyncStream<Event>.makeStream()

    // wangqi 2025-11-28: Add SSL bypass flag for proxy debugging
    var bypassSSLValidation: Bool = false

    var eventStream: AsyncStream<Event> { internalStream.stream }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        internalStream.continuation.yield(.didCompleteWithError(error))
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @Sendable @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        internalStream.continuation.yield(.didReceiveResponse(response, completionHandler))
    }

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        internalStream.continuation.yield(.didReceiveData(data))
    }

    // wangqi 2025-11-28: Add SSL challenge handling for proxy debugging (mitmproxy, Charles)
    // NOTE: This does NOT work on Mac Catalyst/iOS due to CFNetwork-level "strict TLS Trust evaluation".
    // The delegate is called and returns .useCredential, but the connection still fails.
    // See helper/docs/claude_api_tls_proxy_issue.md for details.
    // To debug with mitmproxy, install the CA certificate on the device instead.
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if bypassSSLValidation,
           challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    // wangqi 2025-11-28: Add task-level SSL challenge handling
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if bypassSSLValidation,
           challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
