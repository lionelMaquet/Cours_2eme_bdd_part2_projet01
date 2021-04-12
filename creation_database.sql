-- Création de la db

CREATE DATABASE IF NOT EXISTS ebusiness CHARACTER SET 'utf8';
USE ebusiness;

-- Création des tables

CREATE TABLE IF NOT EXISTS client (
	email VARCHAR(200) NOT NULL,
	login VARCHAR(20) NOT NULL,
	password VARCHAR(100) NOT NULL, 
	nom VARCHAR(20) NOT NULL,
    prenom VARCHAR(20) NOT NULL,
    adresse_facturation VARCHAR(200) NOT NULL,
    adresse_livraison VARCHAR(200) NOT NULL
)
ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE IF NOT EXISTS article (
	numero INT UNSIGNED NOT NULL,
    fournisseur VARCHAR(50) NOT NULL,
    reference_fournisseur INT NOT NULL,
    prix DECIMAL(9,2) NOT NULL
)
ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE IF NOT EXISTS commande (
	numero INT UNSIGNED NOT NULL auto_increment,
    client_email VARCHAR(200) NOT NULL,
    date TIMESTAMP NOT NULL,
    statut VARCHAR (20), 
    moyen_paiement VARCHAR(30),
    primary key(numero)
)
ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE IF NOT EXISTS detail (
	commande_numero INT UNSIGNED NOT NULL,
    article_numero INT UNSIGNED NOT NULL,
    quantite INT UNSIGNED NOT NULL
)
ENGINE=InnoDB CHARSET=utf8;

CREATE TABLE IF NOT EXISTS paiement (
	commande_numero INT UNSIGNED NOT NULL,
    date_paiement TIMESTAMP NOT NULL,
    solde DECIMAL(10,2) NOT NULL,
    statut VARCHAR(20)
)
ENGINE=InnoDB CHARSET=utf8;

-- Ajout des primary keys

ALTER TABLE client
ADD PRIMARY KEY pk_client (email);

ALTER TABLE article
ADD PRIMARY KEY pk_article (numero);

-- ALTER TABLE commande ADD PRIMARY KEY pk_commande (numero);

ALTER TABLE detail
ADD PRIMARY KEY (commande_numero, article_numero);

ALTER TABLE paiement
ADD PRIMARY KEY pk_paiement (commande_numero);

-- Ajout des foreign keys

ALTER TABLE commande
ADD CONSTRAINT fk_commande_client
FOREIGN KEY (client_email)
REFERENCES  client (email)
ON DELETE RESTRICT 
ON UPDATE CASCADE;

ALTER TABLE detail
ADD CONSTRAINT fk_detail_comande
FOREIGN KEY (commande_numero)
REFERENCES  commande (numero)
ON DELETE RESTRICT 
ON UPDATE CASCADE;

ALTER TABLE detail
ADD CONSTRAINT fk_detail_article
FOREIGN KEY (article_numero)
REFERENCES  article (numero)
ON DELETE RESTRICT 
ON UPDATE CASCADE;

ALTER TABLE paiement
ADD CONSTRAINT fk_paiement_commande
FOREIGN KEY (commande_numero)
REFERENCES commande (numero)
ON DELETE RESTRICT
ON UPDATE CASCADE;