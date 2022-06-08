//
//  ViewController.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-05-31.
//

import Flow
import Foundation
import SnapKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

class MainViewController: UIViewController {

  private enum MainListSection: Int {
    case main
  }

  // MARK: Instance Properties

  private var files = [ImageFile]() {
    didSet {
      loadData()
    }
  }

  private lazy var openAction = UIAction(title: "Open...") { [weak self] _ in
    self?.openFolder()
  }

  private let compositionalLayout: UICollectionViewCompositionalLayout = {
    let inset: CGFloat = 2
    let fraction: CGFloat = 1 / 2
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(fraction))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    return UICollectionViewCompositionalLayout(section: section)
  }()

  private lazy var dataSource: UICollectionViewDiffableDataSource<MainListSection, ImageFile.ID> = {
    let imageCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, ImageFile> { cell, indexPath, file in
      cell.contentConfiguration = UIHostingConfiguration {
        VStack {
          (try? file.thumbnail().map { Image(uiImage: $0) } ?? Image(systemName: "xmark.octagon.fill"))!.resizable().scaledToFit()
          Text(file.url.lastPathComponent).font(.caption)
        }
      }
    }

    return UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
      let file = self.files[indexPath.item]
      return collectionView.dequeueConfiguredReusableCell(using: imageCellRegistration, for: indexPath, item: file)
    }
  }()

  // MARK: Subviews

  private lazy var openBarButton = UIBarButtonItem(systemItem: .add, primaryAction: openAction)
  private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: compositionalLayout)

  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    navigationItem.rightBarButtonItem = openBarButton

    view.subviews {
      collectionView
    }

    collectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }

  // MARK: Private Methods

  private func loadData() {
    var snapshot = NSDiffableDataSourceSnapshot<MainListSection, ImageFile.ID>()
    snapshot.appendSections([.main])
    snapshot.appendItems(files.map { $0.id }, toSection: .main)
    dataSource.applySnapshotUsingReloadData(snapshot)
  }

  private func openFolder() {
    let supportedTypes: [UTType] = [.folder]
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
    picker.delegate = self
    present(picker, animated: true, completion: nil)
  }

}

// MARK: UIDocumentPickerDelegate

extension MainViewController: UIDocumentPickerDelegate {

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    for url in urls {
      if let contents = FileManager.default.enumerator(at: url.resolvingSymlinksInPath(), includingPropertiesForKeys: nil) {
        for case let url as URL in contents {
          files.append(ImageFile(url: url))
        }
      }
    }
  }

}
