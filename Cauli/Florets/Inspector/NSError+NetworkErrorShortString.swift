//
//  Copyright (c) 2018 cauli.works
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

extension NSError {
    // swiftlint:disable identifier_name
    var cauli_networkErrorShortString: String {
        guard let error = CFNetworkErrors(rawValue: Int32(code)) else {
            return "ERR"
        }
        switch error {
        case .cfHostErrorHostNotFound, .cfurlErrorCannotFindHost:
            return "Host not found"
        case .cfHostErrorUnknown, .cfurlErrorUnknown, .cfNetServiceErrorUnknown:
            return "Unknown error"
        case .cfftpErrorUnexpectedStatusCode:
            return "Unexpected status code"
        case .cfErrorHTTPAuthenticationTypeUnsupported:
            return "Unsupported auth type"
        case .cfErrorHTTPBadCredentials:
            return "Bad credentials"
        case .cfErrorHTTPConnectionLost, .cfurlErrorNetworkConnectionLost:
            return "Connection lost"
        case .cfErrorHTTPParseFailure:
            return "Parse failure"
        case .cfErrorHTTPRedirectionLoopDetected:
            return "Redirect loop"
        case .cfurlErrorBadURL, .cfErrorHTTPBadURL:
            return "Bad URL"
        case .cfErrorHTTPProxyConnectionFailure, .cfErrorHTTPSProxyConnectionFailure:
            return "Proxy connection failure"
        case .cfErrorHTTPBadProxyCredentials:
            return "Bad proxy credentials"
        case .cfErrorPACFileError:
            return "Proxy config error"
        case .cfErrorPACFileAuth:
            return "Proxy auth failure"
        case .cfurlErrorUnsupportedURL:
            return "Unsupported URL"
        case .cfurlErrorCannotConnectToHost:
            return "Cannot connect to host"
        case .cfurlErrorDNSLookupFailed:
            return "DNS lookup failed"
        case .cfurlErrorHTTPTooManyRedirects:
            return "Too many redirects"
        case .cfurlErrorResourceUnavailable:
            return "Resource unavailable"
        case .cfurlErrorNotConnectedToInternet:
            return "Offline"
        case .cfurlErrorRedirectToNonExistentLocation:
            return "Failed redirect"
        case .cfurlErrorBadServerResponse:
            return "Bad server response"
        case .cfurlErrorUserCancelledAuthentication:
            return "Auth cancelled"
        case .cfurlErrorUserAuthenticationRequired:
            return "Auth required"
        case .cfurlErrorTimedOut, .cfNetServiceErrorTimeout:
            return "Timeout"
        case .cfsocksErrorUnknownClientVersion:
            return "Unknown client version"
        case .cfsocksErrorUnsupportedServerVersion:
            return "Unsupported server version"
        case .cfsocks4ErrorRequestFailed:
            return "Request failed"
        case .cfsocks4ErrorIdentdFailed:
            return "Ident failed"
        case .cfsocks4ErrorIdConflict:
            return "ID conflict"
        case .cfsocks4ErrorUnknownStatusCode:
            return "Unknown status code"
        case .cfsocks5ErrorBadState:
            return "Bad state"
        case .cfsocks5ErrorBadResponseAddr:
            return "Bad response address"
        case .cfsocks5ErrorBadCredentials:
            return "Bad credentials"
        case .cfsocks5ErrorUnsupportedNegotiationMethod:
            return "Unsupported negotiation method"
        case .cfsocks5ErrorNoAcceptableMethod:
            return "No acceptable method"
        case .cfStreamErrorHTTPSProxyFailureUnexpectedResponseToCONNECTMethod:
            return "HTTPS unexpected connect response"
        case .cfurlErrorBackgroundSessionInUseByAnotherProcess:
            return "Background session in use"
        case .cfurlErrorBackgroundSessionWasDisconnected:
            return "Background session disconnected"
        case .cfurlErrorCancelled:
            return "Cancelled"
        case .cfurlErrorZeroByteResource:
            return "Zero byte resource"
        case .cfurlErrorCannotDecodeRawData:
            return "Cannot decode raw data"
        case .cfurlErrorCannotDecodeContentData:
            return "Cannot decode content data"
        case .cfurlErrorCannotParseResponse:
            return "Cannot parse response"
        case .cfurlErrorInternationalRoamingOff:
            return "Roaming off"
        case .cfurlErrorCallIsActive:
            return "Call is active"
        case .cfurlErrorDataNotAllowed:
            return "Data not allowed"
        case .cfurlErrorRequestBodyStreamExhausted:
            return "Req body stream exhausted"
        case .cfurlErrorAppTransportSecurityRequiresSecureConnection:
            return "ATS requires secure connection"
        case .cfurlErrorFileDoesNotExist:
            return "File does not exist"
        case .cfurlErrorFileIsDirectory:
            return "File is directory"
        case .cfurlErrorNoPermissionsToReadFile:
            return "No read permission"
        case .cfurlErrorDataLengthExceedsMaximum:
            return "Data length exceed max"
        case .cfurlErrorFileOutsideSafeArea:
            return "File outside safe area"
        case .cfurlErrorSecureConnectionFailed:
            return "Secure connection failed"
        case .cfurlErrorServerCertificateHasBadDate:
            return "Bad server cert date"
        case .cfurlErrorServerCertificateUntrusted:
            return "Untrusted server cert"
        case .cfurlErrorServerCertificateHasUnknownRoot:
            return "Unknown server cert root"
        case .cfurlErrorServerCertificateNotYetValid:
            return "Server cert not yet valid"
        case .cfurlErrorClientCertificateRejected:
            return "Client cert rejected"
        case .cfurlErrorClientCertificateRequired:
            return "Client cert required"
        case .cfurlErrorCannotLoadFromNetwork:
            return "Cannot load from network"
        case .cfurlErrorCannotCreateFile:
            return "Cannot create file"
        case .cfurlErrorCannotOpenFile:
            return "Cannot open file"
        case .cfurlErrorCannotCloseFile:
            return "Cannot close file"
        case .cfurlErrorCannotWriteToFile:
            return "Cannot write to file"
        case .cfurlErrorCannotRemoveFile:
            return "Cannot remove file"
        case .cfurlErrorCannotMoveFile:
            return "Cannot move file"
        case .cfurlErrorDownloadDecodingFailedMidStream:
            return "Download decode failed mid stream"
        case .cfurlErrorDownloadDecodingFailedToComplete:
            return "Download decode failed to complete"
        case .cfhttpCookieCannotParseCookieFile:
            return "Cannot parse cookie file"
        case .cfNetServiceErrorCollision:
            return "Collision"
        case .cfNetServiceErrorNotFound:
            return "Not found"
        case .cfNetServiceErrorInProgress:
            return "In Progress"
        case .cfNetServiceErrorBadArgument:
            return "Bad Argument"
        case .cfNetServiceErrorCancel:
            return "Cancel"
        case .cfNetServiceErrorInvalid:
            return "Invalid"
        case .cfNetServiceErrorDNSServiceFailure:
            return "DNS service failure"
        default:
            return "ERR"
        }
    }
    // swiftlint:enable identifier_name
}
