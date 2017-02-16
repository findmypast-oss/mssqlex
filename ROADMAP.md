# Mssqlex Roadmap

The goal of the Mssqlex project is to create an Elixir adapter for Microsoft SQL Server that is compatible with Ecto 2.0

## Section 1: DB Connection

Establishing a connection with a database, using the [DBConnection](https://github.com/elixir-ecto/db_connection) library, do basic queries, pooling, etc.

```
         /--> 3a --> 4a --> 5a
1 --> 2 -|
         \--> 3b --> 4b
```

### Task 1: Establish Connection

Be able to establish a connection to an MS SQL server using DBConnection and Postgrex as a template.

- [DBConnection.start_link/2](https://hexdocs.pm/db_connection/DBConnection.html#start_link/2)

### Task 2: Close Connection

Be able to close a connection to MS SQL Server using DBConnection and Postgrex as an example.

- [DBConnection.close/3](https://hexdocs.pm/db_connection/DBConnection.html#close/3)
- [DBConnection.close!/3](https://hexdocs.pm/db_connection/DBConnection.html#close!/3)

### Task 3a: Queries

Be able to prepare/execute a raw SQL query using a connection to the database.

- [DBConnection.execute/4](https://hexdocs.pm/db_connection/DBConnection.html#execute/4)
- [DBConnection.execute!/4](https://hexdocs.pm/db_connection/DBConnection.html#execute!/4)
- [DBConnection.prepare/3](https://hexdocs.pm/db_connection/DBConnection.html#prepare/3)
- [DBConnection.prepare!/3](https://hexdocs.pm/db_connection/DBConnection.html#prepare!/3)
- [DBConnection.prepare_execute/4](https://hexdocs.pm/db_connection/DBConnection.html#prepare_execute/4)
- [DBConnection.prepare_execute!/4](https://hexdocs.pm/db_connection/DBConnection.html#prepare_execute!/4)

### Task 3b: Pools

Be able to setup a pool of workers that can establish/use connections.

- [DBConnection.ensure_all_started/2](https://hexdocs.pm/db_connection/DBConnection.html#ensure_all_started/2)

### Task 4a: Transactions / Rollbacks

Be able to run transactions and rollbacks.

- [DBConnection.rollback/2](https://hexdocs.pm/db_connection/DBConnection.html#rollback/2)
- [DBConnection.run/3](https://hexdocs.pm/db_connection/DBConnection.html#run/3)
- [DBConnection.transaction/3](https://hexdocs.pm/db_connection/DBConnection.html#transaction/3)

### Task 4b: Child Spec

Create a supervisor child spec for a pool of connections.

- [DBConnection.child_spec/3](https://hexdocs.pm/db_connection/DBConnection.html#child_spec/3)

### Task 5a: Stream

Create a stream that will execute a prepared query and stream results using a cursor.

- [DBConnection.stream/4](https://hexdocs.pm/db_connection/DBConnection.html#stream/4)
- [DBConnection.prepare_stream/4](https://hexdocs.pm/db_connection/DBConnection.html#prepare_stream/4)

## Section 2: Types / Encoding / Decoding

Converting MS SQL Server types with Elixir and Ecto types.

[Decimal library](https://github.com/ericmj/decimal) seems to be used a lot for this.

```
1 --> 2
```

### Task 1: Types

Investigate all available types in MS SQL Server and how they will translate into Elixir and Ecto types.

[TDS Ecto Data Type Mapping](https://github.com/livehelpnow/tds_ecto#data-type-mapping)

[Ecto Schema Types and Casting](https://hexdocs.pm/ecto/Ecto.Schema.html#module-types-and-casting)


### Task 2: Encoding / Decoding

Write encoding / decoding for each conversion. Remember UTF8 <-> Latin 1!

## Section 3: Ecto.Repo

A repository maps to an underlying data store, controlled by an adapter.

This sections is about creating an adapter that can convert all functions in `Ecto.Repo` to functions that can be executed against an MS SQL Server.

By convention this adapter will be called `Mssqlex.Ecto`.

Use `Ecto.Adapaters.Postgres` and `Tds.Ecto` as examples.

### Task 1: Basic query support

INSERT, UPDATE, ETC.

### Task 2: Full query support

JOINS, PRELOAD?? ASSOCIATIONS

### Task 3: Transactions

### Task 4: Migrations / Rollbacks

### Task 5: Ecto.Create / Ecto.Drop Mix Tasks

## Section 4: Ecto.Query

Example of query in Ecto:

```elixir
query = from u in "users",
          where: u.age > 18,
          select: u.name
```

Ensure queries work with an MS SQL data source.

## Section 5: Ecto.Schema

Schemas can map to a MS SQL Server data source, bi-directional.

## Section 6: Ecto.Changeset

Compatible with filtering, casting, validation and definitions of constraints when manipulating structs.

## Section 7: Ecto 2.0 Functionality

A list of Ecto 2.0 features we should be able to handle.

- [ ] Schemaless queries
- [ ] Schemaless changesets
- [ ] Dynamic queries
- [ ] Multi tenancy with query prefixes
- [ ] Aggregates and subqueries
- [ ] Improved associations and factories
- [ ] Many to many casting
- [ ] Many to many upserts
- [ ] Composable transactions with Ecto.Multi
- [ ] Concurrent tests with the SQL Sandbox
