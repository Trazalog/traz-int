CREATE TABLE dbo.novedades_clientes_queue (
	queue_id int IDENTITY(1,1) NOT NULL,
	data_json varchar(8000) COLLATE Modern_Spanish_CI_AI NULL,
	fec_alta datetime DEFAULT getdate() NULL,
	fec_realizado datetime NULL,
	procesado int DEFAULT 0 NULL,
	CONSTRAINT PK__novedade__2294FA6E61B98BF1 PRIMARY KEY (queue_id)
);
