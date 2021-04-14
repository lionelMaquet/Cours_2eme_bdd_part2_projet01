-- PROCEDURE 1 : Créer commande
DELIMITER |
CREATE PROCEDURE creer_commande(IN pi_email_client VARCHAR(200), IN pi_moyen_paiement VARCHAR(30))
BEGIN
	DECLARE nombre_commandes_en_cours INT;
    SELECT COUNT(*) INTO nombre_commandes_en_cours FROM commande WHERE client_email = pi_email_client AND statut = "En cours";
    
    IF nombre_commandes_en_cours = 0
    THEN
		INSERT INTO commande VALUES (NULL, pi_email_client, current_timestamp(), "En cours", pi_moyen_paiement);
	END IF;
END |
DELIMITER ;

-- PROCEDURE 2 : Ajouter article à commande 
DELIMITER |
CREATE PROCEDURE ajouter_article_commande(IN pi_numero_commande INT, IN pi_numero_article INT, IN pi_quantite INT)
BEGIN
	INSERT INTO detail VALUES (pi_numero_commande, pi_numero_article, pi_quantite); 
END |
DELIMITER ; 

-- PROCEDURE 3 : Valider commande 
DELIMITER |
CREATE PROCEDURE valider_commande (IN pi_numero_commande INT)
BEGIN
	-- variables, conditions, curseurs, gestionnaires
	DECLARE prix_total DECIMAL(9,2) DEFAULT 0.00;
    
    DECLARE current_num_article INT DEFAULT 0;
    DECLARE current_quantite INT DEFAULT 0;
    DECLARE current_prix DECIMAL(9,2) DEFAULT 0.00;
    
    DECLARE l_fin_de_boucle BOOLEAN DEFAULT FALSE;
    
    -- curseurs
    DECLARE curseur_prix CURSOR 
    FOR 
		SELECT article_numero, quantite FROM detail 
        WHERE commande_numero = pi_numero_commande;
        
	-- gestionnaire
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_fin_de_boucle := TRUE;
		
        
	OPEN curseur_prix; 
    REPEAT
		FETCH curseur_prix INTO current_num_article, current_quantite;
        SELECT prix * current_quantite INTO current_prix FROM article WHERE numero = current_num_article;
        IF l_fin_de_boucle = FALSE
			THEN
			SET prix_total := prix_total + current_prix;
		END IF;
	UNTIL l_fin_de_boucle = TRUE
    END REPEAT;
    CLOSE curseur_prix;
    
    INSERT INTO paiement VALUES (pi_numero_commande, current_timestamp(), prix_total , "Ouvert");

	UPDATE commande
	SET statut = "Validée" 
    WHERE numero = pi_numero_commande;
END |
DELIMITER ;

-- PROCEDURE 4 : Payer commande 
DELIMITER | 
CREATE PROCEDURE payer_commande (IN pi_commande_num INT, IN pi_montant DECIMAL(9,2))
BEGIN
	DECLARE old_prix DECIMAL(9,2);
    SELECT solde INTO old_prix
    FROM paiement WHERE commande_numero = pi_commande_num;
    
    IF old_prix >= pi_montant
    THEN
		UPDATE paiement
        SET 
			solde = old_prix - pi_montant,
			date_paiement = current_timestamp()
        WHERE commande_numero = pi_commande_num;
	END IF;
	-- Le changement de statut est provoqué par un trigger 
END |
DELIMITER ;

-- PROCEDURE 5 : Commande livrée
DELIMITER |
CREATE PROCEDURE commande_livree (IN pi_commande_num INT)
BEGIN
	UPDATE commande
    SET statut = "Livrée"
    WHERE numero = pi_commande_num;
END |
DELIMITER ;


-- ------------------------------- --
-- --- PROCEDURES STATISTIQUES --- --
-- ------------------------------- -- 

