//
//  TranslateTab.swift
//  Speech2Text
//
//  Created by Jiping Yang on 11/26/25.
//

import SwiftUI
import UIKit

struct TranslateTab: View {
    @ObservedObject var viewModel: SpeechViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                            Text("Target Language")
                                .font(.headline)
                            Spacer()
                        }

                        Picker("Language", selection: $viewModel.selectedLanguage) {
                            ForEach(viewModel.supportedLanguages, id: \.self) { lang in
                                Text(lang.name).tag(lang)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Original Text")
                            .font(.headline)

                        TextEditor(text: $viewModel.speechText.originalText)
                            .frame(minHeight: 150)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") { hideKeyboard() }
                                }
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                    )

                    HStack(spacing: 16) {
                        Button(action: viewModel.translateText) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Translate")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isProcessing || viewModel.speechText.originalText.isEmpty)

                        Button(action: viewModel.improveText) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Improve")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isProcessing || viewModel.speechText.originalText.isEmpty)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Result")
                                .font(.headline)
                            Spacer()
                            if !viewModel.speechText.processedText.isEmpty {
                                HStack(spacing: 16) {
                                    Button(action: { viewModel.speakProcessedText() }) {
                                        Image(systemName: "speaker.wave.2.fill")
                                            .foregroundColor(.orange)
                                    }

                                    Button(action: viewModel.copyProcessedText) {
                                        Image(systemName: "doc.on.doc")
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                        }

                        TextEditor(text: $viewModel.speechText.processedText)
                            .frame(minHeight: 150)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.5), lineWidth: viewModel.speechText.processedText.isEmpty ? 1 : 2)
                            )
                            .toolbar {
                                ToolbarItemGroup(placement: .keyboard) {
                                    Spacer()
                                    Button("Done") { hideKeyboard() }
                                }
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 10)
                    )

                    HStack(spacing: 16) {
                        Button(action: viewModel.clearText) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Clear")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Button(action: viewModel.replaceText) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                Text("Swap")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.speechText.processedText.isEmpty)
                    }
                    .padding(.horizontal)

                    if let errorMessage = viewModel.errorMessage {
                        ErrorBanner(message: errorMessage)
                    }

                    if viewModel.showCopySuccess {
                        SuccessBanner(message: "Copied to clipboard!")
                    }
                }
                .padding()
            }
            .navigationTitle("Translate & Improve")
            .overlay {
                if viewModel.isProcessing {
                    ProcessingOverlay(message: viewModel.processingMessage, onCancel: viewModel.cancelProcessing)
                }
            }
        }
    }
}

struct TranslateTab_Previews: PreviewProvider {
    static var previews: some View {
        TranslateTab(viewModel: SpeechViewModel())
    }
}
