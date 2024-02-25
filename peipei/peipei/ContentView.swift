//
//  ContentView.swift
//  peipei
//
//  Created by Sanjay Salem on 2/24/24.
//

import SwiftUI
import ProximityReader

struct ContentView: View {
    var reader: PaymentCardReader?
    var session: PaymentCardReaderSession?
    
    var events: AsyncStream<PaymentCardReader.Event>? {
        return reader?.events
    }
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(Image.Scale.large)
                .foregroundStyle(TintShapeStyle.tint)
            Text("Hello, world!")
        }
        .padding()
    }
    
    init() {
        guard PaymentCardReader.isSupported else {
            // This device doesn't support Tap to Pay on iPhone.
            return
        }
        self.reader = PaymentCardReader()
    }
    
    public func presentTermsAndConditions(aTokenFromPSP: String) async throws {
        let token: PaymentCardReader.Token = PaymentCardReader.Token(rawValue: aTokenFromPSP)
        // Confirm that the user is an admin. Otherwise, display a message that
        // states only admins may accept the Terms and Conditions.
        do {
            try await self.reader?.linkAccount(using: token)
        } catch {
            // Handle any errors that occur during linking.
        }
    }
    
    public mutating func configureDevice(aTokenFromPSP: String) async throws {
        let token: PaymentCardReader.Token = PaymentCardReader.Token(rawValue: aTokenFromPSP)
        guard let events: AsyncStream<PaymentCardReader.Event> else {
            return
        }
        do {
            Task {
                for await event: PaymentCardReader.Event in events {
                    if case PaymentCardReader.Event.updateProgress = event {
                        // Make sure you update the user interface (if you have one)
                        // using the progress value.
                    }
                }
            }
            self.session = try await reader?.prepare(using: token)
        } catch {
            // Handle any errors that occur during preparation
            // (see PaymentCardReaderError).
        }
    }
    
    public func readCard(for amount: Decimal) async throws {
        let request: PaymentCardTransactionRequest = PaymentCardTransactionRequest(amount: amount, 
                                                                                   currencyCode: "USD",
                                                                                   for: PaymentCardTransactionRequest.TransactionType.purchase)
        guard let events: AsyncStream<PaymentCardReader.Event> else {
            return
        }
        do {
            Task {
                for await event: PaymentCardReader.Event in events {
                    // Handle events that happen while the sheet is up.
                }
            }
            let result: PaymentCardReadResult? = try await session?.readPaymentCard(request)
            // Send result.paymentCardData to your payment service provider.
        } catch {
            // Handle any errors that occur during read
            // (see PaymentCardReaderSession.ReadError).
        }
    }
    
    public func capturePIN(for previousData: PaymentCardReadResult, with rawPINTokenFromPSP: String) async throws {
        let transactionId: String = previousData.id
        let token: PaymentCardReaderSession.PINToken = PaymentCardReaderSession.PINToken(rawValue: rawPINTokenFromPSP)
        guard let events: AsyncStream<PaymentCardReader.Event> else {
            return
        }
        do {
            Task {
                for await event: PaymentCardReader.Event in events {
                    // Handle events that happen while the sheet is up.
                }
            }
            let result: PaymentCardReadResult? = try await self.session?.capturePIN(using: token, cardReaderTransactionID: transactionId)
            // Send result.paymentCardData to your payment service provider.
        } catch {
            // Handle any errors that occur during PIN capture
            // (see PaymentCardReaderSession.ReadError).
        }
    }
    
    public mutating func cleanup() {
        self.session = nil
        self.reader = nil
    }
}

#Preview {
    ContentView()
}
