//
//  ViewController.swift
//  Peekraw
//
//  Created by Alexander Kolov on 2022-05-31.
//

import Cache
import Defaults
import Flow
import Foundation
import SnapKit
import SwiftUI
import UIKit
import UniformTypeIdentifiers

class MainViewController: UIViewController {

  private typealias ImageCache = Storage<ImageFile.ID, PlatformImage>

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

  private lazy var cache: ImageCache? = {
    do {
      return try Self.prepareCache()
    }
    catch {
      debugPrint(error)
      return nil
    }
  }()

  private var unsupportedFiles = Set<ImageFile.ID>()

  private var files = [ImageFile]() {
    didSet {
      unsupportedFiles.removeAll()
      loadData()
      DispatchQueue.global(qos: .userInitiated).async {
        self.prepareThumbnails()
      }
    }
  }

  private lazy var openAction = UIAction(title: L10n.General.openWithEllipsis) { [weak self] _ in
    self?.openFolder()
  }

  private lazy var dataSource: UICollectionViewDiffableDataSource<MainListSection, ImageFile.ID> = {
    let imageCellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, ImageFile> { cell, indexPath, file in
      let isUnsupported = self.unsupportedFiles.contains(file.id)
      let thumbnail: PlatformImage?

      do {
        thumbnail = try self.cache?.object(forKey: file.id)
      }
      catch {
        thumbnail = nil
        debugPrint(error)
      }

      cell.contentConfiguration = UIHostingConfiguration {
        VStack {
          if isUnsupported {
            ZStack(alignment: .center) {
              Rectangle()
                .foregroundColor(Color(uiColor: .tertiarySystemFill))
              Text(L10n.MainView.unsupportedFormat)
                .font(.title)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
          }
          else if let thumbnail = thumbnail {
            Image(uiImage: thumbnail).resizable().scaledToFit()
          }
          else {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
  private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout()).then {
    $0.alwaysBounceVertical = true
    $0.refreshControl = refreshControl
  }

  private lazy var refreshControl = UIRefreshControl(
    frame: .zero,
    primaryAction: UIAction { _ in
      DispatchQueue.global(qos: .userInitiated).async {
        self.prepareThumbnails()
      }
    })

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

  private static func prepareCache() throws -> ImageCache {
    return Storage(
      hybridStorage: HybridStorage(
        memoryStorage: MemoryStorage(
          config: MemoryConfig(countLimit: 100)
        ),
        diskStorage: try DiskStorage(
          config: DiskConfig(
            name: "ThumbnailStorage",
            maxSize: 100 * 1024 * 1024
          ),
          transformer: TransformerFactory.forImage()
        )
      )
    )
  }

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

  private func prepareThumbnails() {
    for file in files {
      do {
        guard let image = try file.thumbnail() else {
          unsupportedFiles.insert(file.id)
          continue
        }

        try cache?.setObject(image, forKey: file.id)
      }
      catch {
        unsupportedFiles.insert(file.id)
      }

      DispatchQueue.main.async {
        var snapshot = self.dataSource.snapshot()
        snapshot.reloadItems([file.id])
        self.dataSource.apply(snapshot)
      }
    }

    DispatchQueue.main.async {
      self.refreshControl.endRefreshing()
    }
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
