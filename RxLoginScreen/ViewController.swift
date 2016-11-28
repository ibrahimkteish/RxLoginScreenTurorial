//
//  ViewController.swift
//  RxLoginScreen
//
//  Created by Ivan Kupalov on 14/08/16.
//  Copyright © 2016 Charlag. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

enum AuthCellType: String {
  case Headline
  case EmailTextField
  case NameTextField
  case PasswordTextField
  case LoginButton
  case Separator
}

extension AuthCellType: IdentifiableType {
  var identity: String { return rawValue }
}

enum LoginScreenState {
  case showLogIn
  case showSignUp
  
  var buttonTitle: String {
    switch self {
    case .showLogIn:
      return "Don't have an account?"
    case .showSignUp:
      return "Already have an account?"
    }
  }
  
  var cells: [AuthCellType] {
    switch self {
    case .showLogIn:
      return [
        .Headline,
        .Separator,
        .EmailTextField,
        .PasswordTextField,
        .LoginButton
      ]
    case .showSignUp:
      return [
        .EmailTextField,
        .NameTextField,
        .PasswordTextField,
        .LoginButton
      ]
    }
  }
}

typealias AuthSection = AnimatableSectionModel<Int, AuthCellType>

class ViewController: UIViewController {
  
  @IBOutlet weak var tableView: UITableView!
  let footerButton = UIButton()
  
  let screenState = Variable(LoginScreenState.showLogIn)
  
  let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tableView.estimatedRowHeight = 44
    tableView.rowHeight = UITableViewAutomaticDimension
    
    screenState.asObservable()
      .map { $0.buttonTitle }
      .bindTo(footerButton.rx.title(for: .normal))
      .addDisposableTo(disposeBag)
    
    footerButton.rx.tap
      .asObservable()
      .withLatestFrom(screenState.asObservable())
      .map { state -> LoginScreenState in
        switch state {
        case .showLogIn:
          return .showSignUp
        case .showSignUp:
          return .showLogIn
        }
      }
      .bindTo(screenState)
      .addDisposableTo(disposeBag)
    
    footerButton.setTitleColor(.blue, for: UIControlState())
    footerButton.titleLabel?.font = UIFont.systemFont(ofSize: 13)
    footerButton.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
    tableView.tableFooterView = footerButton
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<AuthSection>()
    dataSource.configureCell = { _, tableView, indexPath, item in
      let cell = tableView.dequeueReusableCell(withIdentifier: item.rawValue, for: indexPath)
      return cell
    }
    
    dataSource.animationConfiguration = AnimationConfiguration(insertAnimation: .fade,
                                                               reloadAnimation: .fade,
                                                               deleteAnimation: .fade)
    
    screenState.asObservable()
      .map { $0.cells }
      .map { [AuthSection(model: 0, items: $0)] }
      .bindTo(tableView.rx.items(dataSource: dataSource))
      .addDisposableTo(disposeBag)
  }
}

