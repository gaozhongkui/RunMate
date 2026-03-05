//
//  PasswordInputSheet.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import SwiftUI

struct PasswordInputSheet: View {
    @Binding var password: String
    @Binding var isEncrypting: Bool
    @Environment(\.dismiss) var dismiss
    let onConfirm: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 30)
                
                Text("Set Encryption Password")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Set a strong password to protect your images")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                SecureField("Enter password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 30)
                    .frame(height: 50)
                
                Button {
                    onConfirm()
                } label: {
                    if isEncrypting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Encrypt")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(password.isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 30)
                .disabled(password.isEmpty || isEncrypting)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isEncrypting)
                }
            }
        }
    }
}
