//
//  SupabaseQueryBuilder.swift
//  Club Ralley
//
//  Query builder for Supabase database operations
//

import Foundation

/// Query builder for database operations
/// Provides consistent API whether using real Supabase or fallback mode
@MainActor
class SupabaseQueryBuilder {
    private let client: SupabaseClientManager?
    private let table: String
    private let fallbackMode: Bool

    // Track query state for building the actual query
    private var selectColumns: String = "*"
    private var filters: [(column: String, op: String, value: String)] = []
    private var orderColumn: String?
    private var orderAscending: Bool = true
    private var limitCount: Int?
    private var rangeFrom: Int?
    private var rangeTo: Int?

    init(client: SupabaseClientManager? = nil, table: String = "", fallbackMode: Bool = true) {
        self.client = client
        self.table = table
        self.fallbackMode = fallbackMode
    }

    /// Select columns from table
    func select(_ columns: String = "*") -> Self {
        self.selectColumns = columns
        return self
    }

    /// Add WHERE clause condition (equals)
    func eq(_ column: String, value: Any) -> Self {
        filters.append((column: column, op: "eq", value: "\(value)"))
        return self
    }

    /// Add less than filter
    func lt(_ column: String, value: Any) -> Self {
        filters.append((column: column, op: "lt", value: "\(value)"))
        return self
    }

    /// Add OR filter condition
    func or(_ condition: String) -> Self {
        filters.append((column: "", op: "or", value: condition))
        return self
    }

    /// Add ORDER BY clause
    func order(_ column: String, ascending: Bool = true) -> Self {
        self.orderColumn = column
        self.orderAscending = ascending
        return self
    }

    /// Add LIMIT clause
    func limit(_ count: Int) -> Self {
        self.limitCount = count
        return self
    }

    /// Add pagination range (for offset/limit pagination)
    func range(from: Int, to: Int) -> Self {
        self.rangeFrom = from
        self.rangeTo = to
        return self
    }

    /// Execute query and return single result
    func single<T: Codable>() async throws -> T? {
        if fallbackMode {
            return nil // Offline mode
        }

        guard let client = client else {
            throw SupabaseManager.SupabaseError.networkError("No client available")
        }

        var query = client.database.from(table).select(selectColumns)

        for filter in filters where filter.op == "eq" {
            query = query.eq(filter.column, value: filter.value)
        }

        let result: T = try await query.single().execute().value
        return result
    }

    /// Execute query and return array of results
    func execute<T: Codable>() async throws -> [T] {
        if fallbackMode {
            return [] // Offline mode
        }

        guard let client = client else {
            throw SupabaseManager.SupabaseError.networkError("No client available")
        }

        var filterQuery = client.database.from(table).select(selectColumns)

        for filter in filters {
            if filter.op == "eq" {
                filterQuery = filterQuery.eq(filter.column, value: filter.value)
            } else if filter.op == "or" {
                filterQuery = filterQuery.or(filter.value)
            }
        }

        var transformQuery = filterQuery.order(orderColumn ?? "created_at", ascending: orderAscending)
        if let limit = limitCount {
            transformQuery = transformQuery.limit(limit)
        }
        if let from = rangeFrom, let to = rangeTo {
            transformQuery = transformQuery.range(from: from, to: to)
        }

        let results: [T] = try await transformQuery.execute().value
        return results
    }
}
