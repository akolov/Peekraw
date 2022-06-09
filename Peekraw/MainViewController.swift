//
//  ViewController.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-05-31.
//

import Defaults
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

  private var lastOpenDirectoryURL: URL? {
    get {
      let data = Defaults[.lastOpenDirectoryBookmark]
      var isStale = false
      let url = data.flatMap { try? URL(resolvingBookmarkData: $0, bookmarkDataIsStale: &isStale) }
      return isStale ? nil : url
    }
    set {
      Defaults[.lastOpenDirectoryBookmark] = try? newValue?.bookmarkData(options: .minimalBookmark)
    }
  }

  private var files = [ImageFile]() {
    didSet {
      loadData()
    }
  }

  private lazy var openAction = UIAction(title: L10n.General.openWithEllipsis) { [weak self] _ in
    self?.openFolder()
  }

  private lazy var dataSource: UICollectionViewDiffableDataSource<MainListSection, ImageFile.ID> = {
    let imageCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, ImageFile> { cell, indexPath, file in
      let thumbnail = try? file.thumbnail().map { Image(uiImage: $0) }
      cell.contentConfiguration = UIHostingConfiguration {
        VStack {
          if let thumbnail = thumbnail {
            thumbnail.resizable().scaledToFit()
          }
          else {
            ZStack(alignment: .center) {
              Rectangle()
                .foregroundColor(Color(uiColor: .tertiarySystemFill))
              Text(L10n.MainView.unsupportedFormat)
                .font(.title)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
          }

          file.url.map { Text($0.lastPathComponent).font(.caption) }
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
  private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())

  // MARK: Initialization

  init() {
    super.init(nibName: nil, bundle: nil)
    self.title = L10n.MainView.Navigation.title
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: View Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()

    navigationItem.style = .browser
    navigationItem.largeTitleDisplayMode = .automatic
    navigationItem.rightBarButtonItem = openBarButton
    view.backgroundColor = .systemBackground

    collectionView.collectionViewLayout = prepareCollectionViewLayout()

    view.subviews {
      collectionView
    }

    collectionView.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }

    loadData()
  }

  override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate { context in
      self.collectionView.setCollectionViewLayout(self.prepareCollectionViewLayout(), animated: context.isAnimated)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    collectionView.setCollectionViewLayout(prepareCollectionViewLayout(), animated: true)
  }

  // MARK: Private Methods

  private func prepareCollectionViewLayout() -> UICollectionViewCompositionalLayout {
    let inset: CGFloat = 2
    let columns: CGFloat
    let referenceWidth: CGFloat = 250

    switch view.traitCollection.userInterfaceIdiom {
    case .phone:
      switch view.traitCollection.horizontalSizeClass {
      case .regular:
        columns = floor(view.bounds.width / referenceWidth)
      default:
        columns = 2
      }
    case .pad:
      columns = floor(view.bounds.width / referenceWidth)
    case .mac:
      columns = floor(view.bounds.width / referenceWidth)
    default:
      fatalError("Unsupported user inferface idiom")
    }

    let fraction: CGFloat = 1 / columns
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(fraction))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    return UICollectionViewCompositionalLayout(section: section)
  }

  private func prepareEmptyPlaceholderView() -> UIView {
    let container = UIView()

    var config = UIButton.Configuration.filled()
    config.buttonSize = .large
    config.cornerStyle = .large
    config.title = L10n.MainView.addFiles

    let button = UIButton(configuration: config, primaryAction: UIAction { _ in
      self.openFolder()
    })

    container.subviews {
      button
    }

    button.snp.makeConstraints {
      $0.center.equalToSuperview()
    }

    return container
  }

  private func loadData() {
    var snapshot = NSDiffableDataSourceSnapshot<MainListSection, ImageFile.ID>()
    snapshot.appendSections([.main])
    snapshot.appendItems(files.map { $0.id }, toSection: .main)
    dataSource.applySnapshotUsingReloadData(snapshot)

    if files.isEmpty {
      collectionView.backgroundView = prepareEmptyPlaceholderView()
    }
    else {
      collectionView.backgroundView = nil
    }
  }

  private func openFolder() {
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data])
    picker.directoryURL = lastOpenDirectoryURL
    picker.allowsMultipleSelection = true
    picker.delegate = self
    present(picker, animated: true, completion: nil)
  }

  private func processFolder(url: URL) -> [ImageFile] {
    var newFiles = [ImageFile]()
    var error: NSError?

    NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { coordinatedURL in
      let keys : [URLResourceKey] = [.nameKey, .isDirectoryKey]
      guard let contents = FileManager.default.enumerator(at: coordinatedURL, includingPropertiesForKeys: keys) else {
        return
      }

      for case let url as URL in contents {
        do {
          newFiles.append(try ImageFile(url: url))
        }
        catch {
          debugPrint(error)
        }
      }
    }

    if let error = error {
      debugPrint(error)
    }

    return newFiles
  }

}

// MARK: UIDocumentPickerDelegate

extension MainViewController: UIDocumentPickerDelegate {

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    defer {
      urls.forEach {
        $0.stopAccessingSecurityScopedResource()
      }
    }

    var newFiles = [ImageFile]()

    Bookmark: if let parentURL = urls.last?.deletingLastPathComponent(), parentURL.isDirectory {
      lastOpenDirectoryURL = parentURL
      parentURL.stopAccessingSecurityScopedResource()
    }

    for url in urls {
      guard url.startAccessingSecurityScopedResource() else {
        continue
      }

      if url.isDirectory {
        newFiles.append(contentsOf: processFolder(url: url))
      }
      else {
        do {
          newFiles.append(try ImageFile(url: url))
        }
        catch {
          debugPrint(error)
        }
      }
    }

    files = newFiles
  }

}
