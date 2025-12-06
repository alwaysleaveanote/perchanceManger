import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var promptToInject: String?
    @Binding var askToLogIframes: Bool
    @Binding var jsLog: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        let request = URLRequest(url: url)
        webView.load(request)

        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // New prompt → inject into page
        if let prompt = promptToInject {
            injectPrompt(prompt, into: uiView)
            DispatchQueue.main.async {
                self.promptToInject = nil
            }
        }

        // Ask to log iframe URLs
        if askToLogIframes {
            logIframeURLs(in: uiView)
            DispatchQueue.main.async {
                self.askToLogIframes = false
            }
        }
    }

    // MARK: - JS: inject prompt into "description" textarea

    private func injectPrompt(_ prompt: String, into webView: WKWebView) {
        let escaped = prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")

        let js = """
        (function() {
          const text = '\(escaped)';
          let crossOriginCount = 0;

          function setPromptInDoc(doc, label) {
            if (!doc) return null;
            const box = doc.querySelector('textarea.paragraph-input[data-name="description"]');
            if (box) {
              box.value = text;
              box.dispatchEvent(new Event('input', { bubbles: true }));
              return 'set in ' + label;
            }
            return null;
          }

          // 1) Try main document
          let msg = setPromptInDoc(document, 'main document');
          if (msg) return msg;

          // 2) Try iframes
          const iframes = document.querySelectorAll('iframe');
          for (const frame of iframes) {
            try {
              const doc = frame.contentDocument || frame.contentWindow.document;
              msg = setPromptInDoc(doc, 'iframe (same origin)');
              if (msg) return msg;
            } catch (e) {
              crossOriginCount++;
            }
          }

          if (crossOriginCount > 0) {
            return 'no matching textarea found; crossOriginIframes=' + crossOriginCount;
          } else if (iframes.length > 0) {
            return 'no matching textarea found; iframesPresent=' + iframes.length + ', selectorMismatchOrShadowDOM';
          } else {
            return 'no matching textarea found; no iframes, selectorMismatchOrNotRenderedYet';
          }
        })();
        """

        webView.evaluateJavaScript(js) { result, error in
            var newLogEntry = "\n--- JS Injection ---\nPrompt: \(prompt)\n"

            if let error = error {
                newLogEntry += "Error: \(error.localizedDescription)\n"
            } else if let result = result {
                newLogEntry += "Result: \(result)\n"
            } else {
                newLogEntry += "Result: (no result value)\n"
            }

            DispatchQueue.main.async {
                self.jsLog.append(newLogEntry)
            }
        }
    }

    // MARK: - JS: log iframe URLs

    private func logIframeURLs(in webView: WKWebView) {
        let js = """
        (function() {
          const iframes = Array.from(document.querySelectorAll('iframe'));
          return iframes.map((f, i) => i + ': ' + f.src);
        })();
        """

        webView.evaluateJavaScript(js) { result, error in
            var newLogEntry = "\n--- Iframe URLs ---\n"

            if let error = error {
                newLogEntry += "Error: \(error.localizedDescription)\n"
            } else if let urls = result as? [String] {
                if urls.isEmpty {
                    newLogEntry += "(no iframes found)\n"
                } else {
                    newLogEntry += urls.joined(separator: "\n") + "\n"
                    newLogEntry += "Copy one of these URLs and try loading it directly in your WebView if you want to control that frame’s DOM.\n"
                }
            } else {
                newLogEntry += "Result: \(String(describing: result))\n"
            }

            DispatchQueue.main.async {
                self.jsLog.append(newLogEntry)
            }
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        weak var webView: WKWebView?

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.jsLog.append("\nPage finished loading: \(self.parent.url.absoluteString)\n")
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.jsLog.append("\nNavigation failed: \(error.localizedDescription)\n")
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.jsLog.append("\nProvisional navigation failed: \(error.localizedDescription)\n")
            }
        }
    }
}