-- PROCEDURE 6 : Montant total en attente de paiement
DELIMITER |
CREATE PROCEDURE montant_total_attente_paiement()
BEGIN
	DECLARE montant_total DECIMAL(9,2) DEFAULT 0.00;
    DECLARE current_montant DECIMAL(9,2) DEFAULT 0.00;
	DECLARE l_fin_de_boucle BOOLEAN DEFAULT FALSE;
    
    -- curseurs
    DECLARE curseur_montant_attente CURSOR 
    FOR 
		SELECT solde FROM paiement 
        WHERE statut = "Ouvert";
        
	-- gestionnaire
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_fin_de_boucle := TRUE;
		
	OPEN curseur_montant_attente; 
    REPEAT
		FETCH curseur_montant_attente INTO current_montant;
        IF l_fin_de_boucle = FALSE
        THEN
			SELECT montant_total + current_montant INTO montant_total;
		END IF;
	UNTIL l_fin_de_boucle = TRUE
    END REPEAT;
    CLOSE curseur_montant_attente;
    
    SELECT montant_total;
END |
DELIMITER ;

-- PROCEDURE 7 : Delai moyen de paiement
DELIMITER |
CREATE PROCEDURE delai_moyen()
BEGIN
	DECLARE current_numero_commande INT;
    DECLARE current_paiement_timestamp TIMESTAMP;
    
    DECLARE current_commande_timestamp TIMESTAMP;
    
	DECLARE nombre_commandes_payees INT;
    
    DECLARE total_nombre_secondes INT DEFAULT 0;
    DECLARE l_fin_de_boucle BOOLEAN DEFAULT FALSE;
    
    -- curseur
    DECLARE curseur_timestamp CURSOR
    FOR
		SELECT commande_numero, date_paiement FROM paiement
        WHERE statut = "Cloturé";
	
    -- gestionnaire
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_fin_de_boucle := TRUE;
    
    
    SELECT COUNT(*) INTO nombre_commandes_payees FROM paiement WHERE statut = "Cloturé"; 
    SELECT nombre_commandes_payees; -- test
    
    OPEN curseur_timestamp;
    REPEAT
		FETCH curseur_timestamp INTO current_numero_commande, current_paiement_timestamp;
        IF l_fin_de_boucle = FALSE
        THEN
			SELECT date INTO current_commande_timestamp FROM commande WHERE numero = current_numero_commande;
			SET total_nombre_secondes := total_nombre_secondes + timestampdiff(SECOND, current_commande_timestamp, current_paiement_timestamp);
            SELECT current_numero_commande, current_paiement_timestamp, current_commande_timestamp, total_nombre_secondes; -- test
		END IF;
        
    UNTIL l_fin_de_boucle = TRUE
    END REPEAT;
    CLOSE curseur_timestamp;
    
    SELECT sec_to_time(total_nombre_secondes / nombre_commandes_payees ) AS delai_moyen;
    
END |
DELIMITER ;

-- PROCEDURE 8 : Indicateur au choix : Connaitre l'article le plus commandé
DELIMITER |
CREATE PROCEDURE article_populaire()
BEGIN
	DECLARE current_article_numero INT DEFAULT 0;
    DECLARE current_article_total INT DEFAULT 0;
    DECLARE final_article_total INT DEFAULT 0;
    DECLARE final_article_numero INT DEFAULT 0;
    DECLARE l_fin_de_boucle BOOLEAN DEFAULT FALSE;
    
    -- curseur 
    DECLARE curseur_quantite CURSOR
    FOR 
		SELECT article_numero
		FROM detail;
        
	-- gestionnaire
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET l_fin_de_boucle := TRUE;
    
    OPEN curseur_quantite;
    REPEAT
		FETCH curseur_quantite INTO current_article_numero;
        IF l_fin_de_boucle = FALSE
        THEN
			SELECT SUM(quantite) INTO current_article_total FROM detail WHERE article_numero = current_article_numero;
            IF current_article_total > final_article_total
            THEN
				SET final_article_total = current_article_total ;
                SET final_article_numero = current_article_numero ;
			END IF;
		END IF;
    UNTIL l_fin_de_boucle = TRUE
    END REPEAT;
    CLOSE curseur_quantite;
    
    SELECT final_article_numero, final_article_total;
END |
DELIMITER ;







