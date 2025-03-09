import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var showRestorePurchasesAlert = false
    @State private var restoreMessage = ""
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    
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
                                // Products not loaded yet, try loading them
                                Task {
                                    await subscriptionService.loadProducts()
                                }
                            }
                            .foregroundColor(.blue)
                        } else {
                            ForEach(subscriptionService.products, id: \.id) { product in
                                Button(action: {
                                    Task {
                                        do {
                                            try await subscriptionService.purchase(product)
                                        } catch {
                                            print("Purchase failed: \(error)")
                                        }
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
                                    
                                    if userViewModel.stats.hasSubscription {
                                        restoreMessage = "Your purchases have been restored!"
                                    } else {
                                        restoreMessage = "No purchases found to restore."
                                    }
                                } catch {
                                    restoreMessage = "Error restoring purchases: \(error.localizedDescription)"
                                    showRestorePurchasesAlert = true
                                    print("Failed to restore purchases: \(error)")
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
                    Button(action: {
                        showingPrivacyPolicy = true
                    }) {
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
                    
                    Button(action: {
                        showingTermsOfService = true
                    }) {
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
                Alert(
                    title: Text("Restore Purchases"),
                    message: Text(restoreMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                WebContentView(title: "Privacy Policy", content: privacyPolicyContent)
            }
            .sheet(isPresented: $showingTermsOfService) {
                WebContentView(title: "Terms of Service", content: termsOfServiceContent)
            }
            .onAppear {
                // Load products when view appears
                Task {
                    await subscriptionService.loadProducts()
                }
            }
        }
    }
    
    // Placeholder content for privacy policy
    private var privacyPolicyContent: String {
        """
        # Privacy Policy for SkySpotter
        
        ## 1. Information We Collect
        
        SkySpotter respects your privacy and is committed to protecting it. This Privacy Policy explains how we collect, use, and safeguard your information when you use our application.
        
        ## 2. Game Center Integration
        
        We use Game Center for leaderboards and achievements. This integration is subject to Apple's privacy policy.
        
        ## 3. In-App Purchases
        
        Payment information for subscriptions is handled entirely by Apple and we do not have access to your payment details.
        
        ## 4. Data Storage
        
        All quiz data and user progress is stored locally on your device. We do not collect or store this information on our servers.
        
        ## 5. Contact Us
        
        If you have any questions about this Privacy Policy, please contact us.
        """
    }
    
    // Placeholder content for terms of service
    private var termsOfServiceContent: String {
        """
        # Terms of Service for SkySpotter
        
        ## 1. Acceptance of Terms
        
        By downloading and using SkySpotter, you agree to be bound by these Terms of Service.
        
        ## 2. Description of Service
        
        SkySpotter is a quiz application that helps users identify different types of aircraft.
        
        ## 3. Subscriptions and Billing
        
        The app offers a monthly subscription to remove advertisements. Payment will be charged to your Apple ID account at confirmation of purchase.
        
        ## 4. Intellectual Property
        
        All content in the application, including images, text, and software, is the property of SkySpotter and is protected by copyright laws.
        
        ## 5. Limitation of Liability
        
        SkySpotter is provided "as is" without any warranties, express or implied.
        
        ## 6. Changes to Terms
        
        We reserve the right to modify these terms at any time. Your continued use of the application constitutes acceptance of those changes.
        """
    }
}

struct WebContentView: View {
    let title: String
    let content: String
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(content)
                    .padding()
            }
            .navigationTitle(title)
            .navigationBarItems(trailing:
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(UserViewModel())
    }
}
