import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var subscriptionService = SubscriptionService.shared
    @ObservedObject private var adService = AdService.shared
    @State private var showRestorePurchasesAlert = false
    @State private var restoreMessage = ""
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showAdTestResult = false
    @State private var adTestResult = ""
    
    var body: some View {
        NavigationView {
            List {
                // Appearance section
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $userViewModel.isDarkMode)
                        .onChange(of: userViewModel.isDarkMode) { oldValue, newValue in
                            userViewModel.toggleDarkMode()
                        }
                }
                
                // Test Ad Section (Only visible in DEBUG mode)
                #if DEBUG
                Section(header: Text("Debug Options")) {
                    Button("Test Rewarded Interstitial Ad") {
                        testRewardedInterstitialAd()
                    }
                    .foregroundColor(.blue)
                    
                    if !adTestResult.isEmpty {
                        Text(adTestResult)
                            .font(.caption)
                            .foregroundColor(adTestResult.contains("Success") ? .green : .red)
                    }
                    
                    Button("Check Ad Load Status") {
                        adTestResult = adService.rewardedInterstitialAd != nil ?
                            "Ad is loaded and ready" :
                            "No ad is currently loaded"
                    }
                    .foregroundColor(.blue)
                    
                    Button("Force Load New Ad") {
                        Task {
                            adTestResult = "Loading new ad..."
                            await adService.loadRewardedInterstitialAd()
                            adTestResult = adService.rewardedInterstitialAd != nil ?
                                "Successfully loaded new ad" :
                                "Failed to load new ad: \(adService.lastAdError ?? "unknown error")"
                        }
                    }
                    .foregroundColor(.blue)
                }
                #endif
                
                // Subscription section
                Section(header: Text("Subscription")) {
                    if subscriptionService.isLoading {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Processing...")
                                .foregroundColor(.secondary)
                        }
                    } else if let errorMessage = subscriptionService.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if userViewModel.stats.hasSubscription {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Premium Subscription Active")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remove Ads")
                                .font(.headline)
                            Text("Subscribe to remove all advertisements and support the app.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        
                        if subscriptionService.products.isEmpty {
                            Button("$3.99/month") {
                                Task {
                                    await subscriptionService.loadProducts()
                                }
                            }
                            .foregroundColor(.blue)
                        } else {
                            ForEach(subscriptionService.products, id: \ .id) { product in
                                Button(action: {
                                    Task {
                                        try? await subscriptionService.purchase(product)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("\(product.displayPrice)/month")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                        
                        Button(action: {
                            Task {
                                do {
                                    try await subscriptionService.restorePurchases()
                                    showRestorePurchasesAlert = true
                                    restoreMessage = userViewModel.stats.hasSubscription ? "Your purchases have been restored!" : "No purchases found to restore."
                                } catch {
                                    restoreMessage = "Error restoring purchases: \(error.localizedDescription)"
                                    showRestorePurchasesAlert = true
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .foregroundColor(.blue)
                                Text("Restore Purchases")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Game Center section
                Section(header: Text("Game Center")) {
                    Button(action: {
                        GameCenterService.shared.authenticateUser()
                    }) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .foregroundColor(.green)
                            Text("Sign in to Game Center")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                
                // About section
                Section(header: Text("About")) {
                    Button(action: { showingPrivacyPolicy = true }) {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.blue)
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: { showingTermsOfService = true }) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                            Text("Terms of Service")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .alert(isPresented: $showRestorePurchasesAlert) {
                Alert(title: Text("Restore Purchases"), message: Text(restoreMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                WebContentView(title: "Privacy Policy", content: privacyPolicyContent)
            }
            .sheet(isPresented: $showingTermsOfService) {
                WebContentView(title: "Terms of Service", content: termsOfServiceContent)
            }
            .alert("Ad Test Result", isPresented: $showAdTestResult) {
                Button("OK") { showAdTestResult = false }
            } message: {
                Text(adTestResult)
            }
            .onAppear {
                Task { await subscriptionService.loadProducts() }
            }
        }
    }
    
    private func testRewardedInterstitialAd() {
        if let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController {
            
            adTestResult = "Attempting to show ad..."
            
            // Set completion handlers
            adService.onAdDismissed = {
                DispatchQueue.main.async {
                    adTestResult = "Success: Ad was dismissed"
                    showAdTestResult = true
                }
            }
            
            adService.showRewardedInterstitialAd(from: rootVC) {
                print("✅ Test ad reward earned")
                // We don't update UI here as it would be covered by the ad
                // The onAdDismissed callback will handle UI updates
            }
        } else {
            adTestResult = "Error: Could not find root view controller"
            showAdTestResult = true
        }
    }
    
    private var privacyPolicyContent: String { "# Privacy Policy for SkySpotter\n..." }
    private var termsOfServiceContent: String { "# Terms of Service for SkySpotter\n..." }
}

struct WebContentView: View {
    let title: String
    let content: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView { Text(content).padding() }
            .navigationTitle(title)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(UserViewModel())
    }
}
