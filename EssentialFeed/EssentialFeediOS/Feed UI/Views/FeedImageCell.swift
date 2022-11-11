//
//  FeedImageCell.swift
//  EssentialFeediOS
//
//  Created by Paolo Prodossimo Lopes on 09/11/22.
//

import UIKit

final class FeedImageCell: UITableViewCell {
    public lazy var imageContainer = UIView()
    public lazy var feedImageView = UIImageView()
    public lazy var localtionContainer = UIView()
    public lazy var descriptionLabel = UILabel()
    public lazy var localtionLabel = UILabel()
    
    public lazy var feedImageRetryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()
    
    @objc private func retryButtonTapped() {
        onRetry?()
    }
    
    var onRetry: (() -> Void)?
}
