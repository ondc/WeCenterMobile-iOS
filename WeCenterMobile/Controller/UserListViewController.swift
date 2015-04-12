//
//  UserListViewController.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/8/16.
//  Copyright (c) 2014年 ifLab. All rights reserved.
//

import UIKit

@objc enum UserListType: Int {
    case UserFollowing = 1
    case UserFollower = 2
    case QuestionFollwer = 3
}

class UserListViewController: UITableViewController {
    let listType: UserListType
    var user: User
    var users: [User] = []
    var page = 1
    let count = 20
    init(user: User, listType: UserListType) {
        self.listType = listType
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private var headerImageView: UIImageView! // for keeping weak property in header
    private var headerActivityIndicatorView: UIActivityIndicatorView! // for keeping weak property in header
    private var footerActivityIndicatorView: UIActivityIndicatorView! // for keeping weak property in footer
    let cellReuseIdentifier = "UserListViewControllerCell"
    override func loadView() {
        super.loadView()
        let titles: [UserListType: String] = [
            .UserFollowing: "\(user.name!) 关注的用户",
            .UserFollower: "\(user.name!) 的追随者"]
        self.title = titles[listType]!
        view.backgroundColor = UIColor.msr_materialGray900()
        tableView.separatorStyle = .None
        tableView.registerNib(UINib(nibName: "UserListViewControllerCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: cellReuseIdentifier)
        tableView.panGestureRecognizer.requireGestureRecognizerToFail(appDelegate.mainViewController.contentViewController.interactivePopGestureRecognizer)
        tableView.panGestureRecognizer.requireGestureRecognizerToFail(appDelegate.mainViewController.sidebar.screenEdgePanGestureRecognizer)
        let header = tableView.addLegendHeaderWithRefreshingTarget(self, refreshingAction: "refresh")
        header.textColor = UIColor.whiteColor()
        headerImageView = header.valueForKey("arrowImage") as! UIImageView
        headerImageView.tintColor = UIColor.whiteColor()
        headerImageView.msr_imageRenderingMode = .AlwaysTemplate
        headerActivityIndicatorView = header.valueForKey("activityView") as! UIActivityIndicatorView
        headerActivityIndicatorView.activityIndicatorViewStyle = .White
        msr_navigationBar!.barStyle = .Black
        msr_navigationBar!.tintColor = UIColor.whiteColor()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.header.beginRefreshing()
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath) as! UserListViewControllerCell
        cell.update(user: users[indexPath.row], updateImage: true)
        return cell
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        struct _Static {
            static var id: dispatch_once_t = 0
            static var cell: UserListViewControllerCell!
        }
        dispatch_once(&_Static.id) {
            _Static.cell = NSBundle.mainBundle().loadNibNamed("UserListViewControllerCell", owner: nil, options: nil).first as! UserListViewControllerCell
        }
        _Static.cell.update(user: users[indexPath.row], updateImage: false)
        return _Static.cell.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        msr_navigationController!.pushViewController(UserViewController(user: users[indexPath.row]), animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    func refresh() {
        shouldReloadAfterLoadingMore = false
        tableView.footer?.endRefreshing()
        let success: ([User]) -> Void = {
            [weak self] users in
            if let self_ = self {
                self_.page = 1
                self_.users = users
                self_.tableView.header.endRefreshing()
                self_.tableView.reloadData()
                if self_.tableView.footer == nil {
                    let footer = self_.tableView.addLegendFooterWithRefreshingTarget(self_, refreshingAction: "loadMore")
                    footer.textColor = UIColor.whiteColor()
                    footer.automaticallyRefresh = false
                    self_.footerActivityIndicatorView = footer.valueForKey("activityView") as! UIActivityIndicatorView
                    self_.footerActivityIndicatorView.activityIndicatorViewStyle = .White
                }
            }
        }
        let failure: (NSError) -> Void = {
            [weak self] error in
            self?.tableView.header.endRefreshing()
            return
        }
        switch listType {
        case .UserFollower:
            user.fetchFollowers(page: 1, count: count, success: success, failure: failure)
            break
        case .UserFollowing:
            user.fetchFollowings(page: 1, count: count, success: success, failure: failure)
            break
        default:
            break
        }
    }
    var shouldReloadAfterLoadingMore = true
    func loadMore() {
        if tableView.header.isRefreshing() {
            tableView.footer.endRefreshing()
            return
        }
        shouldReloadAfterLoadingMore = true
        let success: ([User]) -> Void = {
            [weak self] users in
            if self?.shouldReloadAfterLoadingMore ?? false {
                self?.page = self!.page + 1
                self?.users.extend(users)
                self?.tableView.reloadData()
            }
            self?.tableView.footer.endRefreshing()
        }
        let failure: (NSError) -> Void = {
            [weak self] error in
            self?.tableView.footer.endRefreshing()
            return
        }
        switch listType {
        case .UserFollower:
            user.fetchFollowers(page: page + 1, count: count, success: success, failure: failure)
            break
        case .UserFollowing:
            user.fetchFollowings(page: page + 1, count: count, success: success, failure: failure)
            break
        default:
            break
        }
    }
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
