/**
 Copyright IBM Corporation 2016, 2017
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import XCTest
import SwiftKuery
import Dispatch

@testable import SwiftKuerySQLite

#if os(Linux)
let tableInsert = "tableInsertLinux"
let tableInsert2 = "tableInsert2Linux"
#else
let tableInsert = "tableInsertOSX"
let tableInsert2 = "tableInsert2OSX"
#endif

class TestInsert: XCTestCase {
    
    static var allTests: [(String, (TestInsert) -> () throws -> Void)] {
        return [
            ("testInsert", testInsert),
        ]
    }
    
    class MyTable : Table {
        let a = Column("a")
        let b = Column("b")
        
        let tableName = tableInsert
    }
    
    class MyTable2 : Table {
        let a = Column("a")
        let b = Column("b")
        
        let tableName = tableInsert2
    }
    func testInsert() {
        let t = MyTable()
        let t2 = MyTable2()
        
        let pool = CommonUtils.sharedInstance.getConnectionPool()
        performTest(asyncTasks: { expectation in

            let semaphore = DispatchSemaphore(value: 0)
            
            guard let connection = pool.getConnection() else {
                XCTFail("Failed to get connection")
                return
            }
            
            cleanUp(table: t.tableName, connection: connection) { result in
                cleanUp(table: t2.tableName, connection: connection) { result in
                    
                    executeRawQuery("CREATE TABLE \"" +  t.tableName + "\" (a varchar(40), b integer)", connection: connection) { result, rows in
                        XCTAssertEqual(result.success, true, "CREATE TABLE failed")
                        XCTAssertNil(result.asError, "Error in CREATE TABLE: \(result.asError!)")
                        
                        executeRawQuery("CREATE TABLE \"" +  t2.tableName + "\" (a varchar(40), b integer)", connection: connection) { result, rows in
                            XCTAssertEqual(result.success, true, "CREATE TABLE failed")
                            XCTAssertNil(result.asError, "Error in CREATE TABLE: \(result.asError!)")
                            
                            let i1 = Insert(into: t, values: "apple", 10)
                            executeQuery(query: i1, connection: connection) { result, rows in
                                XCTAssertEqual(result.success, true, "INSERT failed")
                                XCTAssertNil(result.asError, "Error in INSERT: \(result.asError!)")
                                
                                let i2 = Insert(into: t, valueTuples: (t.a, "apricot"), (t.b, "3"))
                                executeQuery(query: i2, connection: connection) { result, rows in
                                    XCTAssertEqual(result.success, true, "INSERT failed")
                                    XCTAssertNil(result.asError, "Error in INSERT: \(result.asError!)")
                                    XCTAssertNil(result.asResultSet, "INSERT returned rows")
                                    XCTAssertNil(rows, "INSERT returned rows")
                                    
                                    let i3 = Insert(into: t, columns: [t.a, t.b], values: ["banana", 17])
                                    executeQuery(query: i3, connection: connection) { result, rows in
                                        XCTAssertEqual(result.success, true, "INSERT failed")
                                        XCTAssertNil(result.asError, "Error in INSERT: \(result.asError!)")
                                        XCTAssertNil(result.asResultSet, "INSERT returned rows")
                                        XCTAssertNil(rows, "INSERT returned rows")
                                        
                                        let i4 = Insert(into: t, rows: [["apple", 17], ["banana", -7], ["banana", 27]])
                                        executeQuery(query: i4, connection: connection) { result, rows in
                                            XCTAssertEqual(result.success, true, "INSERT failed")
                                            XCTAssertNil(result.asError, "Error in INSERT: \(result.asError!)")
                                            XCTAssertNil(result.asResultSet, "INSERT returned rows")
                                            XCTAssertNil(rows, "INSERT returned rows")
                                            
                                            let i5 = Insert(into: t, rows: [["apple", 5], ["banana", 10], ["banana", 3]])
                                            executeQuery(query: i5, connection: connection) { result, rows in
                                                XCTAssertEqual(result.success, true, "INSERT failed")
                                                XCTAssertNil(result.asError, "Error in INSERT: \(result.asError!)")
                                                XCTAssertNil(rows, "INSERT returned rows")
                                                
                                                let i6 = Insert(into: t2, Select(from: t).where(t.a == "apple"))
                                                executeQuery(query: i6, connection: connection) { result, rows in
                                                    XCTAssertEqual(result.success, true, "INSERT failed")
                                                    XCTAssertNil(result.asError, "Error in INSERT: \(result.asError!)")
                                                    XCTAssertNil(result.asError, "Error in INSERT: \(result.asError!)")
                                                    XCTAssertNil(rows, "INSERT returned rows")
                                                    
                                                    let s1 = Select(from: t)
                                                    executeQuery(query: s1, connection: connection) { result, rows in
                                                        XCTAssertEqual(result.success, true, "SELECT failed")
                                                        XCTAssertNil(result.asError, "Error in SELECT: \(result.asError!)")
                                                        XCTAssertNotNil(rows, "SELECT returned no rows")
                                                        XCTAssertEqual(rows!.count, 9, "INSERT returned wrong number of rows: \(rows!.count) instead of 9")
                                                        
                                                        let drop = Raw(query: "DROP TABLE", table: t)
                                                        executeQuery(query: drop, connection: connection) { result, rows in
                                                            XCTAssertEqual(result.success, true, "DROP TABLE failed")
                                                            XCTAssertNil(result.asError, "Error in DELETE: \(result.asError!)")
                                                            semaphore.signal()
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            semaphore.wait()
            expectation.fulfill()
        })
    }
}
