/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This class shows soup order details. When configured with a 'newOrder' purpose,
 the view controller collects details of a new order. When configured with a 'historicalOrder'
 purpose, the view controller displays details of a previously placed order.
*/

import UIKit
import os.log
import IntentsUI

class OrderDetailViewController: UIViewController {
    
    var intentMap : Dictionary<String,INIntent> = Dictionary.init()
    private var collectionView: UICollectionView! = nil
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>! = nil
    
    private var titleCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Item>!
    private var contentsCellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Item>!
    private var siriCellRegistration: UICollectionView.CellRegistration<AddToSiriCollectionViewCell, Item>!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        var allIntentDataKeys = [CommonCode.shared().DisplayKeyWord,
                                 CommonCode.shared().EndKeyWord,
                                 CommonCode.shared().StartKeyWord,
                                 CommonCode.shared().NormalStartKeyWord,
                                 CommonCode.shared().PauseKeyWord,
                                 CommonCode.shared().ResumeKeyWord,]

        for key in allIntentDataKeys {
            intentMap[key] = stringClassObjectFromString(className: key)
        }
        configureCollectionView()
        configureDataSource()
    }
}

// MARK: - IntentsUI Delegates

extension OrderDetailViewController: INUIAddVoiceShortcutButtonDelegate {
    
    func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        addVoiceShortcutViewController.delegate = self
        present(addVoiceShortcutViewController, animated: true, completion: nil)
    }
    
    /// - Tag: edit_phrase
    func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
        editVoiceShortcutViewController.delegate = self
        present(editVoiceShortcutViewController, animated: true, completion: nil)
    }
}

extension OrderDetailViewController: INUIAddVoiceShortcutViewControllerDelegate {
    
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController,
                                        didFinishWith voiceShortcut: INVoiceShortcut?,
                                        error: Error?) {
        if let error = error as NSError? {
            Logger().debug("Error adding voice shortcut \(error)")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension OrderDetailViewController: INUIEditVoiceShortcutViewControllerDelegate {
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didUpdate voiceShortcut: INVoiceShortcut?,
                                         error: Error?) {
        if let error = error as NSError? {
            Logger().debug("Error editing voice shortcut \(error)")
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController,
                                         didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Collection View Setup

extension OrderDetailViewController: UICollectionViewDelegate {
    private func configureCollectionView() {
        let layout = createCollectionViewLayout()
        let collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        view.addSubview(collectionView)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        self.collectionView = collectionView
    }
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let sectionProvider = { (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            
            var configuration: UICollectionLayoutListConfiguration
                configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            
            configuration.backgroundColor = .systemGroupedBackground
            
            let sectionLayout = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return sectionLayout
        }
        return UICollectionViewCompositionalLayout(sectionProvider: sectionProvider)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        //点击操作
        let item = dataSource.itemIdentifier(for: indexPath)
        
        updateSnapshot()
    }
}

// MARK: - Collection View Data Mangement

extension OrderDetailViewController {
    
    private enum Section: String {
        case soupDescription
        case siri
        case contents
    }
    
    private enum CellType {
        case titleBanner
        case siri
        case contents
    }
    
    private class Item: Hashable, Identifiable {
        let type: CellType
        let text: String?
        let rawValue: AnyHashable?
        let enabled: Bool
        let intent :INIntent?
        
        init(type: CellType, text: String? = nil, rawValue: AnyHashable? = nil, enabled: Bool = false, intent: INIntent? = nil) {
            self.type = type
            self.text = text
            self.rawValue = rawValue
            self.enabled = enabled
            self.intent = intent
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: Item, rhs: Item) -> Bool {
            return lhs.id == rhs.id
        }
    }
    
    private func configureDataSource() {
        prepareCellRegistrations()
            
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Item) -> UICollectionViewCell? in
            switch item.type {
            case .titleBanner:
                return collectionView.dequeueConfiguredReusableCell(using: self.titleCellRegistration, for: indexPath, item: item)
            case .siri:
                return collectionView.dequeueConfiguredReusableCell(using: self.siriCellRegistration, for: indexPath, item: item)
            case .contents:
                return collectionView.dequeueConfiguredReusableCell(using: self.contentsCellRegistration, for: indexPath, item: item)
            }
        }
        
        updateSnapshot()
    }
    
    private func prepareCellRegistrations() {
        titleCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.text
            content.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
            cell.contentConfiguration = content
        }

        siriCellRegistration = UICollectionView.CellRegistration<AddToSiriCollectionViewCell, Item> { cell, indexPath, item in
            var contentConfiguration = AddToSiriCellContentConfiguration()
            contentConfiguration.intent = item.intent
            contentConfiguration.delegate = self
            cell.contentConfiguration = contentConfiguration
        }
        
        contentsCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, indexPath, item in
            var content = cell.defaultContentConfiguration()
            content.text = item.text
            content.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
            cell.contentConfiguration = content
        }
    }
    
    private func visibleSections() -> [Section] {
        return [.soupDescription, .siri, .contents]
    }
    
    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        let sections = visibleSections()
        snapshot.appendSections(sections)
        
        //title
        let soupDescriptions = [Item(type: .titleBanner, text: "喂奶")]
        snapshot.appendItems(soupDescriptions, toSection: .soupDescription)
        
        //siri shortcut
        for (name,intent) in intentMap {
            //这里设置的参数在语音识别回调中会丢失
            snapshot.appendItems([Item(type: .siri, text: name, rawValue: name, intent: intent)], toSection: .siri)
        }
        
        //content
        var items = Array<Item>.init()
        let records = CommonCode.shared().readDBContent()
        for recordItem in records {
            let timeStr = convertDBTimeToDateStr(time: recordItem.content.first!.startTime)
            let string =  timeStr + " count: '\(recordItem.content.count)', " + periodStateStr(periodState: recordItem.periodState) + timeDisplayFormat(time: recordItem.getCost())
            items.append(Item(type: .contents, text: string, rawValue: string))
        }
        snapshot.appendItems(items, toSection: .contents)

        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }
}
