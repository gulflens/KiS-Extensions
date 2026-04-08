import SwiftUI
import WebKit

struct PortalBrowserView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var webView = WKWebView()
    @State private var isLoading = true
    @State private var isExtracting = false
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var currentURL = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var extractionSuccess = false
    @State private var rawJSON: String?
    @State private var showRawJSON = false

    private let portalURL = "https://emiratesgroup.sharepoint.com/sites/ccp/roster/Pages/Roster.aspx#"

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .frame(height: 2)
                }

                // Web view
                WebViewRepresentable(
                    webView: webView,
                    isLoading: $isLoading,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    currentURL: $currentURL
                )
            }
            .navigationTitle("Crew Portal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 12) {
                        Button("Close") { dismiss() }

                        Button {
                            webView.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(!canGoBack)

                        Button {
                            flushTemporaryData {
                                webView.reload()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        extractData()
                    } label: {
                        if isExtracting {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.horizontal, 8)
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.doc")
                                Text("Extract Data")
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)
                    .disabled(isExtracting)
                }
            }
            .alert("Extraction Error", isPresented: $showError) {
                Button("OK") {}
                if rawJSON != nil {
                    Button("Copy Raw Data") {
                        if let json = rawJSON {
                            UIPasteboard.general.string = json
                        }
                    }
                }
            } message: {
                Text(errorMessage ?? "Could not extract data from this page.")
            }
            .sheet(isPresented: $showRawJSON) {
                NavigationStack {
                    ScrollView {
                        Text(rawJSON ?? "")
                            .font(.system(size: 10, design: .monospaced))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .navigationTitle("Raw JSON")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { showRawJSON = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Copy") {
                                if let json = rawJSON {
                                    UIPasteboard.general.string = json
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            flushTemporaryData {
                if let url = URL(string: portalURL) {
                    webView.load(URLRequest(url: url))
                }
            }
        }
    }

    private func extractData() {
        isExtracting = true
        extractionSuccess = false
        rawJSON = nil

        let script = Self.scraperScript

        webView.evaluateJavaScript(script) { result, error in
            isExtracting = false

            if let error = error {
                errorMessage = "JavaScript error: \(error.localizedDescription)"
                showError = true
                return
            }

            guard let jsonString = result as? String, !jsonString.isEmpty, jsonString != "{}" else {
                errorMessage = "No data returned. Make sure you are on the crew portal and your trips are loaded."
                showError = true
                return
            }

            rawJSON = jsonString

            // Parse the JSON
            do {
                let trips = try JSONParser.parse(jsonString)
                if trips.isEmpty {
                    errorMessage = "No trips found in the extracted data. Tap 'Copy Raw Data' to inspect."
                    showError = true
                    return
                }
                extractionSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    appState.loadTrips(trips)
                    dismiss()
                }
            } catch {
                errorMessage = "Failed to parse extracted data: \(error.localizedDescription)\n\nTap 'Copy Raw Data' to share for debugging."
                showError = true
            }
        }
    }

    /// Clears caches, local/session storage, and non-login cookies so SharePoint
    /// doesn't serve stale data, while keeping Microsoft auth cookies intact.
    private func flushTemporaryData(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()

        // Domains whose cookies we preserve (Microsoft SSO / portal login)
        let loginDomains = ["login.microsoftonline.com", "microsoft.com",
                            "sharepoint.com", "emiratesgroup.sharepoint.com",
                            "login.live.com", "microsoftonline.com"]

        // 1. Remove caches, local/session storage, IndexedDB, service workers
        let typesToRemove: Set<String> = [
            WKWebsiteDataTypeDiskCache,
            WKWebsiteDataTypeMemoryCache,
            WKWebsiteDataTypeLocalStorage,
            WKWebsiteDataTypeSessionStorage,
            WKWebsiteDataTypeIndexedDBDatabases,
            WKWebsiteDataTypeServiceWorkerRegistrations
        ]
        dataStore.removeData(ofTypes: typesToRemove,
                             modifiedSince: .distantPast) {
            // 2. Selectively remove cookies that are NOT login-related
            let cookieStore = dataStore.httpCookieStore
            cookieStore.getAllCookies { cookies in
                let group = DispatchGroup()
                for cookie in cookies {
                    let domain = cookie.domain.lowercased()
                    let isLogin = loginDomains.contains { domain.hasSuffix($0) }
                    if !isLogin {
                        group.enter()
                        cookieStore.delete(cookie) { group.leave() }
                    }
                }
                group.notify(queue: .main) {
                    completion()
                }
            }
        }
    }

    // MARK: - Scraper JavaScript

    /// The JavaScript that extracts data from the portal's localStorage.
    /// Returns a JSON string via the last expression.
    static let scraperScript: String = """
    (function() {
        function safeParse(str) {
            try { return JSON.parse(str); }
            catch(e) { return null; }
        }
        function transformFormat(str) {
            var fltNumber = str.split("_")[1];
            var temp = str.split("_")[2].split("-", 3);
            temp[1] = (parseInt(temp[1]) + 1).toString();
            temp[2] = (parseInt(temp[2]) + 2000).toString();
            temp.forEach(function(n, i) { temp[i] = n.padStart(2, "0"); });
            return fltNumber + "_" + temp.join("/");
        }
        function convertDate(stringDate) {
            var parts = stringDate.split(" ", 1)[0].split("/");
            var day = parts[0], month = parts[1], year = parts[2];
            var rest = stringDate.split(" ")[1];
            return [parseInt(month), day, year].join("/") + " " + rest;
        }

        var userStaffNumber = localStorage.getItem("CurrentStaffNo");
        if (!userStaffNumber) return JSON.stringify({});

        var crewDataKey = Object.keys(localStorage).filter(function(k) {
            return k.startsWith("Crew_") && !k.endsWith("TimeOut");
        });
        var rosterKey = Object.keys(localStorage).filter(function(k) {
            return k.startsWith("Roster_" + userStaffNumber) && !k.endsWith("TimeOut") && !k.endsWith("Destination");
        });
        var flightDataKey = Object.keys(localStorage).filter(function(m) {
            return m.startsWith("Position_") && !m.endsWith("TimeOut");
        });

        var dataToGo = {}, roster = [];

        rosterKey.forEach(function(item) {
            var value = safeParse(localStorage.getItem(item));
            if (value) roster.push(value);
        });

        roster.forEach(function(item) {
            item.StaffRosters[0].RosterData.CrewRosterResonse.Trips.Trp.forEach(function(subitem) {
                dataToGo[subitem.TripNo + "_" + subitem.StartDate.split(" ", 1)] = {};
            });
        });

        crewDataKey.forEach(function(item) {
            var value = safeParse(localStorage.getItem(item));
            if (value) {
                var key = transformFormat(item);
                if (dataToGo[key]) dataToGo[key].crewData = value;
            }
        });

        flightDataKey.forEach(function(item) {
            var value = safeParse(localStorage.getItem(item));
            if (value) {
                var key = item.split(" ", 1)[0].split("_").slice(-2).join("_");
                if (dataToGo[key]) dataToGo[key].flightData = value;
            }
        });

        roster.forEach(function(item) {
            item.StaffRosters[0].RosterData.CrewRosterResonse.Trips.Trp.forEach(function(subitem) {
                var key = subitem.TripNo + "_" + subitem.StartDate.split(" ", 1)[0];
                if (!dataToGo[key]) dataToGo[key] = {};
                dataToGo[key].shortInfo = {};
                dataToGo[key].shortInfo.sectors = subitem.Dty.length;
                dataToGo[key].shortInfo.flightNumber = subitem.Dty[0].Flt[0].FltNo;
                dataToGo[key].shortInfo.flightDate = new Date(convertDate(subitem.Dty[0].Flt[0].DepDate)).toISOString();
                var flightLegs = ["DXB"], layovers = [], durations = [], sectorsPerDuty = [];
                subitem.Dty.forEach(function(duty) {
                    sectorsPerDuty.push(duty.Flt.length);
                    duty.Flt.forEach(function(flightLeg) {
                        if (flightLeg.ArrStn !== "DXB") {
                            flightLegs.push(flightLeg.ArrStn);
                            layovers.push(flightLeg.LayOverTime);
                        }
                        durations.push(flightLeg.Duration);
                    });
                });
                dataToGo[key].shortInfo.flightLegs = flightLegs;
                dataToGo[key].shortInfo.layovers = layovers;
                dataToGo[key].shortInfo.durations = durations;
                dataToGo[key].shortInfo.sectorsPerDuty = sectorsPerDuty;
                dataToGo[key].shortInfo.staff = userStaffNumber;
            });
        });

        var sorted = Object.entries(dataToGo)
            .sort(function(a, b) { return new Date(a[1].shortInfo.flightDate) - new Date(b[1].shortInfo.flightDate); })
            .reduce(function(r, entry) { r[entry[0]] = entry[1]; return r; }, {});

        return JSON.stringify(sorted);
    })();
    """
}

// MARK: - WKWebView UIKit Wrapper

struct WebViewRepresentable: UIViewRepresentable {
    let webView: WKWebView
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var currentURL: String

    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebViewRepresentable

        init(_ parent: WebViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
            updateState(webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            updateState(webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            updateState(webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            updateState(webView)
        }

        private func updateState(_ webView: WKWebView) {
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            parent.currentURL = webView.url?.absoluteString ?? ""
        }
    }
}
