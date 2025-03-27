//
//  TranslateViewModel.swift
//  TranslateApp
//
//  Created by Николай Игнатов on 27.03.2025.
//

import Foundation

final class TranslateViewModel {
    // MARK: - Closure for binding
    var onTranslationChanged: ((String) -> Void)?
    var onLoadingStateChanged: ((Bool) -> Void)?
    var onErrorReceived: ((String) -> Void)?
    var onSourceLanguageChanged: ((String) -> Void)?
    var onTargetLanguageChanged: ((String) -> Void)?
    
    // MARK: - Properties
    private let networkService: NetworkServiceProtocol
    private var translateWorkItem: DispatchWorkItem?
    private var translatedText: String = ""
    
    private let languageNames: [String: String] = [
        "en": "Английский",
        "ru": "Русский"
    ]
    
  
    private(set) var sourceLanguage: String = "en" {
        didSet {
            translate()
            onSourceLanguageChanged?(getLanguageName(for: sourceLanguage))
        }
    }
    
    private(set) var targetLanguage: String = "ru" {
        didSet {
            translate()
            onTargetLanguageChanged?(getLanguageName(for: targetLanguage))
        }
    }
    
    private var sourceText: String = "" {
        didSet { translate() }
    }
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    // MARK: - Public methods
    func updateSourceText(_ text: String) {
        sourceText = text
    }
    
    func swapLanguages() {
        let tempLang = sourceLanguage
        let tempText = sourceText
        
        sourceLanguage = targetLanguage
        targetLanguage = tempLang
        
        sourceText = translatedText
        translatedText = tempText
        
        onTranslationChanged?(translatedText)
    }
    
    func clearText() {
        sourceText = ""
        translatedText = ""
        onTranslationChanged?("")
    }
    
    func getLanguageName(for code: String) -> String {
        return languageNames[code] ?? code.uppercased()
    }
}

// MARK: - Private methods
private extension TranslateViewModel {
    func translate() {
        cancelPreviousTranslation()
        
        guard shouldPerformTranslation() else {
            onTranslationChanged?("")
            return
        }
        
        scheduleTranslation()
    }
    
    func cancelPreviousTranslation() {
        translateWorkItem?.cancel()
        translateWorkItem = nil
    }
    
    func shouldPerformTranslation() -> Bool {
        !sourceText.isEmpty
    }
    
    func scheduleTranslation() {
        let workItem = createTranslationWorkItem()
        translateWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func createTranslationWorkItem() -> DispatchWorkItem {
        DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.performTranslation()
        }
    }
    
    func performTranslation() {
        setLoadingState(true)
        
        let parameters = TranslationParameters(
            sourceLanguage: sourceLanguage,
            destinationLanguage: targetLanguage,
            text: sourceText
        )
        
        networkService.translate(parameters: parameters) { [weak self] result in
            self?.handleTranslationResult(result)
        }
    }
    
    func setLoadingState(_ isLoading: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.onLoadingStateChanged?(isLoading)
        }
    }
    
    func handleTranslationResult(_ result: Result<TranslationResponse, NetworkError>) {
        DispatchQueue.main.async { [weak self] in
            self?.setLoadingState(false)
            
            switch result {
            case .success(let response):
                self?.translatedText = response.destinationText
                self?.onTranslationChanged?(response.destinationText)
            case .failure(let error):
                self?.onErrorReceived?(error.localizedDescription)
            }
        }
    }
}
