//
//  TranslateViewController.swift
//  TranslateApp
//
//  Created by Николай Игнатов on 24.03.2025.
//

import UIKit

final class TranslateViewController: UIViewController {
    private let viewModel: TranslateViewModel
    
    private lazy var sourceLanguageLabel: UILabel = makeLanguageLabel()
    private lazy var targetLanguageLabel: UILabel = makeLanguageLabel()
    
    private lazy var sourceTextField: UITextField = {
        let textField = makeTextField()
        textField.placeholder = "Введите текст для перевода"
        return textField
    }()
    
    private lazy var translationTextField: UITextField = {
        let textField = makeTextField()
        textField.isUserInteractionEnabled = false
        return textField
    }()
    
    private lazy var buttonsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [clearButton, swapButton, copyButton])
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var swapButton = makeButton(systemName: "arrow.2.squarepath")
    private lazy var clearButton = makeButton(systemName: "xmark.circle")
    private lazy var copyButton = makeButton(systemName: "doc.on.doc")
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    init(viewModel: TranslateViewModel = TranslateViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupConstraints()
        setupBindings()
        setupActions()
        setupInitialState()
    }
}

// MARK: - Setup UI
private extension TranslateViewController {
    func makeTextField() -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.font = .systemFont(ofSize: 16)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }
    
    func makeButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    func makeLanguageLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
    
    func setupView() {
        view.backgroundColor = .systemBackground
        
        [sourceLanguageLabel, sourceTextField,
         buttonsStackView,
         targetLanguageLabel, translationTextField,
         activityIndicator].forEach(view.addSubview)
    }
    
    func setupInitialState() {
          sourceLanguageLabel.text = viewModel.getLanguageName(for: viewModel.sourceLanguage)
          targetLanguageLabel.text = viewModel.getLanguageName(for: viewModel.targetLanguage)
      }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            // Source language label
            sourceLanguageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            sourceLanguageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Source text field
            sourceTextField.topAnchor.constraint(equalTo: sourceLanguageLabel.bottomAnchor, constant: 8),
            sourceTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sourceTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sourceTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Buttons stack view
            buttonsStackView.topAnchor.constraint(equalTo: sourceTextField.bottomAnchor, constant: 16),
            buttonsStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            buttonsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Target language label
            targetLanguageLabel.topAnchor.constraint(equalTo: buttonsStackView.bottomAnchor, constant: 16),
            targetLanguageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Translation text field
            translationTextField.topAnchor.constraint(equalTo: targetLanguageLabel.bottomAnchor, constant: 8),
            translationTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            translationTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            translationTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: translationTextField.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: translationTextField.centerYAnchor)
        ])
    }
}

// MARK: - Setup Bindings & Actions
private extension TranslateViewController {
    func setupBindings() {
        viewModel.onTranslationChanged = { [weak self] text in
            self?.translationTextField.text = text
        }
        
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            self?.updateLoadingState(isLoading)
        }
        
        viewModel.onErrorReceived = { [weak self] error in
            self?.showError(error)
        }
        
        viewModel.onSourceLanguageChanged = { [weak self] language in
            self?.sourceLanguageLabel.text = language
        }
        
        viewModel.onTargetLanguageChanged = { [weak self] language in
            self?.targetLanguageLabel.text = language
        }
    }
    
    func setupActions() {
        sourceTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        swapButton.addTarget(self, action: #selector(swapButtonTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
    }
    
    func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            activityIndicator.startAnimating()
            translationTextField.textColor = .systemGray
        } else {
            activityIndicator.stopAnimating()
            translationTextField.textColor = .label
        }
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Actions
private extension TranslateViewController {
    @objc func textFieldDidChange() {
        viewModel.updateSourceText(sourceTextField.text ?? "")
    }
    
    @objc func swapButtonTapped() {
        viewModel.swapLanguages()
        sourceTextField.text = translationTextField.text
    }
    
    @objc func clearButtonTapped() {
        sourceTextField.text = ""
        viewModel.clearText()
    }
    
    @objc func copyButtonTapped() {
        UIPasteboard.general.string = translationTextField.text
    }
}
