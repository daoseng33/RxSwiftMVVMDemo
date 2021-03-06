//
//  EventListViewController.swift
//  MVVMPlayground
//
//  Created by Neo on 01/10/2017.
//  Copyright © 2017 ST.Huang. All rights reserved.
//

import UIKit
import SDWebImage
import RxSwift
import RxCocoa

class PhotoListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    lazy var viewModel: PhotoListViewModel = {
        return PhotoListViewModel(apiService: APIService())
    }()
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Init the static view
        initView()
        
        // init view model
        initVM()
        
    }
    
    func initView() {
        self.navigationItem.title = "Popular"
        
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
    }
    
    func initVM() {
        
        viewModel.userPressedPhoto
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] (result) in
                    guard let `self` = self else { return }
                    
                    switch result {
                    case .photo(let photo):
                        self.goDetailVC(with: photo.image_url)
                    case .error(_):
                        self.showAlert("This item is not for sale")
                    }
                }
            )
            .disposed(by: bag)
        
        viewModel.isFetchingPhotos
            .drive(activityIndicator.rx.isAnimating)
            .disposed(by: bag)
        
        viewModel.isFetchingPhotos
            .map { $0 ? 0.0 : 1.0 }
            .drive(tableView.rx.alpha)
            .disposed(by: bag)
        
        viewModel.cellViewModels
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (vms) in
                self?.tableView.reloadData()
            })
            .disposed(by: bag)
        
        viewModel.viewIsReady()

    }
    
    func showAlert( _ message: String ) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction( UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension PhotoListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "photoCellIdentifier", for: indexPath) as? PhotoListTableViewCell else {
            fatalError("Cell not exists in storyboard")
        }
        
        let cellVM = viewModel.getCellViewModel( at: indexPath )
        
        cell.nameLabel.text = cellVM.titleText
        cell.descriptionLabel.text = cellVM.descText
        cell.mainImageView?.sd_setImage(with: URL( string: cellVM.imageUrl ), completed: nil)
        cell.dateLabel.text = cellVM.dateText
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfCells
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.viewModel.userPressed(at: indexPath)
    }
    
    func goDetailVC(with imageUrl: String) {
        let vc = PhotoDetailViewController()
        vc.imageUrl = imageUrl

        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

class PhotoListTableViewCell: UITableViewCell {
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descContainerHeightConstraint: NSLayoutConstraint!
}

