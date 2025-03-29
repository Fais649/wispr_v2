//
//  Listable.swift
//  wispr
//
//  Created by Faisal Alalaiwat on 25.03.25.
//

protocol Listable: Identifiable, Equatable {
    var parent: Self? { get set }
    var children: [Self] { get set }
}
