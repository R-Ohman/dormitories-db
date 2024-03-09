# University Dormitory Management Database

## Table of Contents
- [Project Overview](#project-overview)
  - [Client](#client)
  - [Project Goals and Challenges](#project-goals-and-challenges)
  - [System Users](#system-users)
  - [Use Case Scenarios](#use-case-scenarios)
- [Database Structure](#database-structure)
- [Example Queries](#example-queries)
- [ERD](#entity-relationship-diagram)
- [How to Use the Database](#how-to-use-the-database)
- [Limitations](#limitations)

## Project Overview

### Client
The client for this database is the Accommodation Center of the Gdansk University of Technology, responsible for administering accommodation and check-out processes for students, doctoral candidates, and guests in university dormitories.

### Project Goals and Challenges
The main goal of the project is to improve the processes of accommodation and check-out for students and other residents in university dormitories, simplify the invoicing process, and monitor payments. Key challenges include:

- Cyclical allocation of places in dormitories, including verification of applications for data correctness, especially the number of points affecting student rankings.
- Monitoring room availability to ensure efficient room allocation.
- Handling the room exchange process between students when needed.

### System Users
The system is designed to serve two main user groups:

1. **Residents Council**: Utilizes the system to efficiently allocate rooms in dormitories and calculate ranking points for students.
2. **Accommodation Center**: Manages the accommodation process (including calculating ranking points for students) and check-out, issues invoices, and monitors payments.

### Use Case Scenarios
Key use case scenarios of the system include:

- **Invoice Issuance**: The system generates invoices for dormitory residents and tracks their payments.
- **Room Allocation**: This process involves verifying applications for data correctness and calculating ranking points for students, which serve as the basis for room allocation.
- **Checking Room Availability**: Users can check the availability of vacant rooms in dormitories.
- **Room Exchange**: The system facilitates the room exchange process between students if necessary.

## Database Structure

The database consists of several tables, each serving a specific purpose:

1. **Mieszkancy**: Contains information about residents, including contact details.
2. **Akademiki**: Stores details about dormitories, including address and contact information.
3. **Faktury**: Manages invoice data, including payment status and amount.
4. **Studenci**: Holds student information, including contact details and nationality.
5. **Aktywnosci**: Stores information about student activities.
6. **Zajmowanie**: Manages the relationship between student activities and students.
7. **RodzajePokojow**: Contains data regarding room types available in dormitories.
8. **Cenniki**: Stores pricing information for room types.
9. **Pokoje**: Manages information about rooms in dormitories.
10. **Zakwaterowania**: Tracks accommodation details, including dates and room assignments.
11. **Wydzialy**: Stores data related to university departments.
12. **Przynalezenia**: Manages the relationship between dormitories and university departments.
13. **Studiowania**: Tracks student enrollment information, including dates and study mode.

## Example Queries

Sample queries that can be executed on the database include:

1. Retrieve the number of additional ranking points for a specific student.
2. List residents with outstanding payments.
3. Retrieve the contact number of a specific resident.
4. Find the neighbor of a specific resident.
5. List available rooms in a specified dormitory.

## Entity Relationship Diagram
![erd](https://github.com/R-Ohman/dormitories-db/assets/113181317/6ed0a8bf-127f-408f-9b79-123c9c347ed2)

## How to Use the Database

To use the database effectively, follow these steps:

1. **Set Up**: Ensure that you have a database management system (DBMS) installed, such as Microsoft SQL Server.
2. **Database Creation**: Execute the provided T-SQL code to create the database schema and tables.
3. **Data Population**: Optionally, populate the tables with sample data to simulate real-world scenarios. You are welcome to use 'insert_data.sql'.
4. **Query Execution**: Use SQL queries to interact with the database and retrieve relevant information based on your requirements. You can find some examples in 'selects.sql'.

## Limitations

The database does not encompass all students of the Gdansk University of Technology but only those involved in the accommodation process. Additionally, it does not include management data related to dormitories, such as information about staff, network infrastructure, or utility fees, which are not directly related to the accommodation and check-out process.

---

Feel free to use and contribute to this database project to enhance accommodation management processes for university dormitories. If you have any questions or suggestions, please don't hesitate to reach out.
