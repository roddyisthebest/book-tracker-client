//
//  SupabaseFactory.swift
//  BookTracker
//
//  Created by 배성연 on 2/25/26.
//

import Foundation
import Supabase

enum SupabaseFactory {
    static func make() -> SupabaseClient {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String

        guard let urlString, let anonKey, let url = URL(string: urlString) else {
            fatalError("""
            Missing SUPABASE_URL / SUPABASE_ANON_KEY in Info.plist.
            Make sure Info.plist has:
            - SUPABASE_URL = $(SUPABASE_URL)
            - SUPABASE_ANON_KEY = $(SUPABASE_ANON_KEY)
            And xcconfig defines SUPABASE_URL, SUPABASE_ANON_KEY.
            """)
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey,
            options: .init(auth: .init(emitLocalSessionAsInitialSession: true))
        )
    }
}
