#![expect(clippy::missing_docs_in_private_items, reason = "proto")]
#![expect(unused_imports, reason = "incorrect diagnostic")]

use std::{
    env::{self, args},
    process::exit,
};

use color_eyre::{
    Result,
    eyre::{Context, bail},
};
use pound::Parse;
use sqlx::{Connection as _, FromRow, PgConnection, query, query_as, types::chrono::NaiveDate};

/// Parse from rows.
#[derive(Debug, FromRow)]
pub struct StudentModel {
    pub student_id: i32,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub enrollment_date: Option<NaiveDate>,
}

/// Allowed commands.
enum Command {
    GetAllStudents,
    AddStudent,
    UpdateStudentEmail,
    DeleteStudent,
}

/// Parse command from string.
fn parse_command(string: &str) -> Result<Command> {
    match string {
        "get_all" => Ok(Command::GetAllStudents),
        "add" => Ok(Command::AddStudent),
        "update_email" => Ok(Command::UpdateStudentEmail),
        "delete" => Ok(Command::DeleteStudent),
        _ => bail!("Command does not match!"),
    }
}

/// Base cli arg.
#[derive(Parse)]
struct CommandArg {
    /// One of `"get_all"`, `"add"`, `"update_email"`, or `"delete"`.
    #[pound(default = "get_all", parse = parse_command)]
    pub command: Command,
}

/// Args for adding students.
#[derive(Parse)]
struct AddStudentArgs {
    #[pound(flatten)]
    pub command: CommandArg,
    pub first_name: String,
    pub last_name: String,
    pub email: String,
    pub enrollment_date: Option<String>,
}

/// Args for updating student email.
#[derive(Parse)]
struct UpdateStudentEmailArgs {
    #[pound(flatten)]
    pub command: CommandArg,
    pub student_id: i32,
    pub new_email: String,
}

/// Args for deleting students.
#[derive(Parse)]
struct DeleteStudentArgs {
    #[pound(flatten)]
    pub command: CommandArg,
    pub student_id: i32,
}

/// Async main function, connect to DB and dispatch to appropriate function.
#[tokio::main]
async fn main() -> Result {
    #[expect(clippy::expect_used, reason = "intend to crash")]
    let db = env::var("DATABASE_URL").expect("DATABASE_URL env var must be set.");
    let mut conn = match PgConnection::connect(&db).await {
        Err(err) => {
            println!("Failed to connect to db {err:#}");
            exit(-1);
        }
        Ok(pool) => pool,
    };

    let cli_args_owned: Vec<_> = args().collect();
    #[expect(clippy::indexing_slicing, reason = "prototype")]
    let cli_args: Vec<&str> = cli_args_owned[1..].iter().map(|string| &**string).collect();

    let command = cli_args.first().map_or_else(
        || CommandArg::parse_from([]),
        |first| CommandArg::parse_from([*first]),
    );

    match command.command {
        Command::GetAllStudents => get_all_students(&mut conn).await,
        Command::AddStudent => {
            let args = AddStudentArgs::parse_from(cli_args.clone());
            add_student(&mut conn, args).await
        }
        Command::UpdateStudentEmail => {
            let args = UpdateStudentEmailArgs::parse_from(cli_args.clone());
            update_student_email(&mut conn, args).await
        }
        Command::DeleteStudent => {
            let args = DeleteStudentArgs::parse_from(cli_args);
            delete_student(&mut conn, args).await
        }
    }
}

/// Retrieves and displays all records from the students table.
#[expect(clippy::single_call_fn, reason = "proof of concept")]
#[expect(clippy::use_debug, reason = "prototype")]
async fn get_all_students(conn: &mut PgConnection) -> Result {
    let result = query_as!(
        StudentModel,
        "SELECT student_id, first_name, last_name, email, enrollment_date FROM students"
    )
    .fetch_all(conn)
    .await;
    match result {
        Ok(value) => {
            println!("Students:");

            if value.is_empty() {
                println!("\tNone!");
            }
            for row in value {
                println!("{row:#?}");
            }

            Ok(())
        }
        Err(err) => {
            eprintln!("Failed to retrieve students: {err:#}");
            Err(err.into())
        }
    }
}

/// Inserts a new student record into the students table.
#[expect(clippy::single_call_fn, reason = "proof of concept")]
async fn add_student(conn: &mut PgConnection, args: AddStudentArgs) -> Result {
    // There's definitely a more idiomatic way to do this.
    let enrollment_date: Option<NaiveDate> = match args.enrollment_date {
        None => None,
        Some(value) => match NaiveDate::parse_from_str(&value, "%Y-%m-%d") {
            Ok(val) => Some(val),
            Err(_) => {
                bail!("Could not parse date! Make sure you are using the format %Y-%m-%d.")
            }
        },
    };

    let result = query!(
        "INSERT INTO students (first_name, last_name, email, enrollment_date) VALUES ($1, $2, $3, $4) RETURNING student_id",
        args.first_name,
        args.last_name,
        args.email,
        enrollment_date
    ).fetch_one(conn)
    .await;

    match result {
        Ok(record) => {
            println!("Student added successfully with ID {:#}", record.student_id);
            Ok(())
        }
        Err(err) => {
            eprintln!("Failed to add student: {err:#}");
            Err(err.into())
        }
    }
}

/// Updates the email address for a student with the specified `student_id`.
#[expect(clippy::single_call_fn, reason = "proof of concept")]
async fn update_student_email(conn: &mut PgConnection, args: UpdateStudentEmailArgs) -> Result {
    let result = query!(
        "UPDATE students SET email = $2 WHERE student_id = $1",
        args.student_id,
        args.new_email
    )
    .execute(conn)
    .await;

    match result {
        Ok(_record) => {
            // TODO: check update count?
            println!("Success! (Note: this does not mean any students were updated)");
            Ok(())
        }
        Err(err) => {
            eprintln!("Failed to update student email: {err:#}");
            Err(err.into())
        }
    }
}

/// Deletes the record of the student with the specified `student_id`.
#[expect(clippy::single_call_fn, reason = "proof of concept")]
async fn delete_student(conn: &mut PgConnection, args: DeleteStudentArgs) -> Result {
    let result = query!(
        "DELETE FROM students WHERE student_id = $1",
        args.student_id
    )
    .execute(conn)
    .await;

    match result {
        Ok(_record) => {
            println!("Success! (Note: this does not mean any students were deleted.)");
            Ok(())
        }
        Err(err) => {
            eprintln!("Failed to delete student: {err:#}");
            Err(err.into())
        }
    }
}
