//
//  DecryptPasswordSheet.swift
//  RunMate
//
//  Created by gaozhongkui on 2026/2/6.
//

import SwiftUI

struct DecryptPasswordSheet: View {
    @Binding var password: String
    @Binding var isDecrypting: Bool
    @Environment(\.dismiss) var dismiss
    let onConfirm: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .padding(.top, 30)
                
                Text("vault_decrypt_title")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("vault_decrypt_hint")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                SecureField("vault_decrypt_placeholder", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 30)
                    .frame(height: 50)
                
                Button {
                    onConfirm()
                } label: {
                    if isDecrypting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("vault_decrypt_button")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(password.isEmpty ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 30)
                .disabled(password.isEmpty || isDecrypting)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common_cancel") {
                        dismiss()
                    }
                    .disabled(isDecrypting)
                }
            }
        }
    }
}
