-- pricing_t.dbo.errors definition

-- Drop table

-- DROP TABLE pricing_t.dbo.errors;

CREATE TABLE dbo.tzl_errors (
	erro_id int IDENTITY(1,1) NOT NULL,
	[TYPE] varchar(MAX) COLLATE Latin1_General_CI_AS NULL,
	number int NULL,
	state int NULL,
	severity int NULL,
	line int NULL,
	procedure_name varchar(MAX) COLLATE Latin1_General_CI_AS NULL,
	message varchar(MAX) COLLATE Latin1_General_CI_AS NULL,
	insert_date datetime DEFAULT getdate() NOT NULL,
	insert_user varchar(50) COLLATE Latin1_General_CI_AS DEFAULT original_login() NOT NULL
);