//
//  TeamsTableViewController.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import UIKit
import TheGreatKit
import Shallows
import Avenues

class MatchesTableViewController: TheGreatGame.TableViewController, Refreshing {
    
    // MARK: - Data source
    var stages: [Stage] = []
    
    // MARK: - Injections
    var resource: Resource<[Stage]>!
    var makeAvenue: (CGSize) -> SymmetricalAvenue<URL, UIImage> = runtimeInject

    // MARK: - Services
    var avenue: SymmetricalAvenue<URL, UIImage>!
    var pullToRefreshActivities: NetworkActivity.IndicatorManager!
    
    // MARK: - Cell Fillers
    var matchCellFiller: MatchCellFiller!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(tableView)
        self.avenue = makeAvenue(CGSize(width: 30, height: 30))
        self.matchCellFiller = MatchCellFiller(avenue: avenue)
        configure(avenue)
        self.pullToRefreshActivities = make()
        self.resource.load(completion: reloadData(stages:source:))
    }
    
    fileprivate func indexPathOfMostRelevantMatch(from stages: [Stage]) -> IndexPath {
        return IndexPath.start(ofSection: 0)
    }
    
    fileprivate func reloadData(stages: [Stage], source: Source) {
        let mostRecent = indexPathOfMostRelevantMatch(from: stages)
        if self.stages.isEmpty && source.isAbsoluteTruth {
            self.stages = stages
            tableView.insertSections(IndexSet.init(integersIn: 0 ... stages.count - 1), with: UITableViewRowAnimation.top)
            tableView.scrollToRow(at: mostRecent, at: .top, animated: false)
        } else {
            self.stages = stages
            tableView.reloadData()
//            tableView.scrollToRow(at: mostRecent, at: .top, animated: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPullToRefresh(_ sender: UIRefreshControl) {
        resource.reload(connectingToIndicator: pullToRefreshActivities, completion: reloadData(stages:source:))
    }
    
    func didFetchImage(with url: URL) {
        var paths: [IndexPath] = []
        for (stage, stageIndex) in zip(stages, stages.indices) {
            for (match, matchIndex) in zip(stage.matches, stage.matches.indices) {
                if match.teams.contains(where: { $0.badgeURL == url }) {
                    paths.append(IndexPath(row: matchIndex, section: stageIndex))
                }
            }
        }
        for indexPath in paths {
            if let cell = tableView.cellForRow(at: indexPath) {
                configureCell(cell, forRowAt: indexPath, afterImageDownload: true)
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return stages.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stages[section].matches.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return stages[section].title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchListMatch", for: indexPath)
        configureCell(cell, forRowAt: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool = false) {
        switch cell {
        case let match as MatchTableViewCell:
            configureMatchCell(match, forRowAt: indexPath, afterImageDownload: afterImageDownload)
        default:
            fault(type(of: cell))
        }
    }
    
    func configureMatchCell(_ cell: MatchTableViewCell, forRowAt indexPath: IndexPath, afterImageDownload: Bool) {
        let match = stages[indexPath.section].matches[indexPath.row]
        matchCellFiller.setup(cell, with: match, forRowAt: indexPath, afterImageDownload: afterImageDownload)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}

// MARK: - Configurations
extension MatchesTableViewController {
        
    fileprivate func configure(_ avenue: Avenue<URL, URL, UIImage>) {
        avenue.onStateChange = { [weak self] url in
            assert(Thread.isMainThread)
            self?.didFetchImage(with: url)
        }
        avenue.onError = {
            print($0)
        }
    }
    
    fileprivate func configure(_ tableView: UITableView) {
        tableView.register(UINib.init(nibName: "MatchTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "MatchListMatch")
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
}
