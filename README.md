# 3005 A3

> - Student #: 101346935
> - Name: Cynth Jones

This was not tested in the course VM, but should generally work.
The thing that may require the most adjustment is the `DATABASE_URL` - see below.

## Setup

pgadmin does not function on my system (not well maintained for my distro) so the following use the postgres CLI.

First, open it:

```sh
# or whatever your database is called
sudo psql --username postgres 3005_a3
```

Then, run the following (copy+paste and enter) to drop any existing table, create a new one, and insert the default data.

```pgsql
drop table students;
CREATE TABLE students (student_id serial primary key, first_name varchar(30) not null, last_name varchar(30) not null, email varchar(30) not null, enrollment_date date );
INSERT INTO students (first_name, last_name, email, enrollment_date) VALUES
('John', 'Doe', 'john.doe@example.com', '2023-09-01'),
('Jane', 'Smith', 'jane.smith@example.com', '2023-09-01'),
('Jim', 'Beam', 'jim.beam@example.com', '2023-09-02');
```

You can use `select * from students;` to verify success.

You will need Rust and Cargo.
Install rustup, then install the toolchain using rustup.

```sh
sudo apt install rustup
rustup install nightly
```

You will also need the database URL specified in your environment.
See <https://docs.rs/sqlx/latest/sqlx/postgres/struct.PgConnectOptions.html>.

```sh
# Change depending on where you database is and how you are connecting.
# This example runs as the postgres user for a db named 3005_a3 with a unix socket in /run/postgresql/.s.PGSQL.5432
export DATABASE_URL=postgresql://postgres@%2Frun%2Fpostgresql/3005_a3
```

Then, in the project directory, compile and run the program.

```sh
cargo run -- [arguments]
```

## Usage

Examples:

```sh
cargo run -- --help
cargo run # or cargo run -- get_all
cargo run -- add first-name last-name email@email 2026-10-10
cargo run -- add first-name last-name email@email
cargo run -- update_email
cargo run -- delete
```

The output is ugly, but should communicate everything.
