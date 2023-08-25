-- "int".jlmi_synch_queue definition

-- Drop table

-- DROP TABLE "int".jlmi_synch_queue;

CREATE TABLE "int".jlmi_synch_queue (
	queue_id serial4 NOT NULL,
	data_json varchar NULL,
	fec_alta timestamp NOT NULL DEFAULT now(),
	fec_realizado timestamp NULL,
	procesado int4 NULL DEFAULT 0,
	empr_id int4 NULL,
	CONSTRAINT jlmi_synch_queue_pk PRIMARY KEY (queue_id)
);
