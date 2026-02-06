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

    init(client: SupabaseClientManager? = nil, table: String = "", fallbackMode: Bool = true) {
        self.client = client
        self.table = table
        self.fallbackMode = fallbackMode
    }

    /// Select columns from table
    func select(_ columns: String = "*") -> Self {
        self.selectColumns = columns
        print("🔵 helloWORLD QUERY select(\(columns)) from \(table) - fallbackMode: \(fallbackMode)")
        if fallbackMode {
            print("🔴 helloWORLD QUERY SKIPPED - fallback mode")
        }
        return self
    }

    /// Add WHERE clause condition (equals)
    func eq(_ column: String, value: Any) -> Self {
        filters.append((column: column, op: "eq", value: "\(value)"))
        if fallbackMode {
            print("Mock WHERE \(column) = \(value)")
        }
        return self
    }

    /// Add less than filter
    func lt(_ column: String, value: Any) -> Self {
        filters.append((column: column, op: "lt", value: "\(value)"))
        if fallbackMode {
            print("Mock WHERE \(column) < \(value)")
        }
        return self
    }

    /// Add OR filter condition
    func or(_ condition: String) -> Self {
        filters.append((column: "", op: "or", value: condition))
        if fallbackMode {
            print("Mock OR \(condition)")
        }
        return self
    }

    /// Add ORDER BY clause
    func order(_ column: String, ascending: Bool = true) -> Self {
        self.orderColumn = column
        self.orderAscending = ascending
        if fallbackMode {
            print("Mock ORDER BY \(column) \(ascending ? "ASC" : "DESC")")
        }
        return self
    }

    /// Add LIMIT clause
    func limit(_ count: Int) -> Self {
        self.limitCount = count
        if fallbackMode {
            print("Mock LIMIT \(count)")
        }
        return self
    }

    /// Execute query and return single result
    func single<T: Codable>() async throws -> T? {
        print("🔵 helloWORLD QUERY_SINGLE START - table: \(table), columns: \(selectColumns)")

        if fallbackMode {
            print("🔴 helloWORLD QUERY_SINGLE SKIPPED - fallback mode")
            return nil
        }

        guard let client = client else {
            print("🔴 helloWORLD QUERY_SINGLE FAILED - no client")
            throw SupabaseManager.SupabaseError.networkError("No client available")
        }

        var query = client.database.from(table).select(selectColumns)

        for filter in filters where filter.op == "eq" {
            query = query.eq(filter.column, value: filter.value)
        }

        print("🔵 helloWORLD QUERY_SINGLE - executing...")
        let result: T = try await query.single().execute().value
        print("🟢 helloWORLD QUERY_SINGLE SUCCESS - table: \(table)")
        return result
    }

    /// Execute query and return array of results
    func execute<T: Codable>() async throws -> [T] {
        print("🔵 helloWORLD QUERY_EXECUTE START - table: \(table), columns: \(selectColumns)")

        if fallbackMode {
            print("🔴 helloWORLD QUERY_EXECUTE SKIPPED - fallback mode")
            return []
        }

        guard let client = client else {
            print("🔴 helloWORLD QUERY_EXECUTE FAILED - no client")
            throw SupabaseManager.SupabaseError.networkError("No client available")
        }

        print("🔵 helloWORLD QUERY_EXECUTE - building query...")
        var filterQuery = client.database.from(table).select(selectColumns)

        for filter in filters {
            if filter.op == "eq" {
                filterQuery = filterQuery.eq(filter.column, value: filter.value)
                print("🔵 helloWORLD QUERY_EXECUTE - added filter: \(filter.column) = \(filter.value)")
            } else if filter.op == "or" {
                filterQuery = filterQuery.or(filter.value)
            }
        }

        var transformQuery = filterQuery.order(orderColumn ?? "created_at", ascending: orderAscending)
        if let limit = limitCount {
            transformQuery = transformQuery.limit(limit)
        }

        print("🔵 helloWORLD QUERY_EXECUTE - executing query on \(table)...")
        do {
            let results: [T] = try await transformQuery.execute().value
            print("🟢 helloWORLD QUERY_EXECUTE SUCCESS - table: \(table), count: \(results.count)")
            return results
        } catch {
            print("🔴 helloWORLD QUERY_EXECUTE FAILED - table: \(table), error: \(error)")
            throw error
        }
    }
}
