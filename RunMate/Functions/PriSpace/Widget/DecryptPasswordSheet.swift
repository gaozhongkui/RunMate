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
                
                Text("输入解密密码")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("请输入加密时设置的密码")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                SecureField("输入密码", text: $password)
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
                        Text("解密查看")
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
                    Button("取消") {
                        dismiss()
                    }
                    .disabled(isDecrypting)
                }
            }
        }
    }
}
